"""Sticky top navigation bar with a collapsible mobile menu."""

import from ".ui.button" { Button }
import from "..lib.utils" { cn }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { FlashIcon, Menu01Icon, Cancel01Icon }

glob _navLinks: list[dict[str, str]] = [
    {"label": "Features", "href": "#features"},
    {"label": "Pricing", "href": "#pricing"},
    {"label": "FAQ", "href": "#faq"},
    {"label": "Docs", "href": "#"}
];

def:pub Navbar() -> JsxElement {
    has mobileOpen: bool = False;

    def toggle_mobile(_e: MouseEvent) {
        mobileOpen = not mobileOpen;
    }

    def close_mobile(_e: MouseEvent) {
        mobileOpen = False;
    }

    return
        <header className="sticky top-0 z-50 w-full border-b border-border bg-background/80 backdrop-blur">
            <div className="mx-auto flex h-16 max-w-7xl items-center justify-between pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
                <a href="#" className="flex items-center gap-2">
                    <span className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                        <HugeiconsIcon icon={FlashIcon} strokeWidth={2} className="size-4" />
                    </span>
                    <span className="text-base font-semibold tracking-tight">Slipstream</span>
                </a>

                <nav className="hidden items-center gap-8 md:flex">
                    {for link in _navLinks {
                        <a
                            key={link["label"]}
                            href={link["href"]}
                            className="text-sm text-muted-foreground transition-colors hover:text-foreground"
                        >
                            {link["label"]}
                        </a>
                    }}
                </nav>

                <div className="flex items-center gap-2">
                    <Button variant="ghost" size="sm" className="hidden sm:inline-flex">Sign in</Button>
                    <Button size="sm">Start free</Button>
                    <Button
                        variant="ghost"
                        size="icon-sm"
                        className="md:hidden"
                        aria-label="Toggle menu"
                        onClick={toggle_mobile}
                    >
                        <HugeiconsIcon
                            icon={Cancel01Icon if mobileOpen else Menu01Icon}
                            strokeWidth={2}
                        />
                    </Button>
                </div>
            </div>

            {if mobileOpen {
                <nav className="border-t border-border bg-background md:hidden">
                    <div className="mx-auto flex max-w-7xl flex-col pt-2 pb-4 pl-4 pr-4 sm:pl-6 sm:pr-6">
                        {for link in _navLinks {
                            <a
                                key={link["label"]}
                                href={link["href"]}
                                onClick={close_mobile}
                                className="rounded-lg pt-2 pb-2 pl-2 pr-2 text-sm text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                            >
                                {link["label"]}
                            </a>
                        }}
                    </div>
                </nav>
            }}
        </header>;
}
