---
name: debt-cost-estimate
description: >
  Use this skill to translate tech debt into product cost that stakeholders actually understand.
  Trigger on /debt-cost-estimate or when the user says things like
  "what does this tech debt cost us", "translate tech debt to business impact",
  "how much is tech debt slowing us down", "tech debt roadmap argument",
  "quantify technical debt", "debt cost analysis", or "make the case for paying down debt."
  Also trigger when a PM needs ammunition for a roadmap review where tech debt is being deprioritized.
version: 1.0
---

# Tech Debt Cost Estimator

> Level 1 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Tech debt came up in the roadmap review. Everyone nodded. Nothing changed. This skill reads the actual debt and translates it to product impact. "This billing feature takes 3x longer next quarter." That's a position. Not a nod.

## What This Does

Scans a codebase module for technical debt indicators — duplicated logic, outdated patterns, brittle dependencies, missing abstractions — and translates each one into product cost. Not "this code is messy." Instead: "This handler adds 3 days to every payment feature next quarter." Numbers. Timelines. Impact. The language roadmap reviews actually respond to.

The key insight: tech debt isn't one thing. Some debt blocks features. Some debt slows velocity. Some debt creates risk. Some debt compounds every sprint. This skill categorizes each item so you can prioritize by what hurts most, not what's easiest to fix.

## When to Use This

- Tech debt keeps getting deprioritized because nobody can quantify it
- You need a concrete argument for a cleanup sprint
- Eng is frustrated but can't articulate the cost in product terms
- A roadmap review is coming and you want to make a real case
- You're inheriting a codebase and need to understand what's expensive
- Leadership is asking "why are estimates so high?" and you suspect accumulated debt is the answer but need proof
- You're planning next quarter and need to decide between new features and cleanup — this gives you the data to make that trade-off honestly
- The team keeps missing estimates on a specific module and you want to understand if debt is the hidden tax
- You're negotiating headcount and need to show current team capacity consumed by debt maintenance vs feature work

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path or module is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which module to scan — just start scanning.

Clarify the goal:
- **Roadmap argument**: Focus on debt that directly blocks planned features — lead with opportunity cost
- **Velocity recovery**: Focus on debt that slows every feature in the module — lead with velocity tax percentage
- **Risk reduction**: Focus on debt that creates production incidents — lead with incident cost and failure modes
- **Full inventory**: Scan everything and prioritize by ROI — for quarterly planning or cleanup sprint scoping

### Step 2: Debt Detection

Scan the target for:
- **Duplicated logic** — same thing implemented in multiple places. Not just copy-paste functions — look for the same business rule expressed differently in two handlers. That's the kind of duplication that causes "we fixed it in checkout but not in billing" bugs
- **Dead code** — functions/routes that exist but aren't called. Every dead function still gets read by new engineers trying to understand the module. That's onboarding cost hiding as code
- **Hardcoded values** — magic numbers, hardcoded URLs, config buried in code. The pricing module with `0.029` scattered across 8 files means changing the processing fee requires 8 changes and a prayer
- **Missing abstractions** — repeated patterns that should be a shared utility. When 4 different endpoints all build the same response shape manually, the next endpoint will too, and it'll get it slightly wrong
- **Outdated dependencies** — libraries with known issues or EOL. Check for major version gaps, security advisories, and packages that haven't been updated in 18+ months
- **Brittle coupling** — components that break each other when changed. The classic tell: changing a function signature in module A requires updating 12 files across 4 directories
- **Missing tests** — critical paths with no test coverage. Not "test coverage is 60%." Specifically: which user-facing flows have zero test coverage? Those are the ones that break silently
- **Inconsistent error handling** — some functions throw, some return null, some swallow errors silently. This means the same failure shows as a crash in one flow and a silent data loss in another
- **God objects/modules** — files over 500 lines that do everything. These attract more code because devs add to the existing file instead of creating a proper abstraction. They grow until nobody wants to touch them
- **Schema drift** — database columns or API fields that exist but don't match the current data model. Renamed in code but not in the DB. Nullable in the schema but required in the UI. These cause intermittent bugs that are brutal to diagnose
- **Configuration sprawl** — environment variables, config files, and settings scattered across multiple locations with no single source of truth. Devs don't know which config wins, so they hardcode values to be safe
- **Retry/timeout debt** — missing or inconsistent retry logic, hardcoded timeouts, no circuit breakers. This is invisible until traffic spikes, then everything cascades
- **Logging/observability debt** — inconsistent structured logging, missing correlation IDs, log levels used arbitrarily, no standard log format across services. When an incident happens, you spend more time finding the right logs than fixing the issue
- **CI/build pipeline debt** — slow builds, flaky tests, manual deploy steps, missing caching, no parallelization. If your CI takes 45 minutes and 1 in 5 runs fails on a flaky test, every engineer is losing hours per week waiting and re-running

### Step 3: Cost Translation

For each debt item, translate to product impact using language that resonates in a roadmap review:

- **Velocity cost**: "Every new feature in this module takes X extra days because of Y." Be specific — not "it's slow" but "the duplicated auth logic means every auth-touching feature requires changes in 3 files instead of 1, adding ~2 days per feature"
- **Risk cost**: "This brittle coupling means changing Z has a 30% chance of breaking W." Quantify the blast radius — how many other modules does a change here ripple through?
- **Opportunity cost**: "We can't build [desired feature] until this is addressed." Connect debt to specific roadmap items that stakeholders care about. "Tiered pricing is blocked by hardcoded values in 8 files" hits harder than "hardcoded values are bad practice"
- **Incident cost**: "This pattern has caused N incidents in codebases like this." If there's no retry logic, no circuit breaker, no graceful degradation — estimate the failure mode and its frequency under realistic conditions
- **Onboarding cost**: "New engineers spend X days understanding this module because of dead code, inconsistent patterns, and undocumented workarounds." This is invisible but real — especially if you're scaling the team
- **Compounding cost**: "Every sprint we don't address this, the debt grows by approximately X because new features add to the existing mess." Some debt compounds. A god object attracts more code. Missing abstractions mean more duplication. Quantify the trajectory, not just the current state

For each cost, assign a severity:
- `[CRITICAL]` — blocks a roadmap item or creates production risk
- `[WARNING]` — slows velocity or creates ongoing maintenance burden
- `[INFO]` — suboptimal but not actively hurting

### Step 4: Output

**Summary** (always shown first):
- Total debt items found with severity breakdown: [N] critical, [N] warning, [N] info
- Top 3 highest-cost items with one-line impact statements — these are the ones to lead with in the roadmap review
- Estimated velocity tax: "This module is approximately X% slower to ship in than it should be"
- Quick wins: debt items that can be fixed in < 1 day with high ROI — these are your "prove the cleanup sprint is worth it" items
- Roadmap blockers: debt items that directly prevent specific planned features from shipping
- Compounding items: debt that's getting worse every sprint if left unaddressed

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Debt Item | Severity | Location | Product Cost | Fix Effort | ROI |
|-----------|----------|----------|-------------|------------|-----|
| Duplicated auth logic | `[WARNING]` | auth.js:45, api.js:120 | +2 days per auth feature | 3 days | High |
| Hardcoded pricing tiers | `[CRITICAL]` | billing.js:89 | Blocks tiered pricing launch | 1 day | Very High |
| God object: OrderService | `[WARNING]` | order.js:1-680 | Every order change risks regression, +1 day testing | 5 days | High |
| No retry logic on payment calls | `[CRITICAL]` | stripe.js:34 | Silent payment failures under load, revenue loss | 1 day | Very High |
| 14 unused deps in package.json | `[INFO]` | package.json | +40s install time, 3 known CVEs in unused packages | 2 hours | Medium |
| Inconsistent error formats | `[WARNING]` | api/*.js | Frontend team guesses error shapes, +1 day per feature | 3 days | High |
| Schema drift: user.plan_id | `[WARNING]` | users table, user.js:45 | Nullable in DB, required in UI — intermittent 500s | 1 day | High |

**Debt Priority Matrix**:

| Priority | Debt Item | Fix Effort | Quarterly Cost if Ignored | ROI | Action |
|----------|-----------|-----------|--------------------------|-----|--------|
| 1 | Hardcoded pricing tiers | 1 day | Blocks $[X] revenue feature | Very High | Fix this sprint |
| 2 | No retry on payments | 1 day | ~[N] silent failures/month, est. $[X] revenue | Very High | Fix this sprint |
| 3 | Duplicated auth logic | 3 days | +2 days per auth feature (~8 features/quarter = 16 days) | High | Next cleanup sprint |
| 4 | God object OrderService | 5 days | +1 day testing per order feature, regression risk | High | Schedule for next quarter |
| 5 | Schema drift user.plan_id | 1 day | Intermittent 500s, ~[N] incidents/quarter | High | Fix this sprint |

**Share-Ready Snippet**:

> Team, I analyzed the tech debt in [module]. Here's what it's costing us in real product terms:
>
> **Velocity cost**: Every feature touching [area] takes ~[X] extra days because of [specific debt item]. That's [N] extra engineering days per quarter at our current shipping pace.
>
> **Risk cost**: [Specific debt item] has no retry logic / no tests / brittle coupling — this creates [specific failure mode] under [condition].
>
> **Opportunity cost**: We can't build [desired capability] until [specific debt item] is addressed. This has been on the roadmap for [N] quarters.
>
> Top items:
> - [Top item 1]: adds ~[X days] to every feature touching [area]
> - [Top item 2]: blocks [desired capability] entirely
> - [Top item 3]: creates [risk] every time we deploy
>
> A focused [X-day] cleanup sprint would recover ~[Y%] velocity. Proposed timeline: [specific sprint/quarter]. The ROI is clear — we spend [X days] now to save [Y days] over the next two quarters.

### Step 5: Next Steps

- "Run `/dead-code-audit` to find unused code you can remove immediately — the quickest wins in any cleanup sprint"
- "Run `/architecture-map` to see how this debt ripples through the system — some debt is local, some infects everything downstream"
- "Run `/constraint-analysis` if a specific debt item is blocking a feature — break down the constraint and find alternatives"
- "Run `/pre-ship-scan` before the cleanup sprint ships to make sure the fixes don't introduce new conflicts"

## Sample Usage

```
"Scan the billing module for tech debt. For each item, translate it into
product cost: what slows down, what breaks, what takes longer next quarter.
Give me a table I can bring to the roadmap review."
```

**More examples:**

```
"I'm making the case for a cleanup sprint. Analyze /src/api/ and tell me
exactly how much this debt is costing us in shipping speed."
```

```
"We keep missing deadlines on the checkout flow. Is tech debt the reason?
Scan /src/checkout/ and show me."
```

```
"I'm inheriting the notifications service from another PM. Before I plan
anything new, scan /src/notifications/ and tell me what tech debt I'm
inheriting and how much it'll slow down my first feature."
```

```
"Leadership wants to know why the API team keeps missing estimates. I think
it's accumulated debt. Scan /src/api/ and give me a cost breakdown I can
present at the leadership review — no jargon, just impact."
```

## Tips

- Run this before a roadmap review, not during. You want the numbers ready, not the conversation.
- Focus on one module at a time. "The whole codebase has debt" isn't actionable. "The billing module costs us 2 extra days per feature" is.
- Pair this with `/dead-code-audit` for quick wins you can ship immediately.
- The ROI column is your secret weapon. Leadership doesn't care about "code quality." They care about "spend 3 days now, save 20 days over the next two quarters." Frame every debt item as an investment with a return.
- Don't present every debt item. Pick the top 3-5 with the highest ROI and present those. A 40-item debt list paralyzes people. A 5-item list with clear costs and fix efforts gets action.
- Track debt cost over time. Run this scan once a quarter on the same module. If the velocity tax goes from 15% to 22%, that's a trend line you can show leadership. "The debt is getting worse, not better" is more persuasive than any single snapshot.
- Separate "debt that blocks" from "debt that slows." Blockers get fixed because they're visible. The slow-down debt is sneakier — it never causes an outage, it just makes every feature take an extra day. Quantify the compound cost per quarter to make it visible.
- When presenting to leadership, lead with the opportunity cost (what you can't build) rather than the velocity cost (what takes longer). "We can't ship tiered pricing until we fix this" gets budget. "It takes 2 extra days per feature" gets a nod.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
