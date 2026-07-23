"""Slipstream landing page - composition root."""

import from ".components.navbar" { Navbar }
import from ".components.hero" { Hero }
import from ".components.features" { Features }
import from ".components.pricing" { Pricing }
import from ".components.faq" { Faq }
import from ".components.cta" { CallToAction }
import from ".components.footer" { Footer }
import ".styles.global.css";

def:pub app() -> JsxElement {
    return
        <div className="min-h-screen bg-background text-foreground">
            <Navbar />
            <main>
                <Hero />
                <Features />
                <Pricing />
                <Faq />
                <CallToAction />
            </main>
            <Footer />
        </div>;
}
