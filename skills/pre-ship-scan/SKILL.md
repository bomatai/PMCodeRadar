---
name: pre-ship-scan
description: >
  Use this skill before shipping any release to catch breaking conflicts before they hit production.
  Trigger on /pre-ship-scan or when the user says things like
  "scan before we ship", "what could break if we deploy this", "pre-release check",
  "impact analysis before shipping", "will this break anything", "release readiness scan",
  "pre-ship impact check", or "what are we about to break."
  Also trigger when a PM mentions an upcoming release, deploy, or launch and wants to de-risk it.
version: 1.0
---

# Pre-Ship Impact Scanner

> Level 1 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Shipped Friday. Bug reports Saturday. Post-mortem Monday. What if Monday never happened? This skill maps proposed changes against every existing flow and flags what breaks. One team ran this on 4 releases straight. Caught a breaking conflict on the third. That's a post-mortem that never happened.

## What This Does

Takes a proposed change (new feature, refactor, migration) and maps it against every existing user flow that touches the same code paths. Finds conflicts, breaking changes, and edge cases that manual review misses. The goal: catch the bug before it ships, not after.

This is the tool that turns "I hope nothing breaks" into "here's exactly what's at risk and what we need to fix first." Manual code review catches syntax issues and logic errors. This catches the cross-cutting conflicts that live in the spaces between modules — the ones nobody owns and nobody reviews until production breaks.

## When to Use This

- You're about to ship a new feature and want to know what it might break
- A refactor is going out and you need to verify it doesn't affect existing flows
- You've had incidents from shipping without full impact analysis
- Release day is approaching and you want a confidence check
- Multiple teams are shipping to the same area of the codebase
- A database migration is part of the release and you need to understand the blast radius
- You're shipping a change to a shared service (auth, payments, notifications) that other teams depend on
- The change touches an API that mobile clients, partner integrations, or third-party consumers rely on — you need to know if you're about to break their code, not just yours
- You're shipping a hotfix for a production incident and need to verify the fix doesn't break something else under pressure

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path or change is specified, auto-detect the project root from the current working directory and scan from there. Check recent git changes (e.g., `git diff`, `git log`) to identify what's about to ship, then map those changes against existing flows. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user what's about to ship — just detect the recent changes and start scanning.

Clarify the change type — different changes have different risk profiles:
- **New feature**: What existing flows share code paths with the new code? Focus on data and state conflicts
- **Refactor**: What existing behavior is assumed to stay the same? Focus on logic and contract conflicts
- **Migration**: What's the rollback plan if something goes wrong? Focus on data integrity and timing conflicts
- **Dependency update**: What APIs changed between versions? Focus on breaking changes in third-party code
- **Multi-team change**: Are multiple teams shipping to the same area? Focus on merge conflicts and assumption mismatches

### Step 2: Change Mapping

1. **Identify the changed code** — what files are new or modified. Include new functions, changed function signatures, altered return types, and modified data structures
2. **Trace dependencies** — what existing code imports, calls, or depends on the changed files. Follow the chain: direct importers, their importers, and so on until you've mapped the full ripple zone
3. **Map user flows** — which user-facing flows pass through the changed code. A flow is a complete user action: "user adds item to cart," "user resets password," "admin exports report." Map the change against each flow end-to-end
4. **Find conflicts** — where the change contradicts assumptions in existing code. Look for implicit contracts: functions that assume a certain return shape, components that assume a certain state structure, integrations that assume a certain event format
5. **Assess rollback safety** — if this deploy fails, can it be rolled back cleanly? Irreversible migrations, data transformations, and external notifications that can't be unsent all limit your rollback options

### Step 3: Conflict Detection

For each existing flow that intersects with the change, scan for:

- **Data conflicts** — does the change alter data structures other flows depend on? Renamed fields, changed types, new required properties, altered validation rules. A renamed field in one service is a null pointer in every downstream consumer
- **Logic conflicts** — does the change alter behavior other flows assume? A function that used to return `null` on failure now throws an exception. Every caller that checked `if (result === null)` is now broken
- **Timing conflicts** — does the change affect async operations or event ordering? Adding an `await` to a previously synchronous path, changing the order webhooks fire, or modifying queue processing order. These bugs only show up under load
- **State conflicts** — does the change modify shared state other flows read? Global stores, session data, cached values, database rows that multiple services read. One flow writes the new shape, another flow reads the old shape, data corruption follows
- **Contract conflicts** — does the change alter an API response shape, HTTP status code, or error format that external consumers depend on? Mobile clients still on v2.1 won't know about your new required field
- **Permission conflicts** — does the change add or modify auth checks that affect who can access existing flows? Tightening permissions on a shared endpoint might lock out a legitimate integration
- **Migration conflicts** — does the change require a database migration that could lock tables or cause downtime during the deploy window? Large table migrations on production are the silent killer of Friday deploys
- **Event ordering conflicts** — does the change alter when events fire relative to each other? If analytics events fire before the state updates, your dashboards will show stale data
- **Cache invalidation conflicts** — does the change modify data that's cached elsewhere? The cache still serves the old shape for its TTL. Every request during that window gets stale or broken data
- **Feature flag conflicts** — does the change interact with existing feature flags? A new feature that only works when an old flag is ON, but that flag was scheduled for removal next sprint
- **Rollback conflicts** — if this deploy fails and you need to roll back, does the change include an irreversible database migration or data transformation? No rollback path means the failure mode is "forward only"
- **Environment/config conflicts** — does the change depend on environment variables, config values, or infrastructure settings that differ between staging and production? A change that works perfectly in staging but breaks in production because of a missing env var, a different database connection pool size, or a stricter firewall rule is one of the most common deploy surprises

### Step 4: Output

**Summary** (always shown first):
- `[CRITICAL]` Conflicts that would break existing flows — data corruption, payment failures, auth bypasses. These are ship-blockers. Do not deploy until resolved
- `[CRITICAL]` Irreversible changes — migrations with no rollback path, data transformations that can't be undone. If the deploy fails, you're stuck going forward
- `[WARNING]` Potential timing/state issues — race conditions under load, cache staleness windows, event ordering changes. Won't break in testing, will break at scale or under specific conditions
- `[WARNING]` Contract changes affecting external consumers — mobile clients, third-party integrations, partner APIs that expect the old shape. These won't crash your app but will crash theirs
- `[INFO]` Flows affected but not broken — downstream flows that touch the same code but whose behavior doesn't change. Documented for awareness, not action
- `[INFO]` Feature flag interactions — new code that depends on or conflicts with existing flags. Worth reviewing, not blocking
- Ship/No-ship recommendation with specific conditions (e.g., "Ship after fixing the 2 critical items. Warnings can be addressed in a follow-up PR")

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Affected Flow | Conflict Type | Severity | Location | What Breaks | Fix |
|--------------|--------------|----------|----------|-------------|-----|
| Checkout > Payment | Data conflict | `[CRITICAL]` | cart.js:89 | Cart total calculation returns NaN with new discount field | Update cart schema to handle null discount |
| Order confirmation email | Timing conflict | `[WARNING]` | email.js:23 | Email fires before order state saves — shows "pending" not "confirmed" | Add await before email dispatch |
| Webhook to partner API | Contract conflict | `[CRITICAL]` | webhook.js:156 | Partner expects `amount_cents`, new code sends `amount` as float | Add backwards-compatible field or version the webhook |
| Analytics dashboard | State conflict | `[WARNING]` | analytics.js:78 | Dashboard reads cached order count, new flow invalidates cache differently | Align cache invalidation keys |
| Mobile app v2.3 | Contract conflict | `[WARNING]` | api/orders.js:34 | Mobile client parses `status` as enum, new code adds unknown value | Gate new status behind API version check |
| Inventory sync job | Timing conflict | `[INFO]` | inventory.js:201 | Cron job reads order table during migration window — stale read possible | Document deploy timing, run job after migration |

**Deploy Risk Assessment**:

| Risk Factor | Status | Detail |
|-------------|--------|--------|
| Rollback safety | `[CRITICAL]` or `[OK]` | Can this deploy be cleanly rolled back? Any irreversible migrations? |
| External consumer impact | `[WARNING]` or `[OK]` | Do mobile clients, partner APIs, or webhooks depend on changed contracts? |
| Data integrity | `[CRITICAL]` or `[OK]` | Could the change corrupt, lose, or expose user data during the transition? |
| Cache coherence | `[WARNING]` or `[OK]` | Will cached data become stale or structurally incompatible during rollout? |
| Feature flag safety | `[INFO]` or `[OK]` | Does the change interact with existing flags? Any flag removal conflicts? |
| Deploy timing | `[WARNING]` or `[OK]` | Are there windows to avoid? (migration lock time, peak traffic, cron job overlap) |

**Share-Ready Snippet**:

> Before we ship [feature], I ran an impact scan against every existing flow that touches the same code paths. Here's the picture:
>
> **Ship-blockers** ([N] critical):
> - [Specific conflict 1]: [one-line impact — e.g., "cart total returns NaN when new discount field is null"]
> - [Specific conflict 2]: [one-line impact — e.g., "partner webhook breaks because field name changed"]
>
> **Review before deploy** ([N] warnings):
> - [Specific warning 1]: [one-line description — e.g., "confirmation email fires before order state saves"]
> - [Specific warning 2]: [one-line description — e.g., "mobile app v2.3 can't parse new status enum value"]
>
> **Awareness only** ([N] info):
> - [N] flows touch the same paths but aren't affected by the change
>
> Recommendation: Fix the [N] critical items before deploy. Warnings can ship with a follow-up ticket. Deploy window should avoid [specific timing concern if applicable].

### Step 5: Next Steps

- "Run `/constraint-analysis` if the scan found a hard constraint blocking release — break down whether it's a true blocker or a solvable problem, and scope alternatives before deciding to delay the ship"
- "Run `/route-audit` to see the full navigation map and verify no dead ends were created by the change"
- "Run `/notification-audit` if the change affects user-facing alerts, emails, or webhooks"
- "Run `/error-audit` to verify the change handles failure cases correctly — new code often has happy-path-only error handling"
- "Run `/event-inventory` to check if the change affects analytics events — a renamed event or altered payload breaks dashboards silently"

## Sample Usage

```
"We're about to ship the new checkout flow in /src/checkout/. Map it against
every existing user flow that touches cart, payment, and order confirmation.
Flag anything that breaks."
```

**More examples:**

```
"We're deploying a new user roles system tomorrow. Scan /src/auth/ against
every flow that checks permissions. What breaks?"
```

```
"The pricing refactor is ready. Before we merge, check what other services
depend on the old pricing logic in /src/billing/."
```

```
"We're migrating from Stripe to a new payment provider. Before the cutover,
scan /src/payments/ and /src/billing/ against every flow that processes money.
I need a zero-surprise deploy."
```

```
"Three teams are shipping to /src/dashboard/ this sprint. Scan all the pending
changes and tell me if any of them conflict with each other. I'd rather know
now than in the post-mortem."
```

## Tips

- Run this early enough to act on the findings. Friday afternoon is too late. Wednesday gives you two days to fix the critical items. Share the results with eng as "here's what I want to double-check" not "here's what you missed." Same information, completely different reception.
- If you run this on every release, you'll build a reputation as the PM who catches things. That reputation compounds.
- Pay special attention to the `[CRITICAL]` vs `[WARNING]` distinction. Criticals are ship-blockers — the deploy should not happen until they're resolved. Warnings are "ship with eyes open" — document them, file follow-up tickets, but don't hold the release.
- The "rollback conflict" finding is the scariest one. If a deploy includes an irreversible migration and a critical bug, your only option is to fix forward under pressure. Know this before you deploy, not after.
- When multiple teams ship to the same area, run this scan against ALL pending changes combined, not each one individually. Two changes that are each safe alone can conflict with each other. The merge is where the bugs live.
- If the scan comes back clean, that's valuable too. "Zero conflicts found across 12 existing flows" is the kind of confidence that makes Friday deploys possible. Share the clean scan with the team — it builds trust in the process.
- Time this right: run the scan after code review but before the final merge. Running it too early means the code might change. Running it after merge means the conflicts are already in production. The sweet spot is the last review before the deploy button.
- Log scan results in your release notes or deploy log and share the habit with other PMs. When every PM runs a pre-ship scan, the team's incident rate drops. When a future incident happens, you can reference past scans to identify patterns — "we keep missing timing conflicts, let's add that to our standard review checklist."
- For high-stakes deploys (payment changes, auth changes, data migrations), consider running the scan twice: once early in the sprint to shape the implementation, and once before deploy to catch anything that changed during development. The cost is 8 minutes. The value is avoiding a weekend incident.
- A clean scan isn't a guarantee — it's a confidence level. The scan catches code-level conflicts but not infrastructure issues, config mismatches, or problems that only appear with real traffic. Use it as one layer of defense, not the only layer. That said, celebrate clean scans — acknowledge them in standup and the team builds trust in the process, which makes eng more receptive when the scan does find something.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
