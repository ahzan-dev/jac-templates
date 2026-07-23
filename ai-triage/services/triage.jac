"""Structured extraction with `by llm()`.

The whole extractor is the ~12 lines between the two banner comments below.
There is no prompt template and no JSON parsing anywhere in this file --
the enum, the `obj`, and the `sem` lines ARE the prompt, and the declared
return type IS the parser.
"""

import from jaclang.byllm.lib { ByLLMError, AuthenticationError }

# ---------------------------------------------------------------------------
# THE ENTIRE EXTRACTOR  (this block is what the UI renders in its source card)
# ---------------------------------------------------------------------------

enum Priority { LOW, MEDIUM, HIGH, CRITICAL }

obj Ticket {
    has title: str;
    has summary: str;
    has priority: Priority;
    has tags: list[str];
}

def triage(raw: str) -> Ticket by llm(temperature=0.2);

# ---------------------------------------------------------------------------
# `sem` is how you steer the model -- typed prompt wiring, not prompt strings.
# ---------------------------------------------------------------------------

sem Priority = "How urgently a human must respond to this ticket.";
sem Priority.LOW = "A question, suggestion, or cosmetic nit. Nothing is broken.";
sem Priority.MEDIUM = "Something is broken but the user has a workaround.";
sem Priority.HIGH = "The user is blocked on a core task and has no workaround.";
sem Priority.CRITICAL = "Data loss, a security issue, money at risk, or a full outage.";

sem Ticket = "A support ticket distilled from one raw customer message.";
sem Ticket.title = "A specific one-line title in imperative support-desk style, at most 60 characters. No trailing period.";
sem Ticket.summary = "Two sentences at most: what the user was doing, and what went wrong. Neutral tone, no pleasantries.";
sem Ticket.priority = "Urgency, judged on real user impact -- not on how upset the message sounds.";
sem Ticket.tags = "Two to four short lowercase topic tags, e.g. 'billing', 'auth', 'mobile'. Single words or hyphenated. No '#'.";

sem triage = "Read one raw, messy customer support message and distill it into a structured Ticket.";
sem triage.raw = "The unedited customer message: typos, rambling, and all.";

# ---------------------------------------------------------------------------
# Transport: a thin, typed wrapper the client calls. Turns exceptions into a
# friendly result so the UI can render a real message instead of a 500.
# ---------------------------------------------------------------------------

obj TriageResult {
    has ok: bool = False;
    has ticket: Ticket | None = None;
    has error: str = "";
}

glob _NO_KEY_HELP: str = (
    "No LLM credentials found. Set OPENAI_API_KEY in your environment and "
    "restart the server -- or run the bundled local model with no key at all: "
    "`jac install 'byllm[local]'`, then set default_model = \"local:gemma-4-e2b\" "
    "under [byllm.model] in jac.toml."
);

def:pub triage_ticket(raw: str) -> TriageResult {
    if not raw or not raw.strip() {
        return TriageResult(error="Paste a support message first.");
    }
    try {
        return TriageResult(ok=True, ticket=triage(raw.strip()));
    } except AuthenticationError {
        return TriageResult(error=_NO_KEY_HELP);
    } except ByLLMError as e {
        return TriageResult(error=f"The model call failed: {e}");
    }
}
