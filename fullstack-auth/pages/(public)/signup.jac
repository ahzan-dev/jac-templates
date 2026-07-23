"""/signup -- public route."""

import from "...components.SignupPage" { SignupPage }

def:pub page() -> JsxElement {
    return <SignupPage />;
}
