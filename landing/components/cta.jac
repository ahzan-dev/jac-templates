"""Closing call-to-action band on a primary background."""

import from ".ui.button" { Button }
import from ".ui.card" { Card }
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { ArrowRight01Icon }

def:pub CallToAction() -> JsxElement {
    return
        <section className="pt-16 pb-16 sm:pt-24 sm:pb-24">
            <div className="mx-auto max-w-7xl pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
                <Card className="overflow-hidden border-transparent bg-primary text-primary-foreground">
                    <div className="grid gap-8 pt-12 pb-12 pl-8 pr-8 sm:pt-16 sm:pb-16 lg:grid-cols-[1fr_auto] lg:items-center">
                        <div>
                            <h2 className="text-balance text-3xl font-bold tracking-tight sm:text-4xl">
                                Ready to ship faster?
                            </h2>
                            <p className="mt-4 max-w-xl text-lg leading-8 opacity-90">
                                Connect a repository and watch your first preview go live in under a minute.
                            </p>
                        </div>

                        <div className="flex flex-col gap-3 sm:flex-row lg:shrink-0">
                            <Button size="lg" variant="secondary" className="h-11 px-6">
                                Start free
                                <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} />
                            </Button>
                            <Button
                                size="lg"
                                variant="outline"
                                className="h-11 border-primary-foreground/20 bg-transparent px-6 text-primary-foreground hover:bg-primary-foreground/10 hover:text-primary-foreground"
                            >
                                Talk to sales
                            </Button>
                        </div>
                    </div>
                </Card>
            </div>
        </section>;
}
