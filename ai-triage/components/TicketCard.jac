"""Renders the typed Ticket the model returned.

Note what is NOT here: no parsing, no field-presence checks, no defaulting a
missing key. `ticket` arrived as a real Ticket instance with a real Priority
enum, so `ticket.priority` and `ticket.tags` are just typed attribute access.
"""

import from ..components.ui.card { Card, CardHeader, CardTitle, CardContent }
import from ..components.ui.badge { Badge }
import from ..components.ui.separator { Separator }
import from ..lib.utils { cn }

sv import from ..services.triage { Ticket }

# Priority -> semantic status token. Only place in the app that decides how
# urgency looks; every class here is a token, never a raw Tailwind color.
glob _TONE: dict[str, str] = {
    "LOW": "border-success/30 bg-success/10 text-success",
    "MEDIUM": "border-info/30 bg-info/10 text-info",
    "HIGH": "border-warning/30 bg-warning/10 text-warning",
    "CRITICAL": "border-destructive/30 bg-destructive/10 text-destructive"
};

glob _BLURB: dict[str, str] = {
    "LOW": "No one is blocked.",
    "MEDIUM": "Broken, but there is a workaround.",
    "HIGH": "The user is blocked with no workaround.",
    "CRITICAL": "Data, security, money, or uptime is at risk."
};

# The ordinal JSON sends for each Priority member. Jac enums are 1-indexed by
# declaration order, so "1" is LOW. Keep in lockstep with `enum Priority` in
# services/triage.jac.
glob _BY_ORDINAL: dict[str, str] = {
    "1": "LOW",
    "2": "MEDIUM",
    "3": "HIGH",
    "4": "CRITICAL"
};

"""Normalize a Priority to its bare member name.

Over JSON a Jac enum arrives as its **ordinal**, and Jac enums are 1-INDEXED
by declaration order -- LOW=1, MEDIUM=2, HIGH=3, CRITICAL=4. (Verified against
a live response; assuming 0-indexing shifts every badge by one, silently.)
Other transports send the member itself, "Priority.HIGH", or "HIGH", so handle
those too by taking the last dot-segment.
"""
def:pub priorityName(p: any) -> str {
    s = str(p);
    if not s { return "MEDIUM"; }

    # Ordinal form -- what the JSON transport actually sends.
    if s in _BY_ORDINAL { return _BY_ORDINAL[s]; }

    parts = s.split(".");
    return (parts[len(parts) - 1] as str).upper();
}

def:pub PriorityBadge(priority: any, className: str = "") -> JsxElement {
    name = priorityName(priority);
    return <span className={cn(
        "inline-flex w-fit items-center gap-2 rounded-4xl border pt-1 pb-1 pl-3 pr-3",
        "font-mono text-xs font-semibold tracking-wide",
        _TONE[name] or _TONE["MEDIUM"],
        className
    )}>
        <span className="size-1.5 rounded-4xl bg-current" />
        {name}
    </span>;
}

def:pub TicketCard(ticket: Ticket) -> JsxElement {
    name = priorityName(ticket.priority);
    return <Card>
        <CardHeader>
            <div className="flex flex-wrap items-start justify-between gap-4">
                <div className="flex flex-col gap-2">
                    <span className="font-mono text-xs text-muted-foreground">Ticket.title</span>
                    <CardTitle className="text-balance text-xl font-semibold tracking-tight">
                        {ticket.title}
                    </CardTitle>
                </div>
                <div className="flex flex-col items-end gap-2">
                    <span className="font-mono text-xs text-muted-foreground">Ticket.priority</span>
                    <PriorityBadge priority={ticket.priority} />
                </div>
            </div>
        </CardHeader>

        <CardContent className="flex flex-col gap-6">
            <Separator />

            <div className="flex flex-col gap-2">
                <span className="font-mono text-xs text-muted-foreground">Ticket.summary</span>
                <p className="text-base leading-relaxed text-foreground">{ticket.summary}</p>
            </div>

            <div className="flex flex-col gap-2">
                <span className="font-mono text-xs text-muted-foreground">Ticket.tags</span>
                <div className="flex flex-wrap gap-2">
                    {for (i, tag) in enumerate(ticket.tags) {
                        <Badge key={str(i)} variant="secondary" className="font-mono">{tag}</Badge>
                    }}
                </div>
            </div>

            <div className={cn("rounded-lg border pt-3 pb-3 pl-4 pr-4", _TONE[name] or _TONE["MEDIUM"])}>
                <p className="text-sm font-medium">{_BLURB[name] or ""}</p>
            </div>
        </CardContent>
    </Card>;
}
