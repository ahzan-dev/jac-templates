"""The one screen: ask the desk a question, watch it pick tools, read the answer.

There is no login. Everything on the desk is visible to everyone who opens the
app -- see the README on why that is deliberate, and what to do instead.
"""

import from ..components.ui.button { Button }
import from ..components.ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from ..components.ui.input { Input }
import from ..components.ui.badge { Badge }
import from ..components.ui.alert { Alert, AlertTitle, AlertDescription }
import from ..components.ui.skeleton { Skeleton }
import from ..components.ui.separator { Separator }
import from ..components.TraceCard { TraceCard }
import from ..components.SourceCard { SourceCard }
import from ..lib.utils { cn }

sv import from ..services.support { ask_support, list_customers, Answer, ToolCall, Customer }

"""Five questions that each exercise a different shape of the loop. The `hint`
is what to watch for in the trace -- it is the demo, spelled out."""
glob _PRESETS: list[dict] = [
    {
        "label": "Docs only",
        "hint": "search_docs alone -- no customer lookup",
        "text": "What is a preview, and how is it different from a deployment?"
    },
    {
        "label": "Two tools, chained",
        "hint": "get_customer -> get_tier_limits",
        "text": "Why can't Maya Okonjo (maya@northwind.dev) deploy her project?"
    },
    {
        "label": "Billing",
        "hint": "get_billing",
        "text": "Did Rafael Ortiz's last payment go through? His email is raf@studioloop.io"
    },
    {
        "label": "Projects",
        "hint": "get_projects",
        "text": "Is jin@atlasgrid.com's project live right now?"
    },
    {
        "label": "Writes a ticket",
        "hint": "open_ticket -- the only write tool",
        "text": "Open a ticket for dana@fernwood.co: she is at her project limit and wants it raised."
    }
];

def _tierTone(tier: str) -> str {
    if tier == "pro" { return "border-primary/40 text-primary"; }
    if tier == "builder" { return "border-info/40 text-info"; }
    return "border-border text-muted-foreground";
}

"""One preset button. A component rather than an inline lambda so each chip
closes over its own `text` through a typed callback prop."""
def:pub PresetChip(label: str, hint: str, text: str, disabled: bool, onPick: Callable[[str], None]) -> JsxElement {
    def handle(e: MouseEvent) {
        onPick(text);
    }
    return <button
        type="button"
        onClick={handle}
        disabled={disabled}
        className={cn(
            "flex flex-col items-start gap-0.5 rounded-lg border border-border",
            "pt-2 pb-2 pl-3 pr-3 text-left transition-colors",
            "hover:border-primary/40 hover:bg-muted disabled:opacity-50"
        )}
    >
        <span className="text-xs font-semibold text-foreground">{label}</span>
        <span className="font-mono text-[10px] text-muted-foreground">{hint}</span>
    </button>;
}

def:pub RosterCard(customers: list[Customer]) -> JsxElement {
    return <Card>
        <CardHeader>
            <CardTitle className="text-lg font-semibold">On the desk</CardTitle>
            <CardDescription className="text-base leading-relaxed">
                Seeded onto the graph at first question -- five customers, five different
                situations. No database to set up: these are nodes hanging off
                {" "}<code className="font-mono text-foreground">root</code>, persisted
                for you with zero config.
            </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
            {for (i, c) in enumerate(customers) {
                <div key={str(i)} className="flex items-center justify-between gap-3">
                    <div className="flex min-w-0 flex-col">
                        <span className="truncate text-sm font-medium text-foreground">{c.name}</span>
                        <span className="truncate font-mono text-xs text-muted-foreground">{c.email}</span>
                    </div>
                    <Badge variant="outline" className={cn("shrink-0 text-xs", _tierTone(c.tier))}>
                        {c.tier}
                    </Badge>
                </div>
            }}
        </CardContent>
    </Card>;
}

"""The resolved answer. Split out so `answer` is a plain `Answer` here -- a
JSX statement slot does not narrow `Answer | None` for the slots after it."""
def:pub AnswerBody(answer: Answer) -> JsxElement {
    if not answer.ok {
        return <Alert variant="destructive">
            <AlertTitle>That did not work</AlertTitle>
            <AlertDescription className="leading-relaxed">{answer.error}</AlertDescription>
        </Alert>;
    }
    return <p className="whitespace-pre-wrap text-base leading-relaxed text-foreground">{answer.text}</p>;
}

def:pub AnswerCard(answer: Answer | None, busy: bool) -> JsxElement {
    body: JsxElement = <p className="text-sm text-muted-foreground">
        Pick a question above, or write your own.
    </p>;
    if busy {
        body = <div className="flex flex-col gap-2">
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-11/12" />
            <Skeleton className="h-4 w-3/5" />
        </div>;
    } elif answer is not None {
        body = <AnswerBody answer={answer} />;
    }
    return <Card>
        <CardHeader>
            <CardTitle className="text-lg font-semibold">Answer</CardTitle>
        </CardHeader>
        <CardContent>{body}</CardContent>
    </Card>;
}

def:pub SupportDesk() -> JsxElement {
    has question: str = "";
    has answer: Answer | None = None;
    has busy: bool = False;
    has roster: list[Customer] = [];

    async can with entry {
        roster = await list_customers();
    }

    """The local passed to `ask_support` must be NAMED `question`: a def:pub RPC
    takes positional args and the caller's identifier becomes the JSON key."""
    async def runQuery(question: str) -> None {
        res = await ask_support(question);
        answer = res;
        busy = False;
    }

    async def start(q: str) -> None {
        if busy {
            return;
        }
        text = q.strip();
        if len(text) == 0 {
            return;
        }
        question = text;
        answer = None;
        busy = True;
        await runQuery(text);
    }

    def onChange(e: ChangeEvent) {
        question = e.target.value;
    }

    async def onSubmit(e: FormEvent) {
        e.preventDefault();
        await start(question);
    }

    async def onPick(text: str) -> None {
        await start(text);
    }

    trace: list[ToolCall] = answer.trace if answer else [];

    return <main className="min-h-svh bg-background">
        <div className="mx-auto max-w-7xl pt-12 pb-16 pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
            <header className="mx-auto max-w-3xl text-center">
                <Badge variant="outline" className="mb-4 font-mono">by llm(tools=[...])</Badge>
                <h1 className="text-balance text-4xl font-bold tracking-tight sm:text-5xl">
                    A support agent that decides
                </h1>
                <p className="mt-4 text-balance text-lg leading-8 text-muted-foreground">
                    Six tools, no loop to write. Some questions need the docs. Some need the
                    customer record. Some need both, in order. Watch it choose.
                </p>
            </header>

            <div className="mt-12 grid gap-8 lg:grid-cols-3">
                <div className="flex flex-col gap-8 lg:col-span-2">
                    <Card>
                        <CardHeader>
                            <CardTitle className="text-lg font-semibold">Ask the desk</CardTitle>
                            <CardDescription className="text-base leading-relaxed">
                                Each preset takes a different path through the loop.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="flex flex-col gap-6">
                            <form onSubmit={onSubmit} className="flex flex-col gap-3 sm:flex-row">
                                <Input
                                    value={question}
                                    onChange={onChange}
                                    disabled={busy}
                                    placeholder="Why can't maya@northwind.dev deploy?"
                                    className="flex-1"
                                />
                                <Button type="submit" disabled={busy} className="sm:w-32">
                                    {"Thinking..." if busy else "Ask"}
                                </Button>
                            </form>

                            <div className="flex flex-col gap-3">
                                <Separator />
                                <p className="text-sm text-muted-foreground">Try one of these:</p>
                                <div className="flex flex-wrap gap-2">
                                    {for (i, p) in enumerate(_PRESETS) {
                                        <PresetChip
                                            key={str(i)}
                                            label={p["label"] as str}
                                            hint={p["hint"] as str}
                                            text={p["text"] as str}
                                            disabled={busy}
                                            onPick={onPick}
                                        />
                                    }}
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <TraceCard trace={trace} busy={busy} />
                    <AnswerCard answer={answer} busy={busy} />
                </div>

                <div className="flex flex-col gap-8">
                    <SourceCard />
                    <RosterCard customers={roster} />
                </div>
            </div>
        </div>
    </main>;
}
