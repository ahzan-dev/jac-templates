"""The one screen: paste messy text on the left, read the typed result, and see
the source that did it on the right."""

import from ..components.ui.button { Button }
import from ..components.ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }
import from ..components.ui.textarea { Textarea }
import from ..components.ui.badge { Badge }
import from ..components.ui.alert { Alert, AlertTitle, AlertDescription }
import from ..components.ui.skeleton { Skeleton }
import from ..components.TicketCard { TicketCard }
import from ..components.SourceCard { SourceCard }
import from ..lib.utils { cn }

sv import from ..services.triage { triage_ticket, Ticket }

glob _SAMPLES: list[dict] = [
    {
        "label": "Double charge",
        "text": "hey so i tried to upgrade to the team plan this morning on my phone and the payment page just spun forever, then i got charged TWICE?? 199 x2 on my amex. i have a demo with a client tomorrow and my team still cant log in. please fix this"
    },
    {
        "label": "Dark mode nit",
        "text": "not a big deal at all but the little checkmark icon in the settings sidebar is basically invisible in dark mode, looks like it's dark grey on dark grey. everything else looks great btw, loving the new release :)"
    },
    {
        "label": "CSV export",
        "text": "morning! quick one - when i export my report to csv the dates all come out as 45231 etc instead of actual dates. excel thing maybe? i can work around it by reformatting the column each time but its getting old doing it every monday"
    }
];

"""One sample-text chip. A component (rather than an inline lambda in the loop)
so each chip closes over its own `text` through a typed callback prop."""
def:pub SampleChip(label: str, text: str, onPick: Callable[[str], None]) -> JsxElement {
    def handle -> None { onPick(text); }
    return <button
        type="button"
        onClick={handle}
        className={cn(
            "rounded-4xl border border-border pt-1 pb-1 pl-3 pr-3 text-xs font-medium",
            "text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
        )}
    >{label}</button>;
}

def:pub TriageStudio() -> JsxElement {
    has raw: str = "";
    has ticket: Ticket | None = None;
    has errorMsg: str = "";
    has busy: bool = False;

    async def runTriage -> None {
        if busy { return; }
        busy = True;
        errorMsg = "";
        ticket = None;
        try {
            # One positional arg. The result is a hydrated TriageResult --
            # nothing is parsed on this side.
            res = await triage_ticket(raw);
            if res and res.ok {
                ticket = res.ticket;
            } else {
                errorMsg = (res.error if res else "") or "The model call failed.";
            }
        } except Exception as e {
            errorMsg = f"Could not reach the server: {e}";
        }
        busy = False;
    }

    def onEdit(e: ChangeEvent) { raw = e.target.value; }

    def onClear -> None {
        raw = "";
        ticket = None;
        errorMsg = "";
    }

    def onPickSample(text: str) -> None {
        raw = text;
        ticket = None;
        errorMsg = "";
    }

    return <div className="min-h-screen bg-background text-foreground">
        <div className="mx-auto max-w-7xl pt-12 pb-16 pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">

            <header className="mx-auto max-w-3xl text-center">
                <Badge variant="outline" className="mb-4 font-mono">by llm()</Badge>
                <h1 className="text-balance text-4xl font-bold tracking-tight sm:text-5xl">
                    Messy text in. Typed object out.
                </h1>
                <p className="mt-4 text-balance text-lg leading-8 text-muted-foreground">
                    Paste a real support message. A Jac function whose body is just
                    {" "}<code className="font-mono text-foreground">by llm()</code> returns a
                    {" "}<code className="font-mono text-foreground">Ticket</code> — title, priority
                    {" "}enum, tags — with no prompt string and no JSON parsing anywhere.
                </p>
            </header>

            <div className="mt-12 grid grid-cols-1 gap-6 lg:grid-cols-2 lg:items-start">

                <div className="flex flex-col gap-6">
                    <Card>
                        <CardHeader>
                            <CardTitle className="text-lg font-semibold">Raw customer message</CardTitle>
                            <CardDescription>
                                Typos and rambling welcome — that is the point.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="flex flex-col gap-4">
                            <Textarea
                                value={raw}
                                onChange={onEdit}
                                rows={8}
                                placeholder="hey so i tried to upgrade this morning and the payment page just spun forever, then i got charged twice..."
                                className="resize-none font-mono text-sm leading-relaxed"
                            />
                            <div className="flex flex-wrap items-center gap-2">
                                <span className="text-sm text-muted-foreground">Try one:</span>
                                {for (i, s) in enumerate(_SAMPLES) {
                                    <SampleChip
                                        key={str(i)}
                                        label={s["label"] as str}
                                        text={s["text"] as str}
                                        onPick={onPickSample}
                                    />
                                }}
                            </div>
                        </CardContent>
                        <CardFooter className="flex items-center gap-3">
                            <Button onClick={runTriage} disabled={busy or not raw.strip()}>
                                {"Triaging..." if busy else "Triage this"}
                            </Button>
                            <Button variant="ghost" onClick={onClear} disabled={busy}>Clear</Button>
                            <span className="ml-auto font-mono text-xs text-muted-foreground">
                                {"triage(raw) -> Ticket"}
                            </span>
                        </CardFooter>
                    </Card>

                    {if busy {
                        <Card>
                            <CardHeader>
                                <div className="flex items-start justify-between gap-4">
                                    <Skeleton className="h-7 w-2/3" />
                                    <Skeleton className="h-6 w-24 rounded-4xl" />
                                </div>
                            </CardHeader>
                            <CardContent className="flex flex-col gap-4">
                                <Skeleton className="h-4 w-full" />
                                <Skeleton className="h-4 w-5/6" />
                                <div className="flex gap-2">
                                    <Skeleton className="h-5 w-16 rounded-4xl" />
                                    <Skeleton className="h-5 w-20 rounded-4xl" />
                                    <Skeleton className="h-5 w-14 rounded-4xl" />
                                </div>
                            </CardContent>
                        </Card>
                        skip;
                    }}

                    {if errorMsg {
                        <Alert variant="destructive">
                            <AlertTitle>Extraction failed</AlertTitle>
                            <AlertDescription className="leading-relaxed">{errorMsg}</AlertDescription>
                        </Alert>
                        skip;
                    }}

                    {if ticket is not None {
                        <TicketCard ticket={ticket} />
                    }}
                </div>

                <SourceCard />
            </div>
        </div>
    </div>;
}
