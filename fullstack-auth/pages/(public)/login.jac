"""/login -- public route."""

import from "...components.LoginPage" { LoginPage }

def:pub page() -> JsxElement {
    return <LoginPage />;
}
