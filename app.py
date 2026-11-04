"""
app.py

Flask API for the web frontend. Wraps agent.py's tool-calling loop
(schema injection + execute_sql_query with self-correction) behind a
single HTTP endpoint the React app can call.

This does not replace main.py -- main.py is still the simple interactive
CLI using the fixed Phase-1 pipeline. app.py is a separate entry point
that uses the Phase-2 agent for result generation instead, as requested.

Run:
    python app.py

Then hit:
    POST /api/ask                              -> agent result JSON
    GET  /api/health                            -> { "status": "ok" }
    GET  /api/schema/tables                     -> list of live table names
    GET  /api/schema/tables/<table_name>        -> columns, row count, sample rows for one table
    POST /api/memory/clear                      -> clears query_log.json (Database Inspector's "Clear memory" button)
"""

import json
from pathlib import Path
from datetime import datetime, timezone

from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

from agent import run_agent
from db_connection import run_query
from main import append_to_log  # reuse the same query_log.json logging as the CLI

BASE_DIR = Path(__file__).parent
LOG_PATH = BASE_DIR / "query_log.json"
load_dotenv(BASE_DIR / ".env")

app = Flask(__name__)
CORS(app)  # allow the React dev server (different port) to call this API directly if not using the Vite proxy

SAMPLE_ROW_LIMIT = 5


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


@app.route("/api/ask", methods=["POST"])
def ask():
    data = request.get_json(silent=True) or {}
    question = (data.get("question") or "").strip()

    if not question:
        return jsonify({"error": "No question provided."}), 400

    try:
        result = run_agent(question, verbose=False)
    except Exception as e:
        # something broke outside the agent's own error handling (e.g. Ollama unreachable)
        error_payload = {"question": question, "error": str(e)}
        error_payload["timestamp"] = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        error_payload["source"] = "web_agent"
        try:
            append_to_log(error_payload)
        except Exception:
            pass  # logging failure shouldn't hide the real error from the client
        return jsonify({"error": str(e)}), 500

    result["timestamp"] = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    result["source"] = "web_agent"
    try:
        append_to_log(result)
    except Exception:
        pass  # logging is best-effort; don't fail the request over it

    status_code = 200 if result.get("answer") else 502
    return jsonify(result), status_code


def get_valid_table_names() -> set:
    """
    Live list of tables actually in the database right now. Used both to
    populate the sidebar and as a safety allowlist for the preview endpoint
    below, since a table name can't be safely parameterized as a SQL
    identifier the way a normal value can.
    """
    _, rows = run_query(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_schema = 'public' ORDER BY table_name;"
    )
    return {r["table_name"] for r in rows}


@app.route("/api/schema/tables", methods=["GET"])
def list_tables():
    """Real-time table list, queried live from Postgres -- not the static schema_context.md."""
    try:
        _, rows = run_query(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'public' ORDER BY table_name;"
        )
        return jsonify({"tables": [r["table_name"] for r in rows]})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/schema/tables/<table_name>", methods=["GET"])
def table_detail(table_name):
    """
    Column definitions, live row count, and a small sample of real rows for
    one table -- everything the sidebar needs for one table, in one call.
    """
    try:
        valid_tables = get_valid_table_names()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    if table_name not in valid_tables:
        return jsonify({"error": f"Table '{table_name}' not found."}), 404

    try:
        _, column_rows = run_query(
            "SELECT column_name, data_type, is_nullable "
            "FROM information_schema.columns "
            "WHERE table_schema = 'public' AND table_name = %s "
            "ORDER BY ordinal_position;",
            (table_name,),
        )

        # table_name is validated against a live allowlist above, so it's safe
        # to interpolate as an identifier here -- psycopg2 can't parameterize
        # identifiers the way it does values.
        _, count_rows = run_query(f'SELECT COUNT(*) AS n FROM "{table_name}";')
        row_count = count_rows[0]["n"]

        sample_columns, sample_rows = run_query(
            f'SELECT * FROM "{table_name}" LIMIT {SAMPLE_ROW_LIMIT};'
        )

        return jsonify({
            "table": table_name,
            "columns": column_rows,
            "row_count": row_count,
            "sample_columns": sample_columns,
            "sample_rows": sample_rows,
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/memory/clear", methods=["POST"])
def clear_memory():
    """Wipes query_log.json back to an empty list -- the 'memory clear' button."""
    try:
        with open(LOG_PATH, "w", encoding="utf-8") as f:
            json.dump([], f)
        return jsonify({"status": "cleared"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
