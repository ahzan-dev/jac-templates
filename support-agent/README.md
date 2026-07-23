# Support Agent

Ask a support desk a question. Watch the model decide which of six tools it needs.

## What this demonstrates

The sibling [`ai-triage`](../ai-triage) template demos `by llm()` for **one-shot
typed extraction**: one call in, one typed object out. This template demos the
thing that does not: **the agent loop** — the model choosing among tools,
calling them, reading what came back, and choosing again.

This is the whole agent. It lives in [`services/support.jac`](services/support.jac):

```jac
def ask(question: str) -> str by llm(
    tools=[search_docs, get_customer, get_tier_limits, get_billing, get_projects, open_ticket],
    temperature=0.2,
    max_react_iterations=6
);
```

Four things are worth staring at:

1. **There is no loop to write.** Passing `tools=[...]` turns the ReAct loop on.
   There is no `method="ReAct"` to set, no `while` over tool calls, no
   dispatch table matching a tool name back to a function, no message history to
   thread. The tools are ordinary `def`s with ordinary bodies — the model reads
   them, picks, and calls.

2. **`sem` is the only steering text in the project.** There is no prompt
   template assembled at runtime; search the repo for one. There is one `sem`
   statement attached to the `ask` declaration (shown truncated here — it is a
   single unbroken string in the source):

   ```jac
   sem ask = "You are the support agent for a web application-building platform,
   answering a support operator's question. Call only the tools the question actually
   needs, then stop. A general question about how the platform works, naming no
   customer, is answered from search_docs alone -- do not look anyone up. ... A question
   about whether a specific person is ALLOWED to do something needs two calls in that
   order: get_customer to learn which plan they are on, then get_tier_limits on that
   plan name to learn what it permits -- the plan name alone never tells you the
   limits ... Never invent a limit, price, date or status: if no tool told you, say
   you do not know.";
   ```

   Every tool and every tool parameter carries its own `sem` too — that is how
   the model knows what a tool is for and when to reach for it. No sem, no tool
   use. **To change the agent's judgement, you edit the `sem`.** Not a string
   concat, not a config file.

3. **The tool trace is the tools reporting themselves.** Each of the six tools
   calls `_trace(tool, args, result)`, which appends a `ToolCall` to a
   module-level `glob _TRACE`. `ask_support` clears `_TRACE`, runs `ask()`, and
   returns the answer *and* `list(_TRACE)` on its `Answer` object;
   [`components/TraceCard.jac`](components/TraceCard.jac) renders one step
   per call, in order, with the argument the model picked and what came back.
   Nothing about the trace is scripted — it is a record of decisions. (A `glob`
   is honest at demo scale: one operator, one question at a time. Concurrent
   questions would interleave into the same list.)

4. **Data lives on `root` — no database to set up.** Customers, projects,
   payments, deployments and tickets are nodes hanging off `root`, connected by
   typed edges (`Owns`, `Billed`, `Deployed`, `Raised`). `_ensure_seed` creates
   them on the first question and is idempotent. The tools traverse the graph
   (`[c ->:Billed:->]`) instead of querying a table. You still get real
   persistence — Jac stores the graph for you (SQLite in `.jac/data/` by
   default, MongoDB via `MONGODB_URI`); you just never write a schema, a
   migration or an ORM mapping. See `jac guide jac-sv-persistence`.

## Watch it choose

Three real runs. The point of each is *which tools were not called*.

**One tool.** `"What is a preview?"`

```
search_docs   query=preview     -> 3 section(s) from platform.md, troubleshooting.md
```

Six tools available, one called. The agent decided the other five were
irrelevant: nobody is named, so there is nobody to look up. **Restraint is the
proof of reasoning.** A hardcoded pipeline would have called all six, or a fixed
subset; this one made a judgement about the question.

**Two tools, chained.** `"Why can't maya@northwind.dev deploy her project?"`

```
get_customer      email=maya@northwind.dev  -> Maya Okonjo, free tier
get_tier_limits   tier=free                 -> 3 projects, 0 deploys
```

> "Maya Okonjo is on the free plan, which does not allow any live deployments.
> The free plan permits only sandbox deployments…"

**The chain is genuinely necessary, not theatre.** The plan *name* never tells
you the limits — `get_customer` returns `"free"` and nothing else, and the
knowledge base deliberately does not list the numbers (`knowledge/billing.md`:
*"The exact numbers differ per plan and are not listed in this document"*). The
only place `deploy_count: 0` exists is `TIER_LIMITS`, behind `get_tier_limits`.
So the model has to learn the plan, then look the plan up. The output of call
one is the input to call two. That is the loop doing work no single call could.

**A different tool entirely.** `"Did raf@studioloop.io's last payment go through?"`

```
get_billing   email=raf@studioloop.io  -> 3 payment(s), latest failed
```

The answer names the failed July 14 charge and invoice INV-3944. Note it did
*not* call `get_customer` first — a billing question does not need a plan
lookup, and the agent knows that from the `sem`.

## The six tools

Every tool is a plain `def`, one job each, returning a **readable string** —
prose the model can reason over, not a dict it has to decode.

| Tool | What it does | Reads / writes |
| --- | --- | --- |
| `search_docs(query)` | Keyword-searches `knowledge/*.md`, returns the top 3 matching `## ` sections verbatim | reads — files on disk |
| `get_customer(email)` | Who they are, which plan, when they joined | reads — graph |
| `get_tier_limits(tier)` | What `free` / `builder` / `pro` actually permit, as real numbers | reads — the `TIER_LIMITS` table |
| `get_billing(email)` | Full payment history, oldest first: date, amount, status, invoice | reads — graph |
| `get_projects(email)` | Their projects and each one's deployment state | reads — graph |
| `open_ticket(email, summary)` | Creates a `Ticket` node, returns a `TCK-####` reference | **writes — the only one** |

`open_ticket` is the only tool that mutates anything, and its `sem` says so
plainly: use it only when a ticket is asked for or a human is genuinely
required, never for a question already answered. `TraceCard` colors it
differently so a write is never mistaken for a read at a glance.

## The knowledge base

`search_docs` reads [`knowledge/`](knowledge/) off disk **at question time** —
three markdown files (`platform.md`, `billing.md`, `troubleshooting.md`), split
on `## ` headings, scored by keyword overlap, top 3 sections returned verbatim.

**This is the main fork point.** Delete those three files, drop in your own
product's docs, and you have an agent that answers from *your* documentation —
the tools, the `sem`, and the agent declaration are all unchanged. No reindex
step, no build, no restart for content: edit a `.md` and the next question sees
it.

Be clear about what the retrieval is, though: **it is keyword matching, not
embeddings.** `_keywords` strips stopwords, `_score` counts substring hits, the
top 3 win. That is deliberate — it is ~40 lines, has zero dependencies, needs no
vector store, no embedding API key and no index to keep warm, and it is legible
enough that you can predict what it will return. The cost is real: it will miss
a paraphrase that shares no words with the docs. Ask about "the site won't come
up" and it finds nothing where "deployment failed" would have hit. The tool
handles that honestly rather than hallucinating —

```jac
return "The documentation has no section matching that. Do not guess an answer.";
```

— but a miss is still a miss. Swapping in real vector search is the natural
next step, and it is a change to `_search_knowledge` alone.

## Run it

```bash
jac install
export OPENAI_API_KEY=sk-...
jac start --dev
```

Open <http://localhost:8000>.

byLLM is built into jaclang core — there is nothing to `pip install`.

The model is configured once in [`jac.toml`](jac.toml), and **nowhere else**:

```toml
[byllm.model]
default_model = "${LLM_MODEL:-gpt-4o-mini}"
api_key = "${OPENAI_API_KEY:-}"
```

Switching providers is a one-line change to `default_model` — the Jac source
never moves:

| `default_model` | Env var |
| --- | --- |
| `gpt-4o-mini` *(default)*, `gpt-4o` | `OPENAI_API_KEY` |
| `claude-sonnet-4-6` | `ANTHROPIC_API_KEY` |
| `gemini/gemini-2.0-flash` | `GOOGLE_API_KEY` |

If the key is missing the app doesn't crash — `ask_support` catches
`AuthenticationError` and the UI tells you what to set.

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

Honest warning, and it matters more here than in `ai-triage`: **a small local
model picks and chains tools noticeably worse than `gpt-4o-mini`.** Tool
selection is the hard part for small models. Expect it to skip the second call
in a chain — answering "Maya is on the free plan" and stopping, without ever
calling `get_tier_limits` to find out what free allows. Filling one typed object
is a much easier job than deciding, six times, which of six tools to reach for.
The code is byte-for-byte identical either way, which is the point — but if you
want to see the loop reason well, use a hosted model.

## No auth — read this before you ship it

This is a demo desk, not a real one. `ask_support` is a `def:pub`, which means
**no login**: anyone who opens the page can ask about any customer and read
their plan, their projects and their payment history. There is no `Customer` ↔
user binding, no ownership check in any tool, and `list_customers` hands the
whole roster to the browser.

That is deliberate. The lesson here is tool use, and auth would be noise around
it. But it is **not shippable as-is** — bolt this onto real customer data and you
have published it.

When you want the real thing:

- `jac guide jac-sv-auth` — the server-side auth model, and what `def:pub` vs
  `def:priv` vs a plain `def` actually mean for who can call what.
- The sibling [`fullstack-auth`](../fullstack-auth) template — a working
  login/signup loop with per-user data, to copy from.

The shape of the fix: drop `:pub` from `ask_support`, hang customers off the
authenticated user's root instead of the global `root`, and make each tool scope
to the caller rather than searching every `Customer` on the graph.

The seed data is fictional. Maya Okonjo, Rafael Ortiz, Jin Park, Dana Whitfield
and Sam Ellery are invented, and so are their invoices, cards and deployments.

## Layout

```
main.jac                        entry: server import (registers the endpoint) + client mount
jac.toml                        model config ([byllm.model]) + theme
services/support.jac            the whole payload: graph, six tools, sem, `by llm(tools=[...])`
knowledge/platform.md           what previews, projects and deployments are
knowledge/billing.md            plans, credits, payments -- deliberately no numbers
knowledge/troubleshooting.md    symptom -> cause sections
components/SupportDesk.jac   the screen: input, presets, roster, layout
components/TraceCard.jac     the trace -- one step per tool call, writes flagged
components/SourceCard.jac    the agent's source, on screen next to the agent
components/ui/                  jac-shadcn primitives (yours to edit)
lib/utils.jac                cn() -- class merging
styles/global.css               semantic tokens incl. the status ramp
```

The five preset buttons in `SupportDesk.jac` each take a different path
through the loop — docs only, two chained, billing, projects, and the write.
Each one's `hint` is what to watch for in the trace.

## Extending it

See [`AGENTS.md`](AGENTS.md) for how to reach the Jac reference guides bundled
with the compiler. **`jac guide jac-by-llm` is the one that matters here** — it
is the authoritative spec for `by llm()`, `sem` wiring, tools and the ReAct
loop. Read it before touching `services/support.jac`.

A few directions worth taking:

1. **Point it at your own docs.** Replace `knowledge/*.md`. Change nothing else.
2. **Add a seventh tool.** A plain `def` returning a readable string, a `sem` on
   the function and one on every parameter, a `_trace(...)` call in the body,
   and its name in the `tools=[...]` list. That is the entire contract.
3. **Swap keyword search for embeddings.** `_search_knowledge` is the only
   function that changes; `search_docs` keeps its signature and its `sem`.
4. **Tighten the judgement.** Edit `sem ask`, ask the same question, and watch
   the trace change. This is the fastest loop in the project.
5. **Give it auth.** See the section above — and then the tools become per-user
   instead of per-desk.
