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
`services/support.jac`.** It is the authoritative spec for `by llm()`, `sem`
wiring, and `tools=[...]`. Also useful here: `jac guide jac-node-edge-patterns`
(the seed graph), `jac guide jac-shadcn-blocks` (the UI).

## What this app is

A support desk. One bodiless function is the whole agent:

```jac
def ask(question: str) -> str by llm(
    tools=[search_docs, get_customer, get_tier_limits, get_billing, get_projects, open_ticket],
    max_react_iterations=6
);
```

Passing `tools=[...]` turns the ReAct loop on. The model reads each tool's
`sem` and decides which ones the question needs — a general question uses
`search_docs` alone, an allowance question chains `get_customer` into
`get_tier_limits`. Every tool records its own call into `_TRACE`, and
`ask_support()` returns that trace with the answer so the UI can show which
tools ran. **The trace is the feature** — it is how the loop becomes visible.

## Rules that keep this template honest

- **Never write a prompt string.** `sem ask` is the only steering text in the
  project, and it is attached to the declaration, not assembled at runtime. To
  change the agent's judgement, edit the `sem` — not the code around it.
- **Never parse the model's output.** No `json.loads`, no regex.
- **Every tool needs a `sem` for itself AND for every parameter.** That is how
  the model knows a tool exists and when it applies. A tool without a `sem` is
  invisible to the agent.
- **Keep tool bodies short** and return a readable string the model can reason
  over. Tools are for fetching facts, not for making decisions.
- **New tool = add it to `tools=[...]`, give it a `sem`, and record it in
  `_TRACE`.** Miss the trace and it will work but stay invisible in the UI.
- **Never use a backward edge traversal (`[node <-:Edge:<-]`) across users.**
  It silently returns empty in Jac 0.31.0. All seed data lives on one root
  here, which sidesteps it — keep it that way.
- Model config lives only in `jac.toml` under `[byllm.model]`. Never hardcode a
  model name or an API key in `.jac` source.

## Styling rules

- Semantic tokens only: `bg-background`, `text-muted-foreground`, `bg-card`,
  `border-border`, `text-primary`, `text-destructive`, and the status ramp
  (`text-success`, `text-warning`). Never a raw Tailwind color like
  `text-green-400`, never a hex value.
- Single theme. There is deliberately no light/dark toggle.
- Concatenate classes with `cn()` from `lib/utils.jac`, never with `+`.
  `cn` is not auto-injected — import it explicitly.
- Physical padding (`pt-4 pb-4`), not shorthand (`py-4`).

## Try next

Concrete next steps. Each is a self-contained prompt you can hand to an agent.

1. **"Swap the knowledge base for my own product's docs."** Replace the files in
   `knowledge/` with your own markdown. Change nothing else — `search_docs`
   reads whatever is in that directory at runtime. This is the main fork point.
2. **"Add a tool that checks service status."** Write `def get_status(component: str) -> str`,
   add it to `tools=[...]` in `services/support.jac`, give it a `sem` for the
   function and its parameter, and record the call in `_TRACE`. Then ask "is the
   build system down?" and watch the agent reach for it unprompted.
3. **"Replace keyword search with real vector search."** `search_docs` currently
   substring-matches. Chunk `knowledge/*.md`, embed the chunks, and rank by
   cosine similarity. The agent's code does not change at all — only the tool
   body — which is the point.
4. **"Add auth so each customer only sees their own data."** Today `ask_support`
   is `def:pub` and every seeded customer is visible to anyone. Make it a plain
   `def` (JWT-required, runs on the caller's own root), drop the `email`
   parameter from the tools, and read the caller's own record. See
   `jac guide jac-sv-auth`.
5. **"Let the agent issue a refund."** Add a second write tool beside
   `open_ticket`. Consider making it require confirmation before it fires —
   agents with write access to money need a human in the loop.
6. **"Show me what each tool call cost."** byLLM reports token usage; surface
   per-call tokens in the trace card next to each step so the ReAct loop's real
   price is visible.
7. **"Add tests that run in CI without an API key."** Use `MockLLM` from
   `jaclang.byllm.lib` to script tool-call sequences and assert the agent picks
   the right tools. See `jac guide jac-testing`.

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
