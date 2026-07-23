"""Hero section: headline, supporting copy, and the two primary calls to action."""

import from ".ui.button" { Button }
import from ".ui.badge" { Badge }
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { ArrowRight01Icon, PlayIcon }

glob _stats: list[dict[str, str]] = [
    {"value": "40s", "label": "Median deploy"},
    {"value": "12k+", "label": "Teams shipping"},
    {"value": "99.99%", "label": "Uptime"}
];

def:pub Hero() -> JsxElement {
    return
        <section className="relative overflow-hidden pt-24 pb-24 sm:pt-32 sm:pb-32">
            <div
                aria-hidden="true"
                className="pointer-events-none absolute -top-40 left-1/2 size-[36rem] -translate-x-1/2 rounded-full bg-primary/10 blur-3xl"
            />

            <div className="relative mx-auto max-w-7xl pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
                <div className="mx-auto max-w-3xl text-center">
                    <Badge variant="outline" className="mb-4">Now in public beta</Badge>

                    <h1 className="text-balance text-4xl font-bold tracking-tight sm:text-5xl lg:text-6xl">
                        Ship software at full speed
                    </h1>

                    <p className="mx-auto mt-6 max-w-2xl text-balance text-lg leading-8 text-muted-foreground">
                        Slipstream turns every pull request into a live preview, runs your test
                        suite in parallel, and deploys to the edge the moment you merge.
                    </p>

                    <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
                        <Button size="lg" className="h-11 w-full px-6 sm:w-auto">
                            Start free
                            <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} />
                        </Button>
                        <Button size="lg" variant="outline" className="h-11 w-full px-6 sm:w-auto">
                            <HugeiconsIcon icon={PlayIcon} strokeWidth={2} />
                            Watch the demo
                        </Button>
                    </div>

                    <p className="mt-6 text-sm text-muted-foreground">
                        No credit card required. Free forever for solo developers.
                    </p>
                </div>

                <div className="mx-auto mt-16 grid max-w-2xl grid-cols-1 gap-8 sm:grid-cols-3">
                    {for stat in _stats {
                        <div key={stat["label"]} className="text-center">
                            <div className="text-3xl font-semibold tabular-nums">{stat["value"]}</div>
                            <div className="mt-1 text-sm text-muted-foreground">{stat["label"]}</div>
                        </div>
                    }}
                </div>
            </div>
        </section>;
}
