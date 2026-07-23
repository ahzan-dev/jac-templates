# AI Triage

Paste a messy customer support message. Get a typed `Ticket` back.

A one-screen Jac app that demonstrates **`by llm()`** — the feature that lets you
delegate a function's body to a language model and get back a **real typed
object**, not a string you have to parse.

## What this demonstrates

This is the whole extractor. It lives in [`services/triage.jac`](services/triage.jac):

```jac
enum Priority { LOW, MEDIUM, HIGH, CRITICAL }

obj Ticket {
    has title: str;
    has summary: str;
    has priority: Priority;
    has tags: list[str];
}

def triage(raw: str) -> Ticket by llm();
```

That is it. There is no function body — `by llm()` replaces it.

Three things are worth staring at:

1. **No prompt strings.** The function name, the parameter types, and the shape
   of `Ticket` are compiled into the prompt for you. Search this repo for a
   prompt template; there isn't one.
2. **No response parsing.** No `json.loads`, no schema validation, no
   `try: data["priority"] except KeyError`. The declared return type *is* the
   parser — `triage(...)` hands you a `Ticket` whose `.priority` is a genuine
   `Priority` enum member you can compare with `==`.
3. **`sem`, not prompt engineering.** You steer the model by describing a field
   next to the field:

   ```jac
   sem Ticket.priority = "Urgency, judged on real user impact -- not on how upset the message sounds.";
   sem Priority.CRITICAL = "Data loss, a security issue, money at risk, or a full outage.";
   ```

   Those descriptions ride into the model's schema. Change the wording, change
   the behavior — no string surgery.

Typed objects cross the client/server boundary intact, so
[`components/TicketCard.jac`](components/TicketCard.jac) renders
`ticket.priority` and `ticket.tags` as ordinary typed attribute access.

## Run it

```bash
export OPENAI_API_KEY=sk-...    # see "Credentials" below
jac install
jac start --dev
```

Open <http://localhost:8000>.

## Credentials

byLLM is built into jaclang core — there is nothing to `pip install`.

The model is configured once in [`jac.toml`](jac.toml), and **nowhere else**:

```toml
[byllm.model]
default_model = "${LLM_MODEL:-gpt-4o-mini}"
api_key = "${OPENAI_API_KEY:-}"
```

Set the key in your environment before starting the server:

```bash
export OPENAI_API_KEY=sk-...
```

Switching providers is a one-line change to `default_model` — the Jac source
never moves:

| `default_model` | Env var |
| --- | --- |
| `gpt-4o-mini` *(default)*, `gpt-4o` | `OPENAI_API_KEY` |
| `claude-sonnet-4-6` | `ANTHROPIC_API_KEY` |
| `gemini/gemini-2.0-flash` | `GOOGLE_API_KEY` |
| `ollama/llama3` | none — local daemon |

`BYLLM_DEFAULT_MODEL=gpt-4o jac start --dev` overrides the default for one shell.

If the key is missing the app doesn't crash — `triage_ticket` catches
`AuthenticationError` and the UI shows you what to set.

### Zero-key option: run the model locally

byLLM bundles a local model that needs no API key and no account:

```bash
jac install 'byllm[local]'
jac model pull gemma-4-e2b
```

Then in `jac.toml`, point at it and drop the `api_key` line:

```toml
[byllm.model]
default_model = "local:gemma-4-e2b"
```

`gemma-4-e2b` is the small one; `local:gemma-4-e4b` is larger and more accurate.
Both download a multi-GB weights file on first pull. Extraction quality on a
small local model is noticeably below `gpt-4o-mini` — expect rougher titles and
occasional priority misreads — but the code is byte-for-byte identical, which is
the point.

## Layout

```
main.jac                        entry: server import + the client mount
jac.toml                        model config ([byllm.model]) + theme
services/triage.jac             the enum + obj + `by llm()` + sem wiring
components/TriageStudio.jac  the screen: input, states, layout
components/TicketCard.jac    typed result -> priority badge + tag chips
components/SourceCard.jac    the source, on screen next to the demo
components/ui/                  jac-shadcn primitives (yours to edit)
styles/global.css              semantic tokens incl. the status ramp
```

## Calling it without the UI

`triage_ticket` is a plain `def:pub`, so it is also a REST endpoint. The API
serves on the app port + 1:

```bash
curl -s -X POST http://localhost:8001/function/triage_ticket \
  -H 'Content-Type: application/json' \
  -d '{"raw": "cant log in since the update and my whole team is stuck, demo is tomorrow"}'
```

## Extending it

See [`AGENTS.md`](AGENTS.md) — it has a **Try next** list of concrete prompts,
plus how to reach the Jac reference guides bundled with the compiler
(`jac guide jac-by-llm` is the one that matters here).
