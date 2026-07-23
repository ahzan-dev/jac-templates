"""/ -- send visitors wherever they belong."""

import from "@jac/runtime" { jacIsLoggedIn, Navigate }

def:pub page() -> JsxElement {
    if jacIsLoggedIn() {
        return <Navigate to="/dashboard" replace={True} />;
    }
    return <Navigate to="/login" replace={True} />;
}
