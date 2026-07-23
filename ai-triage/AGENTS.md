# Working in this Jac project

This is a [Jac](https://www.jaseci.org/) project. Jac's syntax has evolved and
is easily confused with Python or JSX -- before writing or editing `.jac`
files, consult the reference guides bundled with the compiler.

## Reference guides

The `jac` CLI ships curated reference guides ("Agent Skills") -- the
authoritative spec for writing correct, idiomatic Jac:

- `jac guide` -- list every available guide
- `jac guide <name>` -- print a guide (e.g. `jac guide jac-types`)
- `jac guide --search <keyword>` -- find guides by topic
- `jac guide --json` -- machine-readable output for tooling

Start with `jac guide jac-core-cheatsheet` and `jac guide jac-types`.

**For this project specifically, read `jac guide jac-by-llm` before touching
`services/triage.jac`.** It is the authoritative spec for `by llm()`, `sem`
wiring, typed returns, tools, and model config.

## What this app is

A structured extractor. `services/triage.jac` declares an `enum`, an `obj`, and
one bodiless function:

```jac
def triage(raw: str) -> Ticket by llm();
```

The LLM fills the declared return type. The rules that keep this template honest:

- **Never write a prompt string.** The types plus `sem` statements *are* the
  prompt. If you catch yourself building an f-string of instructions, you have
  taken a wrong turn — describe the field with `sem` instead.
- **Never parse the model's output.** No `json.loads`, no `.get("priority")`,
  no regex. The declared return type is the parser; `by llm()` already retries
  malformed output for you (`max_output_retries`, default 3).
- **`sem`, never docstrings, for anything the model should see.** A
  triple-quoted string inside a body is a `W0060`, and it does not reach the model.
- **Model config lives only in `jac.toml`** under `[byllm.model]`. Do not
  hardcode a model name or an API key in `.jac` source.
- byLLM is **built into jaclang core** — do not `jac add byllm`. The PyPI
  package of that name is a stale pre-fold copy and will shadow core with an
  import error. Import from `jaclang.byllm.lib`.

## Styling rules

- Semantic tokens only: `bg-background`, `text-muted-foreground`, `bg-card`,
  `border-border`, `text-primary`, `text-destructive`, and the status ramp
  (`text-success`, `text-info`, `text-warning`). Never a raw Tailwind color
  like `text-green-400`, never a hex value.
- Single theme. There is deliberately no light/dark toggle.
- Concatenate classes with `cn()` from `lib/utils.jac`, never with `+`.
- Physical padding (`pt-4 pb-4`), not shorthand (`py-4`).
- New status colors go in `styles/global.css` as tokens (`:root` + `@theme
  inline`), not inline in a component.

## Try next

Concrete next steps. Each is a self-contained prompt you can hand to an agent.

1. **"Extract sentiment too."** Add `enum Tone { CALM, FRUSTRATED, ANGRY }` and
   a `has tone: Tone;` to `Ticket`, with `sem` for every member. Render it next
   to the priority badge. Note that you change zero prompt text to do this —
   that is the demo.
2. **"Make the model tell me when a message isn't a support ticket."** Change
   the signature to `-> Ticket | None` and `sem` the function to return nothing
   for spam or chitchat. Show an empty state when it comes back `None`.
3. **"Add batch mode: upload a CSV of messages and triage every row."** Use
   `dispatch_batch` from `jaclang.byllm.lib` to run the calls in parallel, and
   render the results as a sortable table grouped by priority.
4. **"Route CRITICAL tickets to a webhook."** After extraction, if
   `ticket.priority == Priority.CRITICAL`, POST the ticket to a URL from an env
   var. Keep the LLM function pure — do the routing in `triage_ticket`.
5. **"Persist every triaged ticket and add a history panel."** Add a `Ticket`
   *node* (keep the LLM `obj` separate — copy the fields across so the AI schema
   and the storage schema can evolve independently), connect it to `root`, and
   list past tickets. See `jac guide jac-sv-persistence`.
6. **"Let the model look up the customer's plan before deciding priority."**
   Write a `def lookup_plan(email: str) -> str` and pass it as
   `by llm(tools=[lookup_plan])`. The ReAct loop turns on automatically —
   give the tool and each of its args a `sem`.
7. **"Add tests that run in CI without an API key."** Use `MockLLM` from
   `jaclang.byllm.lib` with pre-built `Ticket` instances in `outputs`. See
   `jac guide jac-testing`.

## Validate your work

- `jac check <file>` -- type-check and lint. Compiler diagnostics link to the
  relevant guide; follow the `-> run 'jac guide ...'` hints.
- `jac run <file>` -- execute a Jac script.
- `jac start --dev main.jac` -- start a web-app or service in dev mode
  (hot-reload for client files; restart for server changes). Use this instead
  of `jac run` for apps.
- `jac browse <action>` -- QA a running app in a headless browser:
  `jac browse open localhost:8000`, then `snapshot` (accessibility tree with
  `@e1`-style refs), `click @e5`, `fill '#email' user@example.com`, `screenshot`, `close`.

_Generated by `jac create`._
