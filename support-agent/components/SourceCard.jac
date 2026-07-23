"""The agent's source, on screen next to the agent.

Kept in sync by hand with services/support.jac -- if you add a tool there, add
a line here. That is the point of the card: what you read is what runs.

Each entry in _SRC is one LINE, and a line is a list of {t: text, k: kind}
spans. Lines are separate <div>s rather than "\\n" characters on purpose: in
client Jac, "\\n" in a string literal compiles to a literal backslash-n, not a
newline (use chr(10) if you ever genuinely need the character).
"""

import from ..components.ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from ..components.ui.badge { Badge }
import from ..components.ui.separator { Separator }
import from ..lib.utils { cn }

glob _SRC: list[list[dict]] = [
    [{"t": "def ", "k": "kw"}, {"t": "ask", "k": "fn"}, {"t": "(question: ", "k": "plain"},
     {"t": "str", "k": "type"}, {"t": ") -> ", "k": "plain"}, {"t": "str", "k": "type"},
     {"t": " by ", "k": "kw"}, {"t": "llm", "k": "llm"}, {"t": "(", "k": "plain"}],
    [{"t": "    tools=[", "k": "plain"}],
    [{"t": "        search_docs", "k": "tool"}, {"t": ",       # the knowledge base", "k": "cmt"}],
    [{"t": "        get_customer", "k": "tool"}, {"t": ",      # who is this", "k": "cmt"}],
    [{"t": "        get_tier_limits", "k": "tool"}, {"t": ",   # what the plan allows", "k": "cmt"}],
    [{"t": "        get_billing", "k": "tool"}, {"t": ",       # payment history", "k": "cmt"}],
    [{"t": "        get_projects", "k": "tool"}, {"t": ",      # projects + deploys", "k": "cmt"}],
    [{"t": "        open_ticket", "k": "write"}, {"t": ",        # the only WRITE", "k": "cmt"}],
    [{"t": "    ],", "k": "plain"}],
    [{"t": "    max_react_iterations=", "k": "plain"}, {"t": "6", "k": "num"}],
    [{"t": ");", "k": "plain"}]
];

glob _SEM: list[list[dict]] = [
    [{"t": "sem ", "k": "kw"}, {"t": "get_tier_limits", "k": "field"}, {"t": " =", "k": "plain"}],
    [{"t": "    \"Return exactly what one plan permits...", "k": "str"}],
    [{"t": "     The documentation does not contain these", "k": "str"}],
    [{"t": "     numbers, so never guess a limit -- call this.\";", "k": "str"}]
];

def _tone(k: str) -> str {
    if k == "kw" { return "text-primary"; }
    if k == "type" { return "font-semibold text-foreground"; }
    if k == "fn" { return "font-semibold text-foreground"; }
    if k == "tool" { return "font-semibold text-info"; }
    if k == "write" { return "font-semibold text-warning"; }
    if k == "field" { return "text-info"; }
    if k == "num" { return "text-info"; }
    if k == "cmt" { return "text-muted-foreground/70 italic"; }
    if k == "llm" { return "rounded-sm bg-primary/10 font-semibold text-primary"; }
    if k == "str" { return "text-success"; }
    return "text-muted-foreground";
}

def:pub CodeBlock(lines: list[list[dict]], className: str = "") -> JsxElement {
    return <pre className={cn(
        "overflow-x-auto rounded-lg border border-border bg-muted/40 pt-4 pb-4 pl-4 pr-4",
        "font-mono text-[13px] leading-6",
        className
    )}>
        <code>
            {for (i, line) in enumerate(lines) {
                <div key={str(i)} className="min-h-6">
                    {for (j, s) in enumerate(line) {
                        <span key={str(j)} className={_tone(s["k"] as str)}>{s["t"]}</span>
                    }}
                </div>
            }}
        </code>
    </pre>;
}

def:pub SourceCard() -> JsxElement {
    return <Card className="lg:sticky lg:top-8">
        <CardHeader>
            <Badge variant="outline" className="mb-2 w-fit font-mono">services/support.jac</Badge>
            <CardTitle className="text-lg font-semibold">That is the entire agent</CardTitle>
            <CardDescription className="text-base leading-relaxed">
                No body, no prompt string, no ReAct loop to write. Passing
                {" "}<code className="font-mono text-foreground">tools=[...]</code> turns the loop
                on: the model reads each tool and decides which ones the question needs.
            </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-6">
            <CodeBlock lines={_SRC} />

            <div className="flex flex-col gap-3">
                <Separator />
                <p className="text-sm text-muted-foreground">
                    A tool is chosen because of its <code className="font-mono text-foreground">sem</code>,
                    {" "}not because of anything in a prompt template:
                </p>
                <CodeBlock lines={_SEM} />
            </div>

            <div className="rounded-lg border border-border pt-4 pb-4 pl-4 pr-4">
                <p className="text-sm leading-relaxed text-muted-foreground">
                    <span className="font-semibold text-foreground">The docs are just files.</span>
                    {" "}<code className="font-mono text-foreground">search_docs</code> reads
                    {" "}<code className="font-mono text-foreground">knowledge/*.md</code> off disk at
                    {" "}question time. Drop your own markdown in there and the agent answers from it.
                </p>
            </div>
        </CardContent>
    </Card>;
}
