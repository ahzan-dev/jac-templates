"""The teaching payload: the actual extractor source, on screen next to the demo.

Kept in sync by hand with services/triage.jac -- if you change the obj there,
change the spans here. That is the whole point of the card: what you read is
what runs.

Each entry in _SRC is one LINE, and a line is a list of {t: text, k: kind}
spans. Lines are separate <div>s rather than "\\n" characters on purpose:
in client Jac, "\\n" in a string literal compiles to a literal backslash-n,
not a newline (use chr(10) if you ever genuinely need the character).
"""

import from ..components.ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from ..components.ui.badge { Badge }
import from ..components.ui.separator { Separator }
import from ..lib.utils { cn }

glob _SRC: list[list[dict]] = [
    [{"t": "enum ", "k": "kw"}, {"t": "Priority", "k": "type"},
     {"t": " { LOW, MEDIUM, HIGH, CRITICAL }", "k": "plain"}],
    [],
    [{"t": "obj ", "k": "kw"}, {"t": "Ticket", "k": "type"}, {"t": " {", "k": "plain"}],
    [{"t": "    has ", "k": "kw"}, {"t": "title", "k": "field"},
     {"t": ": ", "k": "plain"}, {"t": "str", "k": "type"}, {"t": ";", "k": "plain"}],
    [{"t": "    has ", "k": "kw"}, {"t": "summary", "k": "field"},
     {"t": ": ", "k": "plain"}, {"t": "str", "k": "type"}, {"t": ";", "k": "plain"}],
    [{"t": "    has ", "k": "kw"}, {"t": "priority", "k": "field"},
     {"t": ": ", "k": "plain"}, {"t": "Priority", "k": "type"}, {"t": ";", "k": "plain"}],
    [{"t": "    has ", "k": "kw"}, {"t": "tags", "k": "field"},
     {"t": ": ", "k": "plain"}, {"t": "list[str]", "k": "type"}, {"t": ";", "k": "plain"}],
    [{"t": "}", "k": "plain"}],
    [],
    [{"t": "def ", "k": "kw"}, {"t": "triage", "k": "fn"}, {"t": "(raw: ", "k": "plain"},
     {"t": "str", "k": "type"}, {"t": ") -> ", "k": "plain"}, {"t": "Ticket", "k": "type"},
     {"t": " by ", "k": "kw"}, {"t": "llm", "k": "llm"}, {"t": "();", "k": "plain"}]
];

glob _SEM: list[list[dict]] = [
    [{"t": "sem ", "k": "kw"}, {"t": "Ticket.priority", "k": "field"}, {"t": " =", "k": "plain"}],
    [{"t": "    \"Urgency, judged on real user impact --", "k": "str"}],
    [{"t": "     not on how upset the message sounds.\";", "k": "str"}]
];

def _tone(k: str) -> str {
    if k == "kw" { return "text-primary"; }
    if k == "type" { return "font-semibold text-foreground"; }
    if k == "fn" { return "font-semibold text-foreground"; }
    if k == "field" { return "text-info"; }
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
            <Badge variant="outline" className="mb-2 w-fit font-mono">services/triage.jac</Badge>
            <CardTitle className="text-lg font-semibold">That is the entire backend</CardTitle>
            <CardDescription className="text-base leading-relaxed">
                No prompt template. No <code className="font-mono text-foreground">json.loads</code>.
                {" "}These types <em>are</em> the prompt, and the return type <em>is</em> the parser.
            </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-6">
            <CodeBlock lines={_SRC} />

            <div className="flex flex-col gap-3">
                <Separator />
                <p className="text-sm text-muted-foreground">
                    Steer the model by describing a field, not by writing a prompt:
                </p>
                <CodeBlock lines={_SEM} />
            </div>

            <div className="rounded-lg border border-border pt-4 pb-4 pl-4 pr-4">
                <p className="text-sm leading-relaxed text-muted-foreground">
                    <span className="font-semibold text-foreground">Swap the model, not the code.</span>
                    {" "}Point <code className="font-mono text-foreground">default_model</code> at
                    {" "}<code className="font-mono text-foreground">claude-sonnet-4-6</code> or
                    {" "}<code className="font-mono text-foreground">local:gemma-4-e2b</code> in
                    {" "}<code className="font-mono text-foreground">jac.toml</code>. The Jac above never changes.
                </p>
            </div>
        </CardContent>
    </Card>;
}
