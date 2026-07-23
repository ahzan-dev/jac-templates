"""/dashboard -- protected route.

Nothing in this file mentions auth. The `(auth)` directory name is what
wraps this page in an AuthGuard; visitors without a session are redirected
to /login before `page()` ever renders.
"""

import from "...components.DashboardPage" { DashboardPage }

def:pub page() -> JsxElement {
    return <DashboardPage />;
}
