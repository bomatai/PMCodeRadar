---
name: constraint-analysis
description: >
  Use this skill when engineering says something is "not possible", "can't be done", or "requires a full rewrite."
  Trigger on /constraint-analysis or when the user says things like
  "eng says we can't do this", "is this really impossible", "break down this technical constraint",
  "analyze why eng says no", "what are the alternatives", "unblock this feature",
  "constraint analysis", or "technical feasibility check."
  Also trigger when a PM mentions being blocked by an engineering objection or wants to challenge a technical limitation.
version: 1.0
---

# Technical Constraint Analyzer

> Level 1 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Eng says "not possible." You point Claude at the repo. It breaks down the constraint and scopes 3 alternatives. 4 minutes. One PM unblocked a feature that had been "impossible" for 6 weeks.

## What This Does

Analyzes a codebase to understand the real technical constraint behind an engineering objection. Breaks it down into what's actually hard, what's just unfamiliar, and what's a design choice masquerading as a limitation. Then scopes 3 alternative approaches with effort estimates so you walk into the next conversation with options, not opinions.

This isn't about catching eng in a lie. Most constraints are communicated honestly — engineers say "can't" when they mean "can't easily" or "can't without risk." The value here is separating the true blockers from the solvable problems, and finding the path of least resistance that everyone missed because nobody had time to look.

## When to Use This

- Eng says "we can't add X without a full rewrite"
- A feature has been stuck in "not possible" limbo for weeks
- You suspect the constraint is real but the conclusion ("therefore no") is premature
- You need alternatives to bring to an architecture review
- You want to understand the technical blocker before escalating
- A critical deadline is approaching and the team says the scope can't be met — you need to find a smaller scope that's technically viable
- You're in a cross-team negotiation where one team says "our system can't support your feature" and you need to understand their architecture well enough to propose a workable integration
- Someone said "that would take 6 months" and you want to understand if there's a 2-week version that unblocks the core use case
- You inherited a project and want to verify whether a constraint from the previous PM still holds

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path or module is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which directory to scan — just start scanning.

Clarify the scope:
- **Single constraint**: "Eng says X can't be done" — analyze the specific technical blocker
- **Multiple constraints**: "Eng says the whole feature is impossible" — break down each constraint separately, some may be hard while others are soft
- **Architecture-level**: "Eng says our architecture doesn't support this" — wider scan needed, look at service boundaries, data flow, and integration points

### Step 2: Constraint Analysis

1. **Read the relevant code** in the specified directory/module
2. **Identify the actual constraint**: Is it architectural? A dependency? A data model limitation? A performance concern?
3. **Classify the constraint**:
   - **Hard constraint**: Fundamental limitation (e.g., database doesn't support this data type)
   - **Soft constraint**: Design choice that could be changed (e.g., service was built assuming single-tenant)
   - **Perceived constraint**: Unfamiliarity or risk aversion (e.g., "we've never done it that way")

4. **Deep scan the constraint surface** — dig into the specifics:
   - **Data model rigidity** — is the schema locked in a way that blocks the feature? Are there foreign key constraints, enum types, or column types that would need migration?
   - **API contract dependencies** — does an external or internal API enforce a shape that doesn't support the new requirement? Is there versioning or is it all-or-nothing?
   - **Authentication/authorization boundaries** — is the constraint about what the system allows, or what the auth layer allows? These are different problems with different fix costs
   - **Third-party SDK limitations** — is the "can't be done" actually "Stripe/Twilio/AWS doesn't support this"? Check the SDK version — sometimes the limitation was fixed two versions ago
   - **Performance ceilings** — is the concern about scale? What's the actual threshold? "It won't scale" is meaningless without a number. Find the number
   - **Concurrency and race conditions** — is the constraint about what happens when two things happen at once? These are real but often solvable with queues, locks, or idempotency
   - **Migration risk** — is the real blocker not the code change itself but the data migration required to support it? How many rows? What's the downtime window?
   - **Test coverage gaps** — is eng saying "can't" because changing this code has zero tests and they're scared of regressions? That's not a constraint, that's a confidence problem
   - **Circular dependencies** — does module A depend on module B which depends on module A? This makes changes feel impossible because touching one thing touches everything
   - **Framework limitations** — is the constraint baked into the framework itself (e.g., Next.js can't do X) or is it how the team chose to use the framework?
   - **Deployment pipeline constraints** — is the blocker about the code or about how it gets deployed? Feature flags, blue-green deploys, and canary releases can unlock things that seem impossible in a big-bang deploy
   - **Internationalization/localization constraints** — is the constraint about character encoding, RTL layout support, locale-specific formatting, or translation pipeline integration? These feel architectural but are often solvable with targeted changes
   - **Rate limit/quota constraints from external APIs** — is the "can't be done" actually "can't be done at our current API tier"? Check rate limits, quota ceilings, and whether upgrading the plan or batching requests removes the constraint entirely

### Step 3: Generate Alternatives

For each constraint found, generate 3 alternative approaches:
- **Option A**: Minimal change — work within the current architecture. This is the "ship something this sprint" option. It might be hacky. It might not scale. But it unblocks the feature now and buys time to do it right later. Be honest about the trade-offs
- **Option B**: Moderate change — refactor the specific bottleneck. This is the "do it properly but scoped" option. Address the root cause of this specific constraint without redesigning the whole system. Usually 2-4x the effort of Option A but doesn't accumulate debt
- **Option C**: Strategic change — redesign for long-term flexibility. This is the "if we're going to touch this, let's set ourselves up for the next 3 features too" option. Higher effort upfront, but eliminates the constraint class entirely. Only worth it if you know more features will hit the same wall

Each option includes:
- What specifically changes (files, modules, data model, API contracts)
- Estimated effort (days/weeks) — broken into implementation + testing + migration if applicable
- Risk level with specific risk description (not just "medium" — what actually could go wrong)
- What it unblocks — both the immediate feature and any downstream capabilities
- What it doesn't solve — be explicit about what remains constrained even after this option
- Rollback complexity — can you undo this if it goes wrong?

### Step 4: Output

Present findings using progressive disclosure:

**Summary** (always shown first):
- The real constraint in one sentence — no jargon, a PM should be able to read this to their VP
- Constraint classification: `[HARD]` fundamental blocker that requires architectural change, `[SOFT]` design choice that can be changed with targeted effort, `[PERCEIVED]` not actually a technical limitation
- Severity tag: `[CRITICAL]` (fundamental blocker), `[WARNING]` (real but workable), `[INFO]` (perceived, not actual)
- 3 alternatives with effort estimates and a one-line trade-off for each
- Recommendation: which option to pursue and why, given the constraints of time, risk, and long-term value

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Constraint | Type | Location | Impact | Alternative | Effort |
|-----------|------|----------|--------|-------------|--------|
| Single-tenant DB schema | Hard | schema.sql:12 | Blocks multi-org support entirely | A: Tenant column + row-level security | 2 weeks |
| Synchronous payment flow | Soft | payments.js:89 | Can't add Apple Pay (requires async) | B: Extract to async handler with webhook | 4 days |
| Monolith auth module | Soft | auth.js:1-400 | Every auth change risks breaking all flows | B: Extract auth into standalone service | 3 weeks |
| "We've never done WebSockets" | Perceived | — | Team assumes real-time requires rewrite | A: Use SSE with existing HTTP stack | 2 days |
| No feature flag infrastructure | Soft | config.js:15 | Can't ship incrementally, big-bang only | A: Add LaunchDarkly/Unleash, wrap new code | 3 days |

**Alternative Comparison Matrix**:

| | Option A (Minimal) | Option B (Moderate) | Option C (Strategic) |
|---|---|---|---|
| Effort | [X days] | [Y days] | [Z weeks] |
| Risk | Low — works within existing arch | Medium — targeted refactor | High — architectural change |
| What it unblocks | [Immediate feature only] | [Feature + 1-2 adjacent needs] | [Feature class — all similar requests] |
| What it doesn't solve | [Remaining limitations] | [Remaining limitations] | [Minimal — addresses root cause] |
| Rollback complexity | Easy — revert one PR | Moderate — revert + data migration | Hard — requires forward-fix if issues |
| Recommended when | Deadline is < 2 weeks | Deadline is 1-2 months | This constraint will recur 3+ times |

**Share-Ready Snippet**:

> Hey [eng lead], I dug into the [feature] constraint. The core issue is [one sentence — e.g., "the payment handler is synchronous and Apple Pay requires an async callback flow"].
>
> The constraint is [hard/soft/perceived]. Here's what I found:
>
> 1. [Option A] — ~[effort], minimal change. [One sentence on what it does and what it unblocks]
> 2. [Option B] — ~[effort], addresses the root cause. [One sentence on the refactor and long-term benefit]
> 3. [Option C] — ~[effort], sets us up long-term. [One sentence on the strategic investment]
>
> My read: Option [X] gives us the best trade-off between speed and future flexibility. Can we walk through these in our next sync? I want to find the right approach together — not prescribe one.

### Step 5: Next Steps

Suggest related skills:
- "Run `/architecture-map` to see the full dependency chain this constraint touches — useful if the constraint affects multiple services"
- "Run `/pre-ship-scan` once you pick an approach to check what else it affects before you ship the change"
- "Run `/debt-cost-estimate` if the constraint is caused by accumulated tech debt — quantify the cost to make the case for addressing it"
- "Run `/dependency-map` to see what other modules depend on the constrained code — this tells you the blast radius of each option"

## Sample Usage

```
Point Claude at /src/payments/ and say: "Eng says we can't add Apple Pay
without a full rewrite. Break down the actual constraint and give me
3 alternatives with effort estimates."
```

**More examples:**

```
"The auth team says adding SSO will take 6 months. Analyze /src/auth/ and
tell me what's actually blocking this and what the alternatives are."
```

```
"We were told real-time notifications aren't possible with our current
architecture. Look at /src/notifications/ and break down why."
```

```
"The platform team says adding multi-tenancy is a 6-month project. Analyze
/src/core/ and /src/db/ — I need to know if the constraint is the data model,
the auth layer, or both, and what the minimal viable path looks like."
```

```
"Engineering quoted 3 months for the API versioning work. I want to understand
if there's a lighter-weight approach. Check /src/api/ and show me what's
actually coupled to the current response format."
```

## Tips

- Point at the specific directory, not the whole repo. Constraints live in specific modules. Scanning everything dilutes the analysis.
- Bring the output to eng as "here's what I found, help me understand if I'm reading this right" — not "Claude says you're wrong." Collaboration beats confrontation.
- The best outcome isn't proving eng wrong. It's finding an alternative nobody considered.
- Pay attention to the constraint classification. If 3 out of 4 constraints are "perceived," the real blocker isn't technical — it's team confidence or knowledge gaps. That changes the solution from "code change" to "spike/prototype."
- When you get the output, read the effort estimates with skepticism. They're directional, not commitments. Use them to compare options against each other, not as sprint planning inputs.
- If multiple constraints are stacked (e.g., "we can't do X because of A, and even if we fixed A, there's B"), get the full chain. Fixing one constraint only to hit the next one is demoralizing. Map the complete path to "unblocked" before committing to an approach.
- A "perceived" constraint isn't an insult to eng. It usually means the team hasn't had time to explore the possibility. The spike or prototype that proves it's doable can be more valuable than weeks of architecture debate.
- Run this before committing to a workaround. Too many teams build around a constraint that could have been addressed directly in less time than the workaround took. The analysis pays for itself if it prevents even one unnecessary detour.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
