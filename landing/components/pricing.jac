"""Pricing section: three tiers with the middle tier highlighted."""

import from ".ui.badge" { Badge }
import from ".ui.button" { Button }
import from ".ui.card" {
    Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter
}
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { CheckmarkCircle02Icon }

glob _tiers: list[dict[str, any]] = [
    {
        "name": "Starter",
        "price": "$0",
        "period": "forever",
        "description": "For solo developers and side projects.",
        "cta": "Start free",
        "popular": False,
        "features": [
            "1 project, unlimited deploys",
            "Preview URLs on every branch",
            "500 build minutes per month",
            "Community support"
        ]
    },
    {
        "name": "Team",
        "price": "$24",
        "period": "per user / month",
        "description": "For teams that ship every single day.",
        "cta": "Start 14-day trial",
        "popular": True,
        "features": [
            "Unlimited projects and members",
            "Parallel pipelines, 10k build minutes",
            "Protected environments and approvals",
            "Release health and tracing",
            "Priority support with a 4-hour SLA"
        ]
    },
    {
        "name": "Enterprise",
        "price": "Custom",
        "period": "annual contract",
        "description": "For organisations with scale and compliance needs.",
        "cta": "Talk to sales",
        "popular": False,
        "features": [
            "Everything in Team",
            "SSO, SCIM, and audit exports",
            "Dedicated regions and private networking",
            "SOC 2 and HIPAA reporting",
            "Named solutions engineer"
        ]
    }
];

def:pub Pricing() -> JsxElement {
    return
        <section id="pricing" className="pt-16 pb-16 sm:pt-24 sm:pb-24">
            <div className="mx-auto max-w-7xl pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
                <div className="mx-auto max-w-2xl text-center">
                    <Badge variant="outline" className="mb-4">Pricing</Badge>
                    <h2 className="text-balance text-3xl font-bold tracking-tight sm:text-4xl">
                        Simple pricing that scales with you
                    </h2>
                    <p className="mt-4 text-balance text-lg text-muted-foreground">
                        Start free. Upgrade when your team outgrows it. Cancel any time.
                    </p>
                </div>

                <div className="mx-auto mt-12 grid max-w-5xl grid-cols-1 gap-6 lg:grid-cols-3">
                    {for tier in _tiers {
                        <Card
                            key={tier["name"]}
                            className={cn(
                                "relative flex flex-col",
                                "border-primary shadow-lg ring-1 ring-primary" if tier["popular"] else "shadow-sm"
                            )}
                        >
                            {if tier["popular"] {
                                <Badge className="absolute -top-3 left-1/2 -translate-x-1/2">Most popular</Badge>
                            }}

                            <CardHeader>
                                <CardTitle className="text-lg font-semibold">{tier["name"]}</CardTitle>
                                <CardDescription>{tier["description"]}</CardDescription>
                                <div className="mt-4 flex items-baseline gap-1.5">
                                    <span className="text-4xl font-bold tracking-tight tabular-nums">
                                        {tier["price"]}
                                    </span>
                                    <span className="text-sm text-muted-foreground">{tier["period"]}</span>
                                </div>
                            </CardHeader>

                            <CardContent className="flex-1">
                                <ul className="flex flex-col gap-3">
                                    {for item in tier["features"] {
                                        <li key={item} className="flex items-start gap-2.5">
                                            <HugeiconsIcon
                                                icon={CheckmarkCircle02Icon}
                                                strokeWidth={2}
                                                className="mt-0.5 size-4 shrink-0 text-primary"
                                            />
                                            <span className="text-sm text-muted-foreground">{item}</span>
                                        </li>
                                    }}
                                </ul>
                            </CardContent>

                            <CardFooter>
                                <Button
                                    className="w-full"
                                    variant={"default" if tier["popular"] else "outline"}
                                >
                                    {tier["cta"]}
                                </Button>
                            </CardFooter>
                        </Card>
                    }}
                </div>
            </div>
        </section>;
}
