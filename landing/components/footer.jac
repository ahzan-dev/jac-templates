"""Site footer: brand blurb, link columns, and legal line."""

import from ".ui.separator" { Separator }
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { FlashIcon }

glob _columns: list[dict[str, any]] = [
    {
        "heading": "Product",
        "links": ["Features", "Pricing", "Changelog", "Status"]
    },
    {
        "heading": "Developers",
        "links": ["Documentation", "API reference", "CLI", "Integrations"]
    },
    {
        "heading": "Company",
        "links": ["About", "Blog", "Careers", "Contact"]
    },
    {
        "heading": "Legal",
        "links": ["Privacy", "Terms", "Security", "DPA"]
    }
];

def:pub Footer() -> JsxElement {
    return
        <footer className="border-t border-border">
            <div className="mx-auto max-w-7xl pt-12 pb-12 pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
                <div className="grid grid-cols-2 gap-8 md:grid-cols-5">
                    <div className="col-span-2 md:col-span-1">
                        <a href="#" className="flex items-center gap-2">
                            <span className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                                <HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-4" />
                            </span>
                            <span className="text-base font-semibold tracking-tight">Slipstream</span>
                        </a>
                        <p className="mt-4 max-w-xs text-sm text-muted-foreground">
                            The deployment platform for teams that ship every day.
                        </p>
                    </div>

                    {for column in _columns {
                        <div key={column["heading"]}>
                            <h3 className="text-sm font-semibold">{column["heading"]}</h3>
                            <ul className="mt-4 flex flex-col gap-3">
                                {for link in column["links"] {
                                    <li key={link}>
                                        <a
                                            href="#"
                                            className="text-sm text-muted-foreground transition-colors hover:text-foreground"
                                        >
                                            {link}
                                        </a>
                                    </li>
                                }}
                            </ul>
                        </div>
                    }}
                </div>

                <Separator className="mt-12" />

                <div className="mt-6 flex flex-col items-center justify-between gap-4 sm:flex-row">
                    <p className="text-xs text-muted-foreground">
                        {"© 2026 Slipstream Labs, Inc. All rights reserved."}
                    </p>
                    <p className="text-xs text-muted-foreground">Built with Jac</p>
                </div>
            </div>
        </footer>;
}
