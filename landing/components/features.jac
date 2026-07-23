"""Features section: a responsive grid of product capability cards."""

import from ".ui.badge" { Badge }
import from ".ui.card" { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    GitBranchIcon,
    FlashIcon,
    ArrowTurnBackwardIcon,
    Globe02Icon,
    ChartLineData01Icon,
    UserGroup02Icon
}

glob _features: list[dict[str, any]] = [
    {
        "icon": GitBranchIcon,
        "title": "Preview every branch",
        "description": "Each pull request gets an isolated URL with real data, seeded and torn down automatically."
    },
    {
        "icon": FlashIcon,
        "title": "Parallel pipelines",
        "description": "Tests fan out across hundreds of workers, so your suite finishes in seconds instead of coffee breaks."
    },
    {
        "icon": ArrowTurnBackwardIcon,
        "title": "Instant rollback",
        "description": "Every deploy is immutable. Roll back to any previous release in one click, with zero downtime."
    },
    {
        "icon": Globe02Icon,
        "title": "Edge by default",
        "description": "Ship to 40 regions on merge. Requests resolve close to your users without extra configuration."
    },
    {
        "icon": ChartLineData01Icon,
        "title": "Insight built in",
        "description": "Logs, traces, and release health arrive pre-wired. Spot a regression before your users file it."
    },
    {
        "icon": UserGroup02Icon,
        "title": "Made for teams",
        "description": "Granular roles, protected environments, and an audit trail your security review will actually pass."
    }
];

def:pub Features() -> JsxElement {
    return
        <section id="features" className="pt-16 pb-16 sm:pt-24 sm:pb-24">
            <div className="mx-auto max-w-7xl pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
                <div className="mx-auto max-w-2xl text-center">
                    <Badge variant="outline" className="mb-4">Features</Badge>
                    <h2 className="text-balance text-3xl font-bold tracking-tight sm:text-4xl">
                        Everything between commit and production
                    </h2>
                    <p className="mt-4 text-balance text-lg text-muted-foreground">
                        One platform for previews, tests, and releases. No glue scripts to maintain.
                    </p>
                </div>

                <div className="mx-auto mt-16 grid max-w-6xl grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
                    {for feature in _features {
                        <Card
                            key={feature["title"]}
                            className="shadow-sm transition-shadow hover:shadow-md"
                        >
                            <CardHeader>
                                <span className="mb-2 flex size-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
                                    <HugeiconsIcon icon={feature["icon"]} strokeWidth={2} className="size-5" />
                                </span>
                                <CardTitle className="text-lg font-semibold">{feature["title"]}</CardTitle>
                                <CardDescription className="text-base leading-relaxed">
                                    {feature["description"]}
                                </CardDescription>
                            </CardHeader>
                        </Card>
                    }}
                </div>
            </div>
        </section>;
}
