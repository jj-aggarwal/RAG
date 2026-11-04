"""
tools.py

The two agent tools from the Phase 2 spec, as plain Python functions, plus
their JSON-schema tool definitions in OpenAI-compatible function-calling
format (which Ollama's /api/chat endpoint understands for tool-calling
models such as qwen2.5-coder, llama3.1, llama3.3, mistral-nemo, command-r).

Tool 1: get_schema_context()            -> full contents of schema_context.md
Tool 2: execute_sql_query(query_string) -> query results as JSON, or a
                                            structured error the agent can
                                            read and self-correct from
"""

import json
from pathlib import Path

import sqlparse
from sqlparse.tokens import Keyword

from db_connection import run_query

BASE_DIR = Path(__file__).parent
SCHEMA_PATH = BASE_DIR / "northwind_schema_context.md"

MAX_ROWS_RETURNED = 50  # cap so a huge result set doesn't blow the context window

# Statement types / keywords that must never reach the database, no matter
# what the model generates or what the user's question asked for.
FORBIDDEN_KEYWORDS = {
    "DELETE", "UPDATE", "INSERT", "DROP", "ALTER", "TRUNCATE",
    "CREATE", "GRANT", "REVOKE", "REPLACE", "MERGE", "CALL",
    "EXECUTE", "COPY", "VACUUM", "LOCK", "COMMENT", "RENAME",
}


def get_schema_context() -> str:
    """Return the full contents of schema_context.md."""
    return SCHEMA_PATH.read_text(encoding="utf-8")


def is_safe_select(query_string: str) -> tuple[bool, str]:
    """
    Returns (True, "") if query_string is a single, read-only SELECT
    statement (including a WITH ... SELECT common table expression).
    Returns (False, reason) for anything else -- this is the gate that
    stops the agent (or a user trying to smuggle instructions through the
    question text) from ever running a destructive statement.

    Uses sqlparse to identify the actual statement type and scan real SQL
    keyword tokens, rather than a crude substring search on the raw text --
    a substring check would both false-positive on a SELECT whose WHERE
    clause happens to contain the word "delete" as a string literal, and
    false-negative on anything creatively formatted to dodge a naive check.
    """
    if not query_string or not query_string.strip():
        return False, "Empty query."

    parsed = sqlparse.parse(query_string)
    statements = [s for s in parsed if s.token_first(skip_ws=True, skip_cm=True) is not None]

    if len(statements) == 0:
        return False, "Empty query."
    if len(statements) > 1:
        return False, "Only a single SQL statement is allowed (no stacked/multiple statements separated by ';')."

    stmt = statements[0]
    stmt_type = stmt.get_type()  # 'SELECT', 'DELETE', 'UPDATE', 'INSERT', 'CREATE', 'DROP', 'UNKNOWN', ...
    first_token = stmt.token_first(skip_ws=True, skip_cm=True)
    first_word = first_token.value.upper() if first_token else ""

    if stmt_type != "SELECT" and not (stmt_type == "UNKNOWN" and first_word == "WITH"):
        # sqlparse tags most non-SELECT statements correctly (DELETE, UPDATE,
        # INSERT, CREATE, DROP, ...). It tags a WITH ... SELECT CTE as
        # 'UNKNOWN', which is the one case allowed through here -- anything
        # else starting with something other than SELECT/WITH is rejected.
        label = stmt_type if stmt_type != "UNKNOWN" else first_word
        return False, f"Only SELECT queries are permitted. This looks like a {label} statement."

    # Extra guard even for accepted SELECT/WITH statements: scan every real
    # SQL keyword token (not string literals, not identifiers) for anything
    # on the forbidden list. Catches a forbidden statement hidden inside a
    # CTE body, or any sqlparse mis-tag.
    for token in stmt.flatten():
        if token.ttype in (Keyword.DML, Keyword.DDL, Keyword) and token.value.upper() in FORBIDDEN_KEYWORDS:
            return False, f"Query contains a forbidden keyword: {token.value.upper()}."

    return True, ""


def execute_sql_query(query_string: str) -> str:
    """
    Execute a SQL query against the PostgreSQL database and return the
    result as a JSON string.

    Every query is checked with is_safe_select() first. A DELETE, UPDATE,
    INSERT, DROP, or any other data-modifying statement is rejected here
    and never reaches run_query() / the database at all -- this holds
    regardless of what the model generates or what the original question
    asked for. The database connection is also opened read-only (see
    db_connection.py) as a second, independent layer of protection.

    On any failure -- rejected query or a real database error -- this
    returns a JSON object with success: false and an 'error' field instead
    of raising, so the agent gets it as a normal tool result it can read
    and react to, not a crash that ends the conversation.
    """
    is_safe, reason = is_safe_select(query_string)
    if not is_safe:
        return json.dumps({
            "success": False,
            "error": (
                f"Query rejected: {reason} This tool only allows read-only "
                f"SELECT queries. If the user asked to add, change, or "
                f"delete data, do not attempt it -- explain that you can "
                f"only look up and report data, and offer to show them the "
                f"matching records with a SELECT instead if that would help."
            ),
            "query": query_string,
        })

    try:
        columns, rows = run_query(query_string)
        truncated = len(rows) > MAX_ROWS_RETURNED
        return json.dumps({
            "success": True,
            "columns": columns,
            "row_count": len(rows),
            "rows": rows[:MAX_ROWS_RETURNED],
            "truncated": truncated,
        }, default=str)
    except Exception as e:
        return json.dumps({
            "success": False,
            "error": str(e),
            "query": query_string,
        })


TOOL_SCHEMAS = [
    {
        "type": "function",
        "function": {
            "name": "get_schema_context",
            "description": (
                "Returns the full database schema context document: table "
                "definitions, column meanings, foreign key relationships, "
                "enum/value mappings, and query guidelines. Call this first, "
                "before writing any SQL, if you don't already have it in this "
                "conversation."
            ),
            "parameters": {"type": "object", "properties": {}, "required": []},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "execute_sql_query",
            "description": (
                "Executes a read-only SQL SELECT query against the PostgreSQL "
                "database and returns the result as JSON. Only SELECT (or "
                "WITH ... SELECT) statements are permitted -- any DELETE, "
                "UPDATE, INSERT, DROP, or other data-modifying statement is "
                "rejected before it ever runs and returns success: false. "
                "If the query is invalid, references a table/column that "
                "doesn't exist, or was rejected for not being a SELECT, this "
                "returns success: false with an 'error' field describing "
                "exactly what went wrong. Read that error and either fix "
                "the query and call this tool again, or -- if the error "
                "says the query was rejected for not being read-only -- "
                "explain to the user that you can only look up data, not "
                "modify it."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "query_string": {
                        "type": "string",
                        "description": "A single valid SQL SELECT statement.",
                    }
                },
                "required": ["query_string"],
            },
        },
    },
]

TOOL_FUNCTIONS = {
    "get_schema_context": get_schema_context,
    "execute_sql_query": execute_sql_query,
}
