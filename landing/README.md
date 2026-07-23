# Landing

A SaaS marketing page for a product that doesn't exist. Seven sections, zero backend.

A client-only Jac app that demonstrates **jac-shadcn blocks** — you compose a
landing page out of section components and ship it in an afternoon, because
there is no server to write.

## What this demonstrates

This is the entire app. It lives in [`main.jac`](main.jac):

```jac
cl {
    def:pub app() -> JsxElement {
        return
            <div className="min-h-screen bg-background text-foreground">
                <Navbar />
                <main>
                    <Hero />
                    <Features />
                    <Pricing />
                    <Faq />
                    <CallToAction />
                </main>
                <Footer />
            </div>;
    }
}
```

The composition root reads as a list of sections. That is the point.

Three things are worth staring at:

1. **No backend.** Search this repo for a `walker`, a `node`, or a server
   module; there isn't one. `main.jac` holds a single `cl { }` block and seven
   `cl import`s — every line of code in this project is client code, and it all
   ends up in the browser bundle.
2. **Sections are self-contained.** Each file in `components/` exports one
   `def:pub` component that takes no props, owns its own content as a
   module-level `glob`, and renders itself. Reordering the page is reordering
   the list above. Deleting a section is deleting a line and its import.
3. **Content is data, not markup.** The six feature cards are one `glob` list
   and one `for` loop:

   ```jac
   glob _features: list[dict[str, any]] = [
       {"icon": GitBranchIcon, "title": "Preview every branch", "description": "..."},
       ...
   ];
   ```

   Editing copy means editing a list. You never touch JSX to change words.

The only stateful component is [`components/navbar.jac`](components/navbar.jac),
which uses a single `has mobileOpen: bool = False;` for the mobile menu — that
is the whole client state budget for the page.

## Run it

```bash
jac install
jac start --dev
```

Open <http://localhost:8000>.

> **Note:** [`jac.toml`](jac.toml) says `kind = "web-app"` even though this app
> has no server code. That is deliberate — leave it. `web-static` is the
> architecturally correct kind, but `jac start --dev` on a web-static project
> proxies `/static/client.js` to a backend that isn't there, gets
> `ECONNREFUSED`, and renders a blank page. The JacBuilder preview pipeline
> always passes `--dev`, so a web-static landing page would never preview.
> `web-app` costs nothing here — there is still zero server code — and it works
> everywhere.

## Layout

```
main.jac                      entry: cl { } composition root, imports every section
jac.toml                      project kind, [jac-shadcn] theme, npm deps
components/navbar.jac      sticky header, nav links, mobile menu (the only stateful component)
components/hero.jac        headline, two CTAs, three-stat strip
components/features.jac    six capability cards from a glob list
components/pricing.jac     three tiers, middle one highlighted via `popular`
components/faq.jac         six questions in a single-open Accordion
components/cta.jac         closing band on a primary-background Card
components/footer.jac      brand blurb, four link columns, legal line
components/ui/                jac-shadcn primitives (yours to edit)
lib/utils.jac              cn() -- clsx + tailwind-merge
styles/global.css             theme tokens, generated from [jac-shadcn]
```

## Styling

- **Semantic tokens only**: `bg-background`, `text-muted-foreground`, `bg-card`,
  `border-border`, `text-primary`, `text-primary-foreground`. Never a raw
  Tailwind color like `text-violet-500`, never a hex value. Opacity variants
  work — `bg-primary/10` is how the hero glow and the feature icon chips are
  tinted.
- **Single theme.** `styles/global.css` carries both a `:root` and a `.dark`
  block because that is what the scaffold generates, but nothing in this app
  toggles the `dark` class. The page ships one look. There is deliberately no
  light/dark switch.
- **`cn()`, never `+`.** Import it from `lib/utils.jac`. See the conditional
  tier styling in `components/pricing.jac` for the pattern:

  ```jac
  className={cn(
      "relative flex flex-col",
      "border-primary shadow-lg ring-1 ring-primary" if tier["popular"] else "shadow-sm"
  )}
  ```

- **Physical padding** (`pt-4 pb-4`, `pl-4 pr-4`), not shorthand (`py-4`,
  `px-4`). Every section in this repo follows it.
- **Icons** are HugeIcons, always through the wrapper:
  `<HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-4" />`.
- **Retheming is config, not CSS.** `global.css` is generated from the
  `[jac-shadcn]` block in `jac.toml`. To change the accent, run
  `jac retheme --theme rose` rather than hand-editing color variables — a later
  `jac retheme` regenerates the file. Tokens you add yourself still go in
  `global.css` under `:root` + `@theme inline`; just know they live alongside
  generated output.

## Extending it

See [`AGENTS.md`](AGENTS.md) — it has a **Try next** list of concrete prompts,
plus how to reach the Jac reference guides bundled with the compiler
(`jac guide jac-shadcn-blocks` is the one that matters here).
