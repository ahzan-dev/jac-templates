"""The trace: which tools the agent chose, in the order it chose them.

This is the point of the template. A one-shot `by llm()` has nothing to show
here -- it just returns. An agent with `tools=[...]` makes decisions, and this
card is where you watch it make them: one step per tool call, with the argument
the model picked and what came back.
"""

import from ..components.ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from ..components.ui.badge { Badge }
import from ..lib.utils { cn }

sv import from ..services.support { ToolCall }

"""open_ticket is the only tool that mutates the graph -- it gets its own
color so a write is never mistaken for a read at a glance."""
def _isWrite(tool: str) -> bool {
    return tool == "open_ticket";
}

def:pub TraceStep(index: int, call: ToolCall, last: bool) -> JsxElement {
    write = _isWrite(call.tool);
    return <li className="relative flex gap-4 pb-5">
        {if not last {
            <span className="absolute left-3.5 top-8 bottom-0 w-px bg-border" />
        }}
        <span className={cn(
            "relative z-10 flex size-7 shrink-0 items-center justify-center rounded-full",
            "border text-xs font-semibold tabular-nums",
            "border-warning/40 bg-warning/10 text-warning" if write
                else "border-primary/40 bg-primary/10 text-primary"
        )}>{str(index + 1)}</span>

        <div className="flex min-w-0 flex-col gap-1 pt-0.5">
            <div className="flex flex-wrap items-center gap-2">
                <code className={cn(
                    "font-mono text-sm font-semibold",
                    "text-warning" if write else "text-foreground"
                )}>{call.tool}</code>
                {if write {
                    <Badge variant="outline" className="border-warning/40 text-warning text-[10px]">writes</Badge>
                }}
            </div>
            <p className="break-words font-mono text-xs text-muted-foreground">{call.args}</p>
            <p className="break-words text-xs text-muted-foreground">
                <span className="text-foreground/70">{"-> "}</span>{call.result}
            </p>
        </div>
    </li>;
}

def:pub TraceCard(trace: list[ToolCall], busy: bool = False) -> JsxElement {
    n = len(trace);
    return <Card>
        <CardHeader>
            <div className="flex flex-wrap items-center justify-between gap-2">
                <CardTitle className="text-lg font-semibold">Tool trace</CardTitle>
                {if n > 0 {
                    <Badge variant="outline" className="font-mono text-xs">
                        {str(n) + (" call" if n == 1 else " calls")}
                    </Badge>
                }}
            </div>
            <CardDescription className="text-base leading-relaxed">
                What the ReAct loop actually did. Nothing here is scripted -- the model
                picked each tool from its <code className="font-mono text-foreground">sem</code>.
            </CardDescription>
        </CardHeader>
        <CardContent>
            {if busy and n == 0 {
                <p className="text-sm text-muted-foreground">Thinking about which tools this needs...</p>
                skip;
            }}
            {if n == 0 {
                <p className="text-sm text-muted-foreground">
                    No tools called yet. Ask something on the left.
                </p>
                skip;
            }}
            <ol className="flex flex-col">
                {for (i, c) in enumerate(trace) {
                    <TraceStep key={str(i)} index={i} call={c} last={i == n - 1} />
                }}
            </ol>
        </CardContent>
    </Card>;
}
