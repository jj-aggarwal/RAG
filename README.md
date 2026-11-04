# Frontend

React (Vite) single-page app. One screen: a question box and a running ledger of question/answer pairs.

## Setup

```
npm install
```

## Run (development)

```
npm run dev
```

Opens on `http://localhost:5173`. Requests to `/api/*` are automatically proxied to the Flask backend at `http://localhost:5000` (see `vite.config.js`) — so the backend must already be running (see `../backend/README.md`) for questions to actually work.

## Build (production)

```
npm run build
```

Outputs static files to `dist/`. Serve these with any static file host, or have Flask serve them directly (not configured out of the box — `app.py` is currently API-only, CORS-enabled, meant to be called by the Vite dev server or a separately-hosted build).

## What it does

- Type a question, press Enter or click **Ask**.
- The question is sent to `POST /api/ask` on the Flask backend, which runs it through `agent.py` (the Phase 2 tool-calling agent, not the simpler CLI pipeline).
- The plain-English answer is shown once it comes back.
- If a question fails outright (agent couldn't resolve it, or the backend is unreachable), the error is shown in place of an answer, and you can just ask another question — nothing gets stuck.

## Database Inspector (sidebar)

A panel on the right shows:
- **Live tables** — fetched from `GET /api/schema/tables`, which queries Postgres's `information_schema` directly, not a static file. Click the refresh icon to re-fetch on demand.
- **Table details** — click any table to expand it: column names/types, a live row count, and a 5-row sample, all from `GET /api/schema/tables/<name>`.
- **Clear memory** — wipes the server-side `query_log.json` via `POST /api/memory/clear`, and also clears the conversation currently shown on screen.

On narrow screens (under ~860px) the sidebar hides itself to keep the main conversation usable.
