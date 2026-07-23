"""FAQ section: common questions in a single-open accordion."""

import from ".ui.badge" { Badge }
import from ".ui.accordion" { Accordion, AccordionItem, AccordionTrigger, AccordionContent }
import from "..lib.utils" { cn }

glob _faqs: list[dict[str, str]] = [
    {
        "question": "How long does it take to migrate?",
        "answer": "Most teams are deploying on Slipstream within an afternoon. Point us at your repository and we detect the framework, build command, and environments automatically."
    },
    {
        "question": "Do you work with our existing CI?",
        "answer": "Yes. Slipstream can own the whole pipeline or run only the deploy step and take status checks from GitHub Actions, GitLab CI, or Jenkins."
    },
    {
        "question": "What counts as a build minute?",
        "answer": "Wall-clock time your pipeline spends running, measured per job. Parallel jobs are billed for their own runtime, so splitting a suite makes it finish sooner without costing more."
    },
    {
        "question": "Can we self-host?",
        "answer": "Enterprise plans can run build workers inside your own VPC while the control plane stays managed. Your source code and secrets never leave your network."
    },
    {
        "question": "What happens when a deploy goes wrong?",
        "answer": "Every release is immutable and health-checked. If error rates spike, Slipstream can roll back automatically, or you can revert to any earlier release in one click."
    },
    {
        "question": "Is there a free plan?",
        "answer": "Starter is free forever for one project, including preview URLs and 500 build minutes a month. No credit card required to begin."
    }
];

def:pub Faq() -> JsxElement {
    return
        <section id="faq" className="pt-16 pb-16 sm:pt-24 sm:pb-24">
            <div className="mx-auto max-w-3xl pl-4 pr-4 sm:pl-6 sm:pr-6 lg:pl-8 lg:pr-8">
                <div className="mx-auto max-w-2xl text-center">
                    <Badge variant="outline" className="mb-4">FAQ</Badge>
                    <h2 className="text-balance text-3xl font-bold tracking-tight sm:text-4xl">
                        Questions, answered
                    </h2>
                    <p className="mt-4 text-balance text-lg text-muted-foreground">
                        {"Still curious? Our team replies to every message within a day."}
                    </p>
                </div>

                <Accordion type="single" collapsible={True} className="mt-12">
                    {for item in _faqs {
                        <AccordionItem key={item["question"]} value={item["question"]}>
                            <AccordionTrigger className="text-left text-base font-medium">
                                {item["question"]}
                            </AccordionTrigger>
                            <AccordionContent className="text-base leading-relaxed text-muted-foreground">
                                {item["answer"]}
                            </AccordionContent>
                        </AccordionItem>
                    }}
                </Accordion>
            </div>
        </section>;
}
