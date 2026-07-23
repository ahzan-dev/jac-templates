# jac-templates

Starter templates for [Jac](https://www.jac-lang.org/) full-stack apps, written
in the **markerless** style (jaclang ≥ 0.34): codespace placement is inferred —
JSX and npm string imports seed client code, plain imports stay on the server —
so there are no `cl { }` blocks or `.cl.jac` suffixes except where a pin is
genuinely load-bearing. Server boundaries (`sv import`, `.sv.jac` service
modules) are always explicit; inference never guesses those.

## Templates

| Template | What it shows |
|---|---|
| [`empty`](empty/) | Minimal shell — the build splash the preview shows before an app exists |
| [`landing`](landing/) | Static marketing page: hero, features, pricing, FAQ, CTA (jac-shadcn) |
| [`fullstack-auth`](fullstack-auth/) | File-based `pages/` routing, `(auth)` route groups, JWT auth, notes CRUD |
| [`social`](social/) | Graph-native social app: follows are edges, the feed is a walker |
| [`ai-triage`](ai-triage/) | Structured extraction with `by llm()` — typed enums/objects from raw text |
| [`support-agent`](support-agent/) | Multi-tool ReAct agent with `by llm(tools=[...])` |

## Run one

```sh
cd social         # or any template
jac start
```

The AI templates (`ai-triage`, `support-agent`) need a model key, e.g.
`export OPENAI_API_KEY=...` or `export ANTHROPIC_API_KEY=...` before `jac start`.

Each template has its own `README.md` (the tour) and `AGENTS.md` (conventions
for coding agents working in that codebase).
