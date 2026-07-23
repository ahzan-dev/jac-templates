"""Support Agent -- a multi-tool ReAct agent with `by llm(tools=[...])`.

Codespace placement is inferred. The service import stays on the server --
importing it registers POST /function/ask_support at startup. Its path is
ABSOLUTE (`services.support`, no leading dot): no-dot imports resolve against
the project root from any depth. A leading-dot relative import passes
`jac check` and then dies at runtime with "attempted relative import with no
known parent package".

`app()` returns JSX, so it and the component/stylesheet imports it needs are
placed client-side automatically.
"""

import from services.support { ask_support, list_customers, Answer, ToolCall, Customer }

import from .components.SupportDesk { SupportDesk }
import ".styles.global.css";

def:pub app() -> JsxElement {
    return <SupportDesk />;
}
