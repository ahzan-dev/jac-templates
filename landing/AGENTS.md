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

**For this project specifically, read `jac guide jac-shadcn-blocks` before
adding or restyling a section.** It carries the spacing scale, type scale, and
structural skeletons this page is built from. Then:

- `jac guide jac-shadcn-components` -- the primitives in `components/ui/`,
  their import paths, and `jac add --shadcn <name>` to fetch more.
- `jac guide jac-cl-components` -- the shape of a `.jac` file: `def:pub`,
  `has` state, props, event handlers, JSX.
- `jac guide jac-cl-styling` -- tokens, `cn()`, and the Tailwind conventions.

## What this app is

A client-only marketing page. `main.jac` is a `cl { }` block that stacks seven
section components:

```jac
<Navbar />
<Hero /> <Features /> <Pricing /> <Faq /> <CallToAction />
<Footer />
```

There is no server: no walkers, no nodes, no `sv import`. The rules that keep
this template honest:

- **One section per file, one `def:pub` per section.** Sections take no props
  and own their own content. Adding a section means a new
  `components/<name>.jac`, a `cl import` in `main.jac`, and one line in the
  JSX.
- **Content is a `glob` list, not markup.** Cards, tiers, FAQ entries, and
  footer columns are module-level `glob` lists rendered by a `for` loop. Put new
  copy in the list; do not hand-write a seventh `<Card>`.
- **Keep it stateless.** `components/navbar.jac` has the page's only `has`
  (the mobile menu toggle). Reach for state only when an interaction genuinely
  needs it.
- **`kind = "web-app"` in `jac.toml` is deliberate** even with no backend — see
  the note in `README.md`. Do not "correct" it to `web-static`; `jac start
  --dev` renders a blank page for web-static projects, and the JacBuilder
  preview always passes `--dev`.
- **Don't add a backend by accident.** If a section needs to persist something
  (a waitlist, a contact form), that is a real server module and a deliberate
  step up — read `jac guide jac-fullstack-patterns` first.

## Styling rules

- Semantic tokens only: `bg-background`, `text-foreground`,
  `text-muted-foreground`, `bg-card`, `border-border`, `text-primary`,
  `text-primary-foreground`, `bg-primary/10`. Never a raw Tailwind color like
  `text-violet-500`, never a hex value.
- Single theme. `styles/global.css` ships a `.dark` block from the scaffold, but
  nothing toggles the class. There is deliberately no light/dark switch.
- Concatenate classes with `cn()` from `lib/utils.jac`, never with `+`.
- Physical padding (`pt-4 pb-4`, `pl-4 pr-4`), not shorthand (`py-4`, `px-4`).
- Icons go through the HugeIcons wrapper:
  `<HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-4" />`.
- New tokens go in `styles/global.css` as tokens (`:root` + `@theme inline`),
  not inline in a component. Note that `global.css` is generated from the
  `[jac-shadcn]` block in `jac.toml` — change the accent with
  `jac retheme --theme <name>`, not by editing color variables by hand.

## Try next

Concrete next steps. Each is a self-contained prompt you can hand to an agent.

1. **"Add a testimonials section."** New `components/testimonials.jac`: a
   `glob _quotes` list of `{quote, name, role, company}` rendered as a
   three-column `Card` grid, matching `features.jac`. Run
   `jac add --shadcn avatar` for the headshots, then import it in `main.jac`
   between `<Features />` and `<Pricing />`.
2. **"Make pricing toggle between monthly and yearly."** Add `has yearly: bool
   = False;` to `Pricing` and a second price to each entry in `_tiers`
   (`"price_yearly": "$19"`). Run `jac add --shadcn switch`, put the toggle
   under the section heading, and show a "2 months free" `Badge` when yearly is
   on. Keep Enterprise reading "Custom" either way.
3. **"Add a logo cloud under the hero."** A short strip of customer logos with a
   `text-sm text-muted-foreground` eyebrow like "Trusted by teams at". Render
   from a `glob` list, grayscale by default, and keep it inside `hero.jac`
   below the stats grid rather than making it a new section.
4. **"Add a sticky mobile nav drawer."** Replace the inline `{if mobileOpen}`
   block in `navbar.jac` with a proper slide-in panel: `jac add --shadcn
   sheet`, drive it from the existing `mobileOpen` state, and keep
   `close_mobile` wired to every link so the drawer shuts on navigate.
5. **"Add a waitlist email form to the CTA band."** Put an `Input` and the
   existing `Start free` `Button` side by side in `cta.jac`
   (`jac add --shadcn input`), with `has email: str = "";` and client-side
   validation plus a success state. Note this is where the template stops being
   backend-free
   — to actually store the address you need a server module; read
   `jac guide jac-fullstack-patterns`.
6. **"Add a feature comparison table below pricing."** A row per capability, a
   column per tier, checkmarks via `CheckmarkCircle02Icon` from
   `@hugeicons/core-free-icons`. Run `jac add --shadcn table`. Build it inside
   `pricing.jac` so it reads the existing `_tiers` glob directly and the two
   can't drift apart — `_tiers` is module-local, so don't try to import it from
   a new file.
7. **"Rebrand the whole page to a different accent color."** Run
   `jac retheme --theme rose` to regenerate `styles/global.css` from
   `[jac-shadcn]` in `jac.toml`, then confirm nothing broke — because every
   component uses `text-primary` / `bg-primary` rather than a literal color, no
   `.jac` file should need to change. If one does, that file has a hardcoded
   color worth fixing.

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
