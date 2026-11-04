"""
agent.py

Phase 2 (revised): multi-stage pipeline instead of one freeform
tool-calling loop.

A single "figure everything out yourself" prompt was prone to hallucination
-- e.g. silently mapping "machine learning" (not a real course) onto
unrelated real course codes and answering as if that were correct, or
narrating a fake tool call as text instead of using one. Splitting the work
into separate, narrowly-scoped prompts -- the same idea as main.py's
query-generation / answer-generation split -- gives the model much less
room to improvise at each step, and lets this code validate/short-circuit
between stages instead of trusting one big response to get everything
right at once.

Stages, run in order for every question:
  0. Write-intent check  -- deterministic, no LLM call at all. If the
     question itself asks to delete/update/insert data, refuse immediately.
  1. Relevance check      -- can this question even be answered from the
     real schema? Catches "machine learning" before any SQL is written.
  2. Query generation     -- schema + question (+ any previous error) ->
     one SQL SELECT statement, as plain text (like main.py), not a
     model-invoked tool call.
  3. Execution             -- run it through the same safe, read-only
     execute_sql_query() used before (SELECT-only enforcement still
     applies). On a database error, go back to step 2 with the error and
     retry, bounded by MAX_QUERY_ATTEMPTS. The generated SQL is also
     checked against the real, live course code/name list -- if it filters
     on a course/subject/department value that never appears anywhere in
     the question, that's treated as a fabricated substitution and
     declined rather than executed.
  4. Answer generation     -- question + SQL + result -> plain-English
     answer, grounded strictly in the returned rows.

No stage here asks the model to invoke a tool itself, so the entire class
of "model narrates a fake tool call as text" bugs is structurally
impossible -- there's no tool-calling mechanism being offered to begin
with. This also means agent.py no longer requires a tool-calling-capable
Ollama model -- any model main.py can use will work here too.

Run a single question:
    python agent.py "How many students are there in total?"

Run the full test_questions.json set through the agent, one at a time:
    python agent.py --batch
"""

import sys
import json
import re
from pathlib import Path

from dotenv import load_dotenv
from llm_client import call_llm
from tools import get_schema_context, execute_sql_query
from db_connection import run_query

BASE_DIR = Path(__file__).parent
load_dotenv(BASE_DIR / ".env")

MAX_QUERY_ATTEMPTS = 3  # bounded retries on SQL errors before giving up

relevance_check_prompt = (BASE_DIR / "prompts" / "relevance_check_prompt.txt").read_text(encoding="utf-8")
query_generation_prompt = (BASE_DIR / "prompts" / "query_generation_prompt.txt").read_text(encoding="utf-8")
data_analysis_prompt = (BASE_DIR / "prompts" / "answer_generation_prompt.txt").read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Stage 0: deterministic write-intent block (no LLM call -- same fixed
# disclaimer every time, so this can never depend on a model remembering
# an instruction).
# ---------------------------------------------------------------------------

_WRITE_INTENT_PATTERN = re.compile(
    r"\b(delete|remove|drop|update|modify|change|edit|insert|add|create|alter|truncate)\b",
    re.IGNORECASE,
)

WRITE_REFUSAL_DISCLAIMER = (
    "I can't delete, update, or otherwise modify data in the database — I can only look up and report it."
)


def _question_requests_a_write(question: str) -> bool:
    """
    Heuristic check on the question text. Not perfect (e.g. "add up the
    total marks" would false-positive), but it trades some over-triggering
    for guaranteeing a genuine write request is never silently complied
    with -- this runs before any LLM is even called.
    """
    return bool(_WRITE_INTENT_PATTERN.search(question))


# ---------------------------------------------------------------------------
# Stage 2/3 support: catching a fabricated course/subject/department
# substitution in generated SQL -- e.g. silently mapping "machine learning"
# onto a real but unrelated course code, or "astronomy" onto a real but
# unrelated department. This is deliberately schema-driven, not hardcoded
# to any particular table or column: it discovers text columns, their
# tables, and any "paired display name" column live from
# information_schema, so it applies equally to courses, departments,
# subjects, countries, or any text column added to the schema later.
# ---------------------------------------------------------------------------

_ENTITY_FILTER_PATTERN = re.compile(
    r"(?:(\w+)\.)?(\w+)\s*"
    r"(?:=\s*'([^']*)'|IN\s*\(\s*((?:'[^']*'\s*,?\s*)+)\))",
    re.IGNORECASE,
)

_text_columns_cache = None  # {column_name: [table_name, ...]}


def _get_text_columns() -> dict:
    """
    Live map of every character/text column in the public schema to the
    table(s) it lives in, e.g. {"department": ["courses"], "course_code":
    ["students", "courses"]}. Queried fresh from information_schema, not
    hardcoded -- this is what makes the grounding check below apply to any
    column in the schema, not just a fixed list. Numeric/date/id-style
    columns are excluded since they're compared with unquoted literals our
    regex above doesn't even match, so they never reach this function.
    """
    global _text_columns_cache
    if _text_columns_cache is not None:
        return _text_columns_cache
    try:
        _, rows = run_query(
            "SELECT table_name, column_name FROM information_schema.columns "
            "WHERE table_schema = 'public' "
            "AND data_type IN ('character varying', 'text', 'character');"
        )
        columns = {}
        for row in rows:
            columns.setdefault(row["column_name"], []).append(row["table_name"])
        _text_columns_cache = columns
    except Exception:
        _text_columns_cache = {}
    return _text_columns_cache


def _get_name_like_column(table: str, exclude_column: str) -> str:
    """
    Finds another text column in the same table whose name suggests it
    holds a human-readable label for the same row (e.g. "course_name" is
    the name-like column for "course_code" in the courses table). Purely a
    naming heuristic (column name contains "name"), not specific to any
    one table -- this is what generalizes the old hardcoded
    course_code<->course_name pairing to any table with a similar
    code/name pattern.
    """
    text_columns = _get_text_columns()
    for column, tables in text_columns.items():
        if column == exclude_column:
            continue
        if table in tables and "name" in column.lower():
            return column
    return None


def _value_exists_in_column(table: str, column: str, value: str) -> bool:
    """Live check: does this literal actually match a real value in table.column (case-insensitive)?"""
    try:
        _, rows = run_query(
            f'SELECT 1 FROM "{table}" WHERE "{column}" ILIKE %s LIMIT 1;', (value,)
        )
        return len(rows) > 0
    except Exception:
        return False


def _get_paired_display_value(table: str, column: str, value: str) -> str:
    """If a name-like column exists in the same table, fetch its value for this row, live."""
    name_column = _get_name_like_column(table, column)
    if not name_column:
        return None
    try:
        _, rows = run_query(
            f'SELECT "{name_column}" FROM "{table}" WHERE "{column}" ILIKE %s LIMIT 1;', (value,)
        )
        return rows[0][name_column] if rows else None
    except Exception:
        return None


def _extract_entity_filter_literals(sql: str) -> list:
    """Returns [(column, literal_value), ...] for every column='...' / IN (...) filter found in sql, any column."""
    literals = []
    for match in _ENTITY_FILTER_PATTERN.finditer(sql):
        column = match.group(2)
        if match.group(3) is not None:
            literals.append((column, match.group(3)))
        elif match.group(4) is not None:
            for lit in re.findall(r"'([^']*)'", match.group(4)):
                literals.append((column, lit))
    return literals


def _find_ungrounded_entity_filter(question: str, sql: str):
    """
    Returns a short description of the first filter value that looks like
    a fabricated substitution -- a text-column literal in the SQL that (a)
    doesn't appear anywhere in the user's original question, and (b) isn't
    explained by a paired display-name column that does. Returns None if
    every text filter used is grounded in something the user actually said,
    or if the column isn't a recognized text column in the schema at all
    (numeric/date/id filters are never flagged by this check).

    Fully schema-driven: works for course_code<->course_name exactly as
    before, but equally for department, subject1/2/3, country, or any other
    text column -- none of that is hardcoded here.
    """
    question_lower = question.lower()
    text_columns = _get_text_columns()

    for column, value in _extract_entity_filter_literals(sql):
        tables = text_columns.get(column)
        if not tables:
            continue  # not a known text column (e.g. a numeric/id column, or a typo the DB error will catch) -- not this check's job

        value_lower = value.strip().lower()
        if not value_lower or value_lower in question_lower:
            continue

        grounded = False
        for table in tables:
            if not _value_exists_in_column(table, column, value):
                continue  # literal isn't even a real value in this table -- try the next table it might belong to
            paired = _get_paired_display_value(table, column, value)
            if paired and paired.lower() in question_lower:
                grounded = True
                break
        if grounded:
            continue

        return f"{column} = '{value}'"
    return None


# ---------------------------------------------------------------------------
# Stage helpers
# ---------------------------------------------------------------------------

def _extract_sql(llm_output: str) -> str:
    match = re.search(r"```(?:sql)?\s*(.*?)```", llm_output, re.DOTALL | re.IGNORECASE)
    return (match.group(1) if match else llm_output).strip()


def _extract_json(llm_output: str) -> dict:
    """Best-effort extraction of a JSON object from a response that may have stray text around it."""
    match = re.search(r"\{.*\}", llm_output, re.DOTALL)
    if not match:
        return {}
    try:
        return json.loads(match.group(0))
    except json.JSONDecodeError:
        return {}


def _format_result(columns, rows) -> str:
    if not rows:
        return "(no rows returned)"
    lines = [" | ".join(columns)]
    for row in rows:
        lines.append(" | ".join(str(row.get(c, "")) for c in columns))
    return "\n".join(lines)


def _check_relevance(schema: str, question: str) -> dict:
    prompt = (
        relevance_check_prompt
        .replace("{{schema_context}}", schema)
        .replace("{{question}}", question)
    )
    raw = call_llm(prompt, temperature=0.0)
    parsed = _extract_json(raw)
    # If the model didn't return valid JSON, fail OPEN (treat as answerable)
    # rather than blocking a legitimate question over a formatting slip --
    # stage 2/3's own entity-grounding check is still there as a backstop.
    return {
        "answerable": parsed.get("answerable", True),
        "reason": parsed.get("reason", ""),
    }


def _generate_query(schema: str, question: str, previous_error: str = None) -> str:
    prompt = (
        query_generation_prompt
        .replace("{{schema_context}}", schema)
        .replace("{{question}}", question)
    )
    if previous_error:
        prompt += (
            f"\n\nYour previous query failed with this database error:\n{previous_error}\n"
            f"Fix the query based on this error and return only the corrected SQL."
        )
    raw = call_llm(prompt, temperature=0.0)
    return _extract_sql(raw)


def _generate_answer(question: str, sql: str, columns, rows) -> str:
    prompt = (
        data_analysis_prompt
        .replace("{{question}}", question)
        .replace("{{sql_query}}", sql)
        .replace("{{query_result}}", _format_result(columns, rows))
    )
    return call_llm(prompt)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def run_agent(question: str, verbose: bool = True) -> dict:
    """
    Run the full multi-stage pipeline for one question. Returns a dict with
    the final answer plus a full trace of every stage -- schema/write
    checks, each query attempt, each execution result -- so the behavior is
    auditable, not a black box.
    """
    trace = []

    # Stage 0: deterministic write-intent check, no LLM involved.
    if _question_requests_a_write(question):
        trace.append({"stage": "write_intent_blocked", "content": WRITE_REFUSAL_DISCLAIMER})
        if verbose:
            print("  [stage 0] write-intent detected -- refusing without calling the model")
        return {"question": question, "answer": WRITE_REFUSAL_DISCLAIMER, "trace": trace}

    schema = get_schema_context()

    # Stage 1: relevance/grounding check.
    relevance = _check_relevance(schema, question)
    trace.append({"stage": "relevance_check", "result": relevance})
    if verbose:
        print(f"  [stage 1] answerable={relevance['answerable']}  reason={relevance['reason']!r}")

    if not relevance["answerable"]:
        answer = relevance["reason"] or "That doesn't appear to be something this database can answer."
        trace.append({"stage": "final_answer", "content": answer})
        return {"question": question, "answer": answer, "trace": trace}

    # Stages 2 + 3: generate SQL, execute, retry on error (bounded).
    previous_error = None
    columns, rows, sql = None, None, None
    for attempt in range(1, MAX_QUERY_ATTEMPTS + 1):
        sql = _generate_query(schema, question, previous_error)
        trace.append({"stage": "query_generation", "attempt": attempt, "sql": sql})
        if verbose:
            print(f"  [attempt {attempt}] SQL: {sql}")

        ungrounded = _find_ungrounded_entity_filter(question, sql)
        if ungrounded:
            answer = (
                "I couldn't find that in the database. No such data is available, or the question may be based on a mistaken assumption."
            )
            trace.append({"stage": "ungrounded_filter_blocked", "attempt": attempt, "detail": ungrounded})
            if verbose:
                print(f"    -> blocked: generated SQL filters on {ungrounded}, which isn't grounded in the question")
            return {"question": question, "answer": answer, "trace": trace}

        result = json.loads(execute_sql_query(sql))
        trace.append({"stage": "execution", "attempt": attempt, "result": result})

        if result.get("success"):
            columns, rows = result["columns"], result["rows"]
            break

        previous_error = result.get("error", "Unknown error")
        if verbose:
            print(f"    -> error: {previous_error}")
    else:
        error_msg = f"I couldn't put together a working query after {MAX_QUERY_ATTEMPTS} attempts. Last error: {previous_error}"
        trace.append({"stage": "final_answer", "content": error_msg})
        return {"question": question, "answer": None, "error": error_msg, "trace": trace}

    # Stage 4: answer generation, grounded in the actual returned rows.
    answer = _generate_answer(question, sql, columns, rows)
    trace.append({"stage": "final_answer", "content": answer})
    if verbose:
        print(f"  [answer] {answer[:100]}...")

    return {"question": question, "answer": answer, "trace": trace}


def run_batch():
    with open(BASE_DIR / "test_questions.json", encoding="utf-8") as f:
        questions = json.load(f)

    results = []
    results_path = BASE_DIR / "agent_results.json"

    for q in questions:  # one at a time, same pattern as main.py's loop
        print(f"[{q['category']:7}] Q{q['id']}: {q['question']}")
        result = run_agent(q["question"], verbose=True)
        result["id"] = q["id"]
        result["category"] = q["category"]
        results.append(result)

        with open(results_path, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, default=str)

        if result.get("answer"):
            print(f"    -> {result['answer'][:100]}...")
        else:
            print(f"    -> FAILED: {result.get('error')}")

    print(f"\nDone. Full trace log written to {results_path}")


if __name__ == "__main__":
    if "--batch" in sys.argv:
        run_batch()
    else:
        question = " ".join(a for a in sys.argv[1:] if a != "--batch")
        if not question:
            question = input("Question: ")
        result = run_agent(question)
        print()
        print("ANSWER:", result.get("answer") or result.get("error"))
