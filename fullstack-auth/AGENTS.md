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

**For this project specifically**, the guides that matter are:

- `jac guide jac-sv-auth` -- the canonical spec for `def:pub` / `def:priv` /
  `def:protect` / plain-`def` semantics and per-user roots. Read it before
  touching `services/notes.sv.jac`.
- `jac guide jac-sv-endpoints` -- endpoint shapes, the response envelope.
- `jac guide jac-sv-persistence` -- graph queries, relationships, view models.
- `jac guide jac-cl-auth` -- `jacLogin` / `jacSignup` / `jacLogout`, AuthGuard.
- `jac guide jac-cl-routing` -- file-based routing and the `(auth)/` group.
- `jac guide jac-shadcn-blocks` -- composition patterns for the UI.

## What this app is

A notes app behind a login. `services/notes.sv.jac` is the entire backend: two
nodes (`Profile`, `Note`), two view objects, and seven endpoints. Notes hang off
the signed-in user's `root` -- that is the whole persistence layer. There is no
database.

The rules that keep this template honest:

- **Never take a `user_id` parameter.** An authenticated function already runs
  on the caller's own `root`, so `[root -->][?:Note]` cannot return anyone
  else's notes. A `user_id` argument is both redundant and a hole -- it trusts
  the client. Look things up by walking the caller's root (see `toggle_note`).
- **Use `def:pub` ONLY for genuinely anonymous endpoints.** `:pub` is the one
  modifier that skips the JWT, and it changes *whose graph the code runs on* --
  an anonymous caller lands on the shared guest graph. Writing user data from a
  `:pub` endpoint is a silent cross-user leak, with no compile or runtime error.
  Everything user-specific stays `def:protect` (or plain `def` / `:priv`).
- **Keep the `app` shell in `main.jac`.** The `def:pub app(children)` shell
  is not dead code -- the client entry imports `app` from `main.js` and
  mounts every routed page inside it. Remove it and the bundle fails with "does
  not provide an export named 'app'" and the page renders blank.
- **Put new pages in the right route group.** `pages/(auth)/` is protected --
  everything inside is wrapped in an AuthGuard automatically by the group name.
  `pages/(public)/` is open. Groups add no URL segment. Do not hand-roll a guard
  inside a page, and do not put a `layout.jac` inside `(auth)/`.
- **Await every `sv import` call.** The stubs are async; a missing `await`
  assigns a Promise and the UI silently breaks. Mutations write, then refetch --
  rebind state to a fresh server response rather than mutating a list in place.

## Styling rules

- Semantic tokens only: `bg-background`, `text-foreground`,
  `text-muted-foreground`, `bg-card`, `bg-muted`, `bg-popover`, `bg-accent`,
  `border-border`, `text-primary`, `text-destructive`, and the `sidebar-*` set.
  Never a raw Tailwind color like `text-green-400`, never a hex value.
- There is deliberately **no light/dark toggle** -- the app ships a single
  theme. Nothing in the app sets a `.dark` class; don't add a switcher unless
  that is the feature you were asked for.
- Concatenate classes with `cn()` from `lib/utils.jac`, never with `+`.
  `cn` is not auto-injected -- import it: `import from "..lib.utils" { cn }`.
- Physical padding (`pt-4 pb-4`), not shorthand (`py-4`).
- This template has **no status ramp** (no `success` / `warning` / `info`
  tokens). If you need one, add it to `styles/global.css` as tokens under
  `:root` *and* register it in `@theme inline` -- never inline in a component.

## Import gotcha: shadcn files use underscores

The component files in `components/ui/` are written with **underscores**, so the
import path must match:

```jac
# GOOD -- matches components/ui/dropdown_menu.jac
import from ".ui.dropdown_menu" { DropdownMenu, DropdownMenuContent }

# BAD -- passes `jac check`, then fails at bundle time
import from ".ui.dropdown-menu" { DropdownMenu, DropdownMenuContent }
```

The hyphenated form type-checks clean and only blows up in the bundler with
"Failed to resolve import". `dropdown_menu` is the only multi-word primitive
here today, but the rule applies to any you add with `jac add --shadcn`.

## Try next

Concrete next steps. Each is a self-contained prompt you can hand to an agent.

1. **"Add password reset."** The runtime already exposes the endpoints --
   `/user/forgot-password` takes an `identity` and `/user/reset-password` takes
   the emailed token plus a new password. Add a `pages/(public)/forgot.jac`
   route and link it from `components/LoginPage.jac`. Read
   `jac guide jac-sv-auth` first; sending the mail needs an emailer configured.
2. **"Add a profile settings page."** `save_profile` and `my_profile` in
   `services/notes.sv.jac` already do the work -- `save_profile` upserts, so no
   new endpoint is needed. Add `pages/(auth)/settings.jac`, reuse the `Field` /
   `Input` pattern from `components/SignupPage.jac`, and add a nav item to
   `components/AppSidebar.jac`.
3. **"Add tags to notes and filter by them."** Put `has tags: list[str] = [];`
   on the `Note` node, carry it through `NoteView` and `to_view()`, and accept
   tags in `add_note`. Filter in `list_notes` with an optional parameter rather
   than filtering in the browser. Render them as `Badge` chips in
   `components/NoteList.jac`.
4. **"Add pagination to the notes list."** Give `list_notes` `limit` and
   `offset` parameters and return a count alongside the page -- the sort already
   happens server-side. Wire prev/next buttons into
   `components/DashboardPage.jac` and keep the page index in a `has` field.
5. **"Let me edit a note's title inline."** Add a `def:protect
   edit_note(note_id: str, title: str) -> NoteView | None` that walks the
   caller's own root exactly like `toggle_note` does, then make the title in
   `components/NoteList.jac` swap to an `Input` on double-click.
6. **"Add a search box over my notes."** Add a `search_notes(q: str)` endpoint
   that filters `[root -->][?:Note]` server-side, and debounce the input in
   `components/DashboardPage.jac` so you are not calling it per keystroke.
   See `jac guide jac-cl-js-interop` for the debounce recipe.
7. **"Let users share a note publicly by link."** This is the interesting one --
   it needs a permission grant, not a `:pub` endpoint that reads the graph. Read
   `jac guide jac-sv-multi-user` for `ReadPerm` and the shared-root pattern
   before writing anything.

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
