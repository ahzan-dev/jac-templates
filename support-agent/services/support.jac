"""The support desk: a multi-tool ReAct agent built with `by llm(tools=[...])`.

The interesting line in this file is `ask`, near the bottom:

    def ask(question: str) -> str by llm(tools=[search_docs, get_customer, ...]);

There is no body, no prompt string, and no output parsing. Passing `tools=[...]`
turns on the ReAct loop: the model reads each tool's `sem`, decides which ones
the question needs, calls them, reads what came back, and decides again -- until
it can answer. Some questions take one tool, some take two chained, some take
none.

Every tool logs itself to `_TRACE`, and `ask_support` hands that trace to the UI
alongside the answer. Watching the agent choose is the entire point of this app.
"""

import os;
import from datetime { date }
import from jaclang.byllm.lib { ByLLMError, AuthenticationError }


# ===========================================================================
# The graph -- one support desk, one root, many customers.
#
# There is deliberately NO auth here: every customer hangs off the same root
# and anyone can read anyone. That makes this a demo desk, not a real one --
# see the README, and `jac guide jac-sv-auth` for the real thing.
# ===========================================================================

node Customer {
    has email: str;
    has name: str;
    has tier: str;
    has joined: str;
}

node Project {
    has name: str;
    has status: str;
    has created: str;
}

node Payment {
    has amount_usd: float;
    has status: str;
    has date: str;
    has invoice: str;
}

node Deployment {
    has project: str;
    has status: str;
    has url: str;
    has date: str;
}

node Ticket {
    has email: str;
    has summary: str;
    has created: str;
}

# Declaring endpoints on the edge means every traversal infers its node type,
# with no per-read `[?:Type]` filter. See `jac guide jac-node-edge-patterns`.
edge Owns: Customer --> Project {}
edge Billed: Customer --> Payment {}
edge Deployed: Project --> Deployment {}
edge Raised: Customer --> Ticket {}


# ===========================================================================
# Plan limits -- seed data, the shape a real billing table has.
#
# `monthly_limit_usd` is the internal raw-model budget. Users are never shown
# it; the advertised number is credits, at 150 credits per USD.
# ===========================================================================

glob CREDITS_PER_USD: float = 150.0;

glob TIER_LIMITS: dict[str, dict[str, any]] = {
    "free": {
        "project_count": 3,
        "deploy_count": 0,
        "sandbox_deploy_count": 1,
        "monthly_limit_usd": 1.3333,
        "preview_share_count": 1,
        "folder_upload_allowed": False,
        "community_submit_allowed": False,
        "default_model": "claude-sonnet-4-6",
        "models_allowed": [
            "gpt-5.2", "gpt-5.4",
            "claude-sonnet-4-5-20250929", "claude-sonnet-4-6"
        ]
    },
    "builder": {
        "project_count": 5,
        "deploy_count": 1,
        "sandbox_deploy_count": 5,
        "monthly_limit_usd": 4.00,
        "preview_share_count": 3,
        "folder_upload_allowed": True,
        "community_submit_allowed": True,
        "default_model": "claude-sonnet-4-6",
        "models_allowed": [
            "gpt-5.2", "gpt-5.4",
            "claude-sonnet-4-5-20250929", "claude-sonnet-4-6"
        ]
    },
    "pro": {
        "project_count": 10,
        "deploy_count": 3,
        "sandbox_deploy_count": 15,
        "monthly_limit_usd": 10.00,
        "preview_share_count": 10,
        "folder_upload_allowed": True,
        "community_submit_allowed": True,
        "default_model": "claude-sonnet-4-6",
        "models_allowed": [
            "gpt-5.2", "gpt-5.4",
            "claude-sonnet-4-5-20250929", "claude-sonnet-4-6",
            "claude-opus-4-5-20251101", "claude-opus-4-6"
        ]
    }
};


# ===========================================================================
# The trace. Every tool appends one line to it; `ask_support` clears it, runs
# the agent, and ships it to the UI. A `glob` is honest at demo scale -- one
# operator, one question at a time. Concurrent questions would interleave.
# ===========================================================================

obj ToolCall {
    has tool: str = "";
    has args: str = "";
    has result: str = "";
}

glob _TRACE: list[ToolCall] = [];

def _trace(tool: str, args: str, result: str) {
    _TRACE.append(ToolCall(tool=tool, args=args, result=result));
}


# ===========================================================================
# Seed data -- five customers, five different situations.
# ===========================================================================

def _today() -> str {
    return date.today().isoformat();
}

def _seed_customer(email: str, name: str, tier: str, joined: str) -> Customer {
    c = Customer(email=email, name=name, tier=tier, joined=joined);
    root ++> c;
    return c;
}

"""Create the desk once. Idempotent: a reload finds the customers already on
the graph and returns immediately."""
def _ensure_seed {
    if len([root --> [?:Customer]]) > 0 {
        return;
    }

    # Free, wants to deploy -- and free allows zero deployments. Answering
    # "why can't Maya deploy?" needs get_customer THEN get_tier_limits.
    maya = _seed_customer("maya@northwind.dev", "Maya Okonjo", "free", "2026-05-02");
    mp = Project(name="northwind-menu", status="active", created="2026-05-03");
    maya +>:Owns:+> mp;
    maya +>:Owns:+> Project(name="scratch-pad", status="active", created="2026-06-20");

    # Builder, last charge declined.
    raf = _seed_customer("raf@studioloop.io", "Rafael Ortiz", "builder", "2025-11-14");
    rp = Project(name="studioloop-site", status="active", created="2025-11-15");
    raf +>:Owns:+> rp;
    rp +>:Deployed:+> Deployment(
        project="studioloop-site", status="failed",
        url="https://studioloop-site.example.app", date="2026-07-09"
    );
    raf +>:Billed:+> Payment(amount_usd=15.0, status="paid", date="2026-05-14", invoice="INV-3312");
    raf +>:Billed:+> Payment(amount_usd=15.0, status="paid", date="2026-06-14", invoice="INV-3618");
    raf +>:Billed:+> Payment(amount_usd=15.0, status="failed", date="2026-07-14", invoice="INV-3944");

    # Pro, everything healthy, one live deployment.
    jin = _seed_customer("jin@atlasgrid.com", "Jin Park", "pro", "2025-08-21");
    jp = Project(name="atlasgrid-dash", status="active", created="2025-08-22");
    jin +>:Owns:+> jp;
    jp +>:Deployed:+> Deployment(
        project="atlasgrid-dash", status="live",
        url="https://atlasgrid-dash.example.app", date="2026-07-11"
    );
    jin +>:Owns:+> Project(name="atlasgrid-docs", status="active", created="2026-02-03");
    jin +>:Billed:+> Payment(amount_usd=25.0, status="paid", date="2026-06-21", invoice="INV-3701");
    jin +>:Billed:+> Payment(amount_usd=25.0, status="paid", date="2026-07-21", invoice="INV-4055");

    # Builder, sitting exactly on the builder project cap of 5.
    dana = _seed_customer("dana@fernwood.co", "Dana Whitfield", "builder", "2026-01-09");
    for nm in ["fernwood-shop", "fernwood-blog", "fernwood-admin", "client-brief", "old-landing"] {
        dana +>:Owns:+> Project(name=nm, status="active", created="2026-01-10");
    }
    dana +>:Billed:+> Payment(amount_usd=15.0, status="paid", date="2026-07-09", invoice="INV-3902");

    # Free, brand new, nothing built yet.
    _seed_customer("sam@quietfox.app", "Sam Ellery", "free", "2026-07-01");
}

def _find_customer(email: str) -> Customer | None {
    key = (email or "").strip().lower();
    if len(key) == 0 {
        return None;
    }
    for c in [root --> [?:Customer]] {
        if c.email.lower() == key {
            return c;
        }
    }
    return None;
}


# ===========================================================================
# The knowledge base: knowledge/*.md, read from disk on every search.
#
# Retrieval is keyword matching over `## ` sections -- no embeddings, no
# vector store, no dependencies. It is honest about what it is: it will miss a
# paraphrase that shares no words with the docs. See the README.
# ===========================================================================

glob _STOP: list[str] = [
    "the", "and", "for", "are", "was", "why", "how", "what", "who", "can",
    "cant", "does", "did", "his", "her", "their", "this", "that", "with",
    "have", "has", "not", "you", "your", "our", "get", "got", "any", "all",
    "but", "from", "about", "into", "they", "them", "she", "him", "its",
    "user", "users", "customer", "please", "tell"
];

def _knowledge_dir() -> str {
    return os.path.join(os.path.realpath("."), "knowledge");
}

"""Every `## ` section of every knowledge/*.md, as {file, text} dicts."""
def _read_sections() -> list[dict[str, str]] {
    out: list[dict[str, str]] = [];
    d = _knowledge_dir();
    if not os.path.isdir(d) {
        return out;
    }
    for fn in sorted(os.listdir(d)) {
        if not fn.endswith(".md") {
            continue;
        }
        try {
            with open(os.path.join(d, fn), "r") as f {
                text = f.read();
            }
        } except OSError {
            continue;
        }
        chunks = text.split("\n## ");
        for (i, ch) in enumerate(chunks) {
            body = ch if i == 0 else "## " + ch;
            if len(body.strip()) == 0 {
                continue;
            }
            out.append({"file": fn, "text": body.strip()});
        }
    }
    return out;
}

def _keywords(query: str) -> list[str] {
    words: list[str] = [];
    for raw in (query or "").lower().split() {
        w = raw.strip(".,?!:;()[]<>\"");
        if len(w) < 3 {
            continue;
        }
        if w in _STOP {
            continue;
        }
        if w in words {
            continue;
        }
        words.append(w);
    }
    return words;
}

def _score(text: str, words: list[str]) -> int {
    low = text.lower();
    n = 0;
    for w in words {
        n += low.count(w);
    }
    return n;
}

def _search_knowledge(query: str) -> list[dict[str, any]] {
    words = _keywords(query);
    if len(words) == 0 {
        return [];
    }
    scored: list[dict[str, any]] = [];
    for sec in _read_sections() {
        s = _score(sec["text"], words);
        if s > 0 {
            scored.append({"score": s, "file": sec["file"], "text": sec["text"]});
        }
    }
    scored.sort(key=lambda(d: dict[str, any]) -> int { return 0 - (d["score"] as int); });
    return scored[:3];
}


# ===========================================================================
# THE SIX TOOLS
#
# Plain `def`, one job each, short body, and each returns a READABLE STRING --
# prose the model can reason over, not a dict it has to decode. Every tool and
# every parameter carries a `sem`: that is how the model knows what a tool is
# for and when to reach for it. No sem, no tool use.
# ===========================================================================

def search_docs(query: str) -> str {
    hits = _search_knowledge(query);
    if len(hits) == 0 {
        _trace("search_docs", "query=" + query, "no matching section");
        return "The documentation has no section matching that. Do not guess an answer.";
    }
    parts: list[str] = [];
    names: list[str] = [];
    for h in hits {
        fn = h["file"] as str;
        parts.append("--- from " + fn + " ---\n" + (h["text"] as str));
        if fn not in names {
            names.append(fn);
        }
    }
    _trace("search_docs", "query=" + query, str(len(hits)) + " section(s) from " + ", ".join(names));
    return "\n\n".join(parts);
}
sem search_docs = "Search the platform's own documentation and return the most relevant sections verbatim. This is the only source of truth for how the platform works: what previews, deployments, plans and credits are, and how to troubleshoot them. It knows nothing about any individual customer, and it does NOT contain the numeric limits of any plan -- use get_tier_limits for those.";
sem search_docs.query = "The topic to look up, as a few plain keywords rather than a sentence -- for example 'preview deployment difference' or 'failed payment card'. Matching is by keyword, so prefer the words the documentation itself would use.";


def get_customer(email: str) -> str {
    c = _find_customer(email);
    if c is None {
        _trace("get_customer", "email=" + email, "not found");
        return "No customer on record with the email " + email + ".";
    }
    _trace("get_customer", "email=" + email, c.name + ", " + c.tier + " tier");
    return (
        c.name + " <" + c.email + "> is on the " + c.tier + " plan, "
        + "and joined on " + c.joined + ". "
        + "This says which plan they are on; it does NOT say what that plan allows."
    );
}
sem get_customer = "Look one customer up by email and return who they are, which plan they are on, and when they joined. Start here for any question about a specific person. Knowing the plan NAME is not the same as knowing what that plan permits -- to answer whether they are allowed to do something, follow this with get_tier_limits on the plan name it returns.";
sem get_customer.email = "The customer's email address, exactly as written in the question.";


def get_tier_limits(tier: str) -> str {
    key = (tier or "").strip().lower();
    if key not in TIER_LIMITS {
        _trace("get_tier_limits", "tier=" + tier, "unknown plan");
        return "There is no plan called " + tier + ". The plans are free, builder and pro.";
    }
    lim = TIER_LIMITS[key];
    deploys = lim["deploy_count"] as int;
    deploy_txt = str(deploys) + " live deployment(s)";
    if deploys == 0 {
        deploy_txt = "0 live deployments -- deployment is NOT available on this plan at all, and the only way to get it is to move to a higher plan";
    }
    credits = int(round((lim["monthly_limit_usd"] as float) * CREDITS_PER_USD));
    _trace("get_tier_limits", "tier=" + key, str(lim["project_count"]) + " projects, " + str(deploys) + " deploys");
    return (
        "The " + key + " plan allows: "
        + str(lim["project_count"]) + " projects at once; "
        + deploy_txt + "; "
        + str(lim["sandbox_deploy_count"]) + " sandbox deployment(s); "
        + str(lim["preview_share_count"]) + " shareable preview link(s); "
        + "about " + str(credits) + " AI credits per month; "
        + "folder upload " + ("allowed" if lim["folder_upload_allowed"] else "not allowed") + "; "
        + "publishing to the community gallery " + ("allowed" if lim["community_submit_allowed"] else "not allowed") + "."
    );
}
sem get_tier_limits = "Return exactly what one plan permits: how many projects, live deployments, sandbox deployments and shareable preview links it allows, how many AI credits it includes per month, and whether folder upload and community publishing are switched on. These are the real numbers and the documentation does not contain them, so never guess a limit -- call this. An allowance of 0 means the feature is unavailable on that plan.";
sem get_tier_limits.tier = "The plan name, which must be one of free, builder or pro. If you do not already know the customer's plan, call get_customer first to find it out.";


def get_billing(email: str) -> str {
    c = _find_customer(email);
    if c is None {
        _trace("get_billing", "email=" + email, "not found");
        return "No customer on record with the email " + email + ".";
    }
    pays = [c ->:Billed:->];
    if len(pays) == 0 {
        _trace("get_billing", "email=" + email, "no payments");
        return c.name + " has no payments on record. They are on the " + c.tier + " plan, which is never charged.";
    }
    lines: list[str] = [];
    for p in pays {
        lines.append(p.date + ": $" + f"{p.amount_usd:.2f}" + " " + p.status + " (invoice " + p.invoice + ")");
    }
    _trace("get_billing", "email=" + email, str(len(pays)) + " payment(s), latest " + (pays[-1].status));
    return "Payment history for " + c.name + " (" + c.tier + " plan), oldest first:\n" + "\n".join(lines);
}
sem get_billing = "Return one customer's full payment history, oldest first: date, amount, status (paid, failed or refunded) and invoice number. Use this for any question about a charge, a card, an invoice, a refund, or whether a payment went through. The most recent entry is the last one listed.";
sem get_billing.email = "The customer's email address, exactly as written in the question.";


def get_projects(email: str) -> str {
    c = _find_customer(email);
    if c is None {
        _trace("get_projects", "email=" + email, "not found");
        return "No customer on record with the email " + email + ".";
    }
    projs = [c ->:Owns:->];
    if len(projs) == 0 {
        _trace("get_projects", "email=" + email, "0 projects");
        return c.name + " has not created any projects yet.";
    }
    lines: list[str] = [];
    for p in projs {
        deps = [p ->:Deployed:->];
        if len(deps) == 0 {
            lines.append(p.name + " (" + p.status + ", created " + p.created + ") -- not deployed");
        } else {
            for d in deps {
                lines.append(
                    p.name + " (" + p.status + ", created " + p.created + ") -- deployment "
                    + d.status + " at " + d.url + " as of " + d.date
                );
            }
        }
    }
    _trace("get_projects", "email=" + email, str(len(projs)) + " project(s)");
    return c.name + " has " + str(len(projs)) + " project(s) on the " + c.tier + " plan:\n" + "\n".join(lines);
}
sem get_projects = "List one customer's projects and, for each, whether it has a deployment and what state that deployment is in (live, building or failed). Use this to answer whether something of theirs is deployed or online, or how many projects they currently have. It reports how many projects they HAVE, not how many they are allowed -- get_tier_limits owns the allowance.";
sem get_projects.email = "The customer's email address, exactly as written in the question.";


def open_ticket(email: str, summary: str) -> str {
    ref = "TCK-" + str(1000 + len([root --> [?:Ticket]]));
    c = _find_customer(email);
    t = Ticket(email=email, summary=summary, created=_today());
    root ++> t;
    if c is not None {
        c +>:Raised:+> t;
    }
    _trace("open_ticket", "email=" + email + ", summary=" + summary, "created " + ref);
    return "Opened ticket " + ref + " for " + email + " on " + t.created + ": " + summary;
}
sem open_ticket = "Open a support ticket for a human to pick up, and return its reference number. This is the only tool that WRITES anything -- use it only when the operator asks for a ticket to be opened, or when the question genuinely needs a human (a billing dispute, suspected data loss, a limit that needs raising by hand). Never open a ticket for a question you have already answered from the other tools.";
sem open_ticket.email = "The email address of the customer the ticket is for.";
sem open_ticket.summary = "One neutral sentence stating what the customer needs and the key facts a human would need to act on it. No pleasantries.";


# ===========================================================================
# THE AGENT
#
# Six tools, one bodiless function. `tools=[...]` turns on the ReAct loop --
# there is no `method="ReAct"` to set and no loop to write. The model reads the
# sem of each tool, picks, calls, reads the result, and picks again.
#
# `sem ask` is the ONLY steering text in this project. It is not a prompt
# string being assembled at runtime -- it is compiled prompt wiring attached to
# the declaration. To change the agent's judgement, edit the sem.
# ===========================================================================

def ask(question: str) -> str by llm(
    tools=[search_docs, get_customer, get_tier_limits, get_billing, get_projects, open_ticket],
    temperature=0.2,
    max_react_iterations=6
);

sem ask = "You are the support agent for a web application-building platform, answering a support operator's question. Call only the tools the question actually needs, then stop. A general question about how the platform works, naming no customer, is answered from search_docs alone -- do not look anyone up. A question about a specific person starts with get_customer on their email. A question about whether a specific person is ALLOWED to do something needs two calls in that order: get_customer to learn which plan they are on, then get_tier_limits on that plan name to learn what it permits -- the plan name alone never tells you the limits, so never answer an allowance question from get_customer alone. Questions about a charge, card, invoice or refund need get_billing. Questions about someone's projects or whether their work is deployed or live need get_projects. Reach for open_ticket only when a ticket is asked for or a human is genuinely required. Never call the same tool twice with the same arguments -- you already have that result, so use it instead of asking again. Then answer the operator in two to four sentences of plain prose, stating the concrete facts the tools returned, including the actual numbers. Never invent a limit, price, date or status: if no tool told you, say you do not know.";
sem ask.question = "The support operator's question, in their own words. It may name a customer by email, ask about the platform in general, or both.";


# ===========================================================================
# Transport: what the client calls. Clears the trace, runs the agent, and
# returns the answer AND the trace, so the UI can show which tools ran.
# ===========================================================================

obj Answer {
    has ok: bool = False;
    has text: str = "";
    has trace: list[ToolCall] = [];
    has error: str = "";
}

glob _NO_KEY_HELP: str = (
    "No LLM credentials found. Set OPENAI_API_KEY in your environment and "
    "restart the server -- or run the bundled local model with no key at all: "
    "`jac install 'byllm[local]'`, then set default_model = \"local:gemma-4-e2b\" "
    "under [byllm.model] in jac.toml."
);

def:pub ask_support(question: str) -> Answer {
    if not question or not question.strip() {
        return Answer(error="Ask a question first.");
    }
    _ensure_seed();
    _TRACE.clear();
    try {
        text = ask(question.strip());
        return Answer(ok=True, text=text, trace=list(_TRACE));
    } except AuthenticationError {
        return Answer(error=_NO_KEY_HELP, trace=list(_TRACE));
    } except ByLLMError as e {
        return Answer(error="The model call failed: " + str(e), trace=list(_TRACE));
    }
}

"""The seeded desk, for the roster panel -- so you can see the data the agent
is reading. Nodes cross the wire hydrated, so the client gets real Customers."""
def:pub list_customers() -> list[Customer] {
    _ensure_seed();
    return [root --> [?:Customer]];
}
