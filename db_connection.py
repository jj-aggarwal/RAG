"""
db_connection.py

Isolated PostgreSQL connection layer. Nothing else in this project imports
psycopg2 directly — everything goes through get_connection() / run_query()
so the database engine can be swapped later without touching main.py.

Configure via environment variables (recommended) or a .env file loaded
before this module is imported:

    PGHOST      default: localhost
    PGPORT      default: 5432
    PGDATABASE  default: university
    PGUSER      default: postgres
    PGPASSWORD  default: "" (empty)
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor


def get_connection(readonly: bool = True):
    """
    Open a new PostgreSQL connection using environment-based config.

    readonly=True (the default) puts the connection's transactions into
    Postgres's own read-only mode -- this is enforced by Postgres itself,
    independent of any SQL-text validation done elsewhere in the app. Even
    if a DELETE/UPDATE/INSERT/DDL statement somehow got past the checks in
    tools.py, Postgres would still refuse to execute it and raise a clear
    error instead of making the change. Pass readonly=False explicitly for
    any future script that genuinely needs to write (nothing in this
    project currently does).
    """
    conn = psycopg2.connect(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5432"),
        dbname=os.environ.get("PGDATABASE", "university"),
        user=os.environ.get("PGUSER", "postgres"),
        password=os.environ.get("PGPASSWORD", ""),
    )
    if readonly:
        conn.set_session(readonly=True)
    return conn


def run_query(sql: str, params: tuple | None = None, readonly: bool = True):
    """
    Execute a single SQL statement and return (columns, rows).

    - columns: list[str]
    - rows: list[dict]  (thanks to RealDictCursor, each row is column -> value)

    readonly=True by default (see get_connection above) -- every caller in
    this project (main.py, tools.py) runs LLM-generated SQL, so defaulting
    to read-only here means a write attempt fails at the database level
    even if something upstream forgot to check for one.

    Raises whatever psycopg2 raises on a bad query (syntax error, missing
    table/column, an attempted write in a read-only transaction, etc.) —
    the caller is expected to catch this per-question so one bad generated
    query doesn't kill the whole run.
    """
    conn = get_connection(readonly=readonly)
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(sql, params)
            if cur.description is None:
                # statement returned no result set (e.g. DDL/DML with no RETURNING)
                return [], []
            columns = [desc[0] for desc in cur.description]
            rows = cur.fetchall()
            return columns, rows
    finally:
        conn.close()


def test_connection() -> bool:
    """Quick sanity check you can run standalone: python db_connection.py"""
    try:
        columns, rows = run_query("SELECT 1 AS ok;")
        return rows and rows[0]["ok"] == 1
    except Exception as e:
        print(f"Connection test failed: {e}")
        return False


if __name__ == "__main__":
    from dotenv import load_dotenv
    from pathlib import Path
    load_dotenv(Path(__file__).parent / ".env")

    if test_connection():
        print("Database connection OK.")
    else:
        print("Database connection FAILED. Check PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD.")
