"""
main.py

Interactive text-to-SQL tool: type a question, get an answer.

For each question:
  1. Query Generation  -> LLM turns (schema_context + question) into SQL
  2. Database Run       -> SQL is executed against PostgreSQL
  3. Answer Generation  -> LLM turns (question + SQL + result) into a plain-English answer

Run:
    python main.py

Type a question and press Enter. Type 'exit' or 'quit' to stop.
"""

import json
import re
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from db_connection import run_query
from llm_client import call_llm

BASE_DIR = Path(__file__).parent
LOG_PATH = BASE_DIR / "query_log.json"

# Load environment variables from .env (PGHOST, PGDATABASE, OLLAMA_MODEL, etc.)
load_dotenv(BASE_DIR / ".env")

# ---------------------------------------------------------------------------
# Load the semantic metadata document (Phase 1: Knowledge Modeling output)
# ---------------------------------------------------------------------------
schema_context = (BASE_DIR / "schema_context.md").read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# Load prompt templates (kept as separate files, not hardcoded strings)
# ---------------------------------------------------------------------------
query_generation_prompt = (BASE_DIR / "prompts" / "query_generation_prompt.txt").read_text(encoding="utf-8")
data_analysis_prompt = (BASE_DIR / "prompts" / "answer_generation_prompt.txt").read_text(encoding="utf-8")


def extract_sql(llm_output: str) -> str:
    """Pull the SQL out of a ```sql ... ``` code block, or fall back to the raw text."""
    match = re.search(r"```(?:sql)?\s*(.*?)```", llm_output, re.DOTALL | re.IGNORECASE)
    return (match.group(1) if match else llm_output).strip()


def build_query_generation_prompt(question: str) -> str:
    return (
        query_generation_prompt
        .replace("{{schema_context}}", schema_context)
        .replace("{{question}}", question)
    )


def format_result_as_text(columns, rows) -> str:
    if not rows:
        return "(no rows returned)"
    lines = [" | ".join(columns)]
    for row in rows:
        lines.append(" | ".join(str(row[c]) for c in columns))
    return "\n".join(lines)


def build_data_analysis_prompt(question: str, sql: str, columns, rows) -> str:
    return (
        data_analysis_prompt
        .replace("{{question}}", question)
        .replace("{{sql_query}}", sql)
        .replace("{{query_result}}", format_result_as_text(columns, rows))
    )


def answer_question(question: str) -> dict:
    """
    Run the full generate -> execute -> answer cycle for one question.
    Returns a dict (not just the answer string) so the caller has enough
    detail -- SQL, status, error -- to log the interaction properly.
    """
    log = {"question": question}

    # --- Step 1: Query Generation Prompt ---
    gen_prompt = build_query_generation_prompt(question)
    sql_raw = call_llm(gen_prompt, temperature=0.0)
    sql = extract_sql(sql_raw)
    log["generated_sql"] = sql
    print(f"  (generated SQL: {sql})")

    # --- Step 2: Database Run ---
    try:
        columns, rows = run_query(sql)
    except Exception as e:
        log["status"] = "sql_error"
        log["error"] = str(e)
        log["answer"] = f"Sorry, the query I generated didn't run correctly: {e}"
        return log

    log["status"] = "success"
    log["row_count"] = len(rows)

    # --- Step 3: Answer Generation Prompt ---
    analysis_prompt = build_data_analysis_prompt(question, sql, columns, rows)
    log["answer"] = call_llm(analysis_prompt)
    return log


def load_log() -> list[dict]:
    if LOG_PATH.exists():
        try:
            with open(LOG_PATH, encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return []
    return []


def append_to_log(entry: dict) -> None:
    """Append one entry and rewrite the log file immediately, so a crash mid-session doesn't lose earlier questions."""
    entries = load_log()
    entries.append(entry)
    with open(LOG_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, default=str)


def main():
    print("Ask a question about the university database.")
    print("Type 'exit' or 'quit' to stop.\n")
    print(f"(Every question and answer is logged to {LOG_PATH.name})\n")

    while True:
        question = input("Question: ").strip()
        if not question:
            continue
        if question.lower() in ("exit", "quit"):
            print("Goodbye.")
            break

        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        try:
            result = answer_question(question)
        except Exception as e:
            result = {"question": question, "status": "error", "error": str(e), "answer": f"Something went wrong: {e}"}

        result["timestamp"] = timestamp
        append_to_log(result)

        print(f"\nAnswer: {result['answer']}\n")


if __name__ == "__main__":
    main()
