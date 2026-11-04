"""
llm_client.py

Isolated wrapper around a local Ollama server. Keeping this in its own file
means main.py doesn't need to know which model or backend is behind
call_llm() -- swap this file out and everything else keeps working.

Requires Ollama running locally (or reachable at OLLAMA_HOST) with the
target model already pulled, e.g.:

    ollama pull llama3.1        # or: sqlcoder, codellama, mistral, etc.
    ollama serve                # usually already running as a background service

Configure via environment variables:

    OLLAMA_HOST     default: http://localhost:11434
    OLLAMA_MODEL    default: llama3.1
    OLLAMA_TIMEOUT  default: 300 (seconds). Raise this if you hit ReadTimeout
                    errors on CPU-only machines or with larger models.
"""

import os
import requests

DEFAULT_HOST = "http://localhost:11434"
DEFAULT_MODEL = "llama3.1"
DEFAULT_TIMEOUT = 300


def call_llm(prompt: str, model: str | None = None, max_tokens: int = 1024, temperature: float = 0.0) -> str:
    """
    Send a single-turn prompt to a local Ollama model and return the text response.

    temperature defaults to 0.0 since this is used for SQL generation, where
    determinism matters more than creativity.
    """
    host = os.environ.get("OLLAMA_HOST", DEFAULT_HOST).rstrip("/")
    model = model or os.environ.get("OLLAMA_MODEL", DEFAULT_MODEL)
    timeout = int(os.environ.get("OLLAMA_TIMEOUT", DEFAULT_TIMEOUT))

    try:
        response = requests.post(
            f"{host}/api/chat",
            json={
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                },
            },
            timeout=timeout,
        )
        response.raise_for_status()
    except requests.exceptions.ConnectionError as e:
        raise RuntimeError(
            f"Could not reach Ollama at {host}. Is `ollama serve` running? "
            f"(underlying error: {e})"
        ) from e
    except requests.exceptions.ReadTimeout as e:
        raise RuntimeError(
            f"Ollama at {host} accepted the request but didn't respond within "
            f"{timeout}s. The model is likely just slow on this hardware (common "
            f"on CPU-only machines). Try: a smaller/faster model, raising "
            f"OLLAMA_TIMEOUT further, or reducing max_tokens. "
            f"(underlying error: {e})"
        ) from e
    except requests.exceptions.HTTPError as e:
        raise RuntimeError(
            f"Ollama returned an error for model '{model}'. Have you run "
            f"`ollama pull {model}`? (underlying error: {e})"
        ) from e

    data = response.json()
    return data.get("message", {}).get("content", "")


def call_llm_with_tools(
    messages: list[dict],
    tools: list[dict],
    model: str | None = None,
    max_tokens: int = 1024,
    temperature: float = 0.0,
) -> dict:
    """
    Phase 2: send a multi-turn conversation plus tool definitions to Ollama
    and return the raw assistant message dict (may contain 'content' and/or
    'tool_calls'). Used by agent.py's tool-calling loop.

    call_llm() above is left untouched -- main.py's Phase 1 pipeline keeps
    working exactly as before, unaffected by this.

    Requires a model that actually supports tool calling: qwen2.5-coder,
    llama3.1, llama3.3, mistral-nemo, and command-r all do. Many smaller or
    older models don't, and will error out or ignore the tools entirely.
    """
    host = os.environ.get("OLLAMA_HOST", DEFAULT_HOST).rstrip("/")
    model = model or os.environ.get("OLLAMA_MODEL", DEFAULT_MODEL)
    timeout = int(os.environ.get("OLLAMA_TIMEOUT", DEFAULT_TIMEOUT))

    try:
        response = requests.post(
            f"{host}/api/chat",
            json={
                "model": model,
                "messages": messages,
                "tools": tools,
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                },
            },
            timeout=timeout,
        )
        response.raise_for_status()
    except requests.exceptions.ConnectionError as e:
        raise RuntimeError(
            f"Could not reach Ollama at {host}. Is `ollama serve` running? "
            f"(underlying error: {e})"
        ) from e
    except requests.exceptions.ReadTimeout as e:
        raise RuntimeError(
            f"Ollama at {host} accepted the request but didn't respond within "
            f"{timeout}s. (underlying error: {e})"
        ) from e
    except requests.exceptions.HTTPError as e:
        raise RuntimeError(
            f"Ollama returned an error for model '{model}'. Does this model "
            f"support tool calling? (qwen2.5-coder, llama3.1, llama3.3, "
            f"mistral-nemo, command-r do; many others don't.) "
            f"(underlying error: {e})"
        ) from e

    data = response.json()
    return data.get("message", {})
