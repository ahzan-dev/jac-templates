"""AI Triage -- structured extraction with `by llm()`.

Codespace placement is inferred: the plain service import stays on the server
(importing it registers POST /function/triage_ticket at startup), while `app()`
is placed client-side because it returns JSX, pulling the component import and
the stylesheet into the client bundle with it.
"""

import from services.triage { triage_ticket, Ticket, Priority, TriageResult }

import from .components.TriageStudio { TriageStudio }
import ".styles.global.css";

def:pub app() -> JsxElement {
    return <TriageStudio />;
}
