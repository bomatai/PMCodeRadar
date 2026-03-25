---
name: dead-code-audit
description: >
  Use this skill to find dead routes, unused endpoints, and features nobody uses anymore.
  Trigger on /dead-code-audit or when the user says things like
  "find dead code", "what features are unused", "cleanup audit", "find unused endpoints",
  "what can we remove", "free up eng capacity", "dead feature audit", "unused code scan",
  or "what are we maintaining that nobody uses."
  Also trigger when a PM wants to free up engineering capacity or plan a cleanup sprint.
version: 1.0
---

# Dead Code & Feature Audit

> Level 1 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Your eng team is stretched. But 15% of their capacity is maintaining features nobody uses. Dead routes. Unused endpoints. Features nobody's called in months - listed, with the eng cost of each. One PM freed 15% of eng capacity in a single cleanup sprint.

## What This Does

Scans the codebase for dead code: routes nobody hits, API endpoints nothing calls, functions that exist but aren't imported anywhere, and features that are technically live but effectively abandoned. Outputs a cleanup hit list with the eng effort each dead item is silently consuming.

Dead code is the quietest form of waste. It doesn't cause incidents. It doesn't block features. It just sits there, getting read during onboarding, maintained during refactors, tested during CI, and scanned during security audits. The cost is invisible until you add it up — and then it's 10-20% of your team's capacity going to code that serves zero users.

## When to Use This

- Eng is "at capacity" but you suspect waste
- You're planning a cleanup sprint and need a target list
- You want to simplify the product before adding new features
- A new PM joined and needs to know what's alive vs. dead
- You're auditing before a major refactor
- Security flagged unused dependencies with known CVEs and you need the full scope of dead surface area
- Test suite is slow and you suspect a chunk of it is testing dead code — false coverage inflating your metrics
- You're preparing for a compliance audit and need to reduce the codebase to only what's actively serving users
- You're sunsetting a product or feature and want to identify all related code paths before removal

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which directory to scan — just start scanning.

Clarify the focus:
- **Capacity recovery**: Focus on dead items with the highest maintenance cost — tests, CI time, dependencies that need updating
- **Security cleanup**: Focus on dead endpoints that still respond to requests and unused dependencies with known CVEs
- **Onboarding prep**: Focus on dead code that new engineers will encounter and waste time trying to understand
- **Pre-refactor audit**: Focus on dead code in the area you're about to refactor — remove it first so the refactor scope is smaller and cleaner

### Step 2: Dead Code Detection

Scan for:
- **Dead routes** — URL paths defined but never linked to or navigated to. These are the ghost pages users sometimes stumble onto via browser autocomplete or old bookmarks. They exist. They render. Nobody intended them to
- **Unused API endpoints** — endpoints defined but not called by any client. The frontend moved on but the backend didn't. Every unused endpoint is still a surface area for security scanning and a line item in API docs nobody should be reading
- **Orphan functions** — exported functions that nothing imports. Trace every export: if nothing in the codebase imports it and it's not in the public API contract, it's dead. Someone wrote it for a feature that got cut, and the function outlived the feature
- **Commented-out code** — blocks of code someone commented instead of deleting. This is not a backup strategy, it's clutter. Git remembers everything. Commented code just confuses the next engineer who wonders "should I uncomment this?"
- **Stale feature flags** — flags that are permanently on or off. A flag that's been `true` for 6 months is not a flag, it's dead conditional logic wrapping production code. A flag that's been `false` for 6 months is dead code behind a false gate
- **Unused dependencies** — packages in package.json/requirements.txt that nothing imports. Each one adds to install time, potential security surface, and version conflict headaches during upgrades
- **Orphan test files** — tests for features or functions that no longer exist. They pass (because they test nothing meaningful) and create a false sense of coverage. Worse: they sometimes fail for unrelated reasons and waste debugging time
- **Dead CSS/styles** — class names and style rules that no component references. Stylesheets grow monotonically in most codebases. Nobody removes old styles because nobody is sure what uses them. Scan component references against defined classes
- **Abandoned migration files** — database migrations that ran once, did their job, and now sit in the migrations directory forever. Not dangerous, but noisy. In some frameworks they slow down test setup
- **Dead environment variables** — env vars defined in `.env.example` or config templates that nothing in the code reads. Devs dutifully set them during setup, wasting onboarding time on values nobody uses
- **Unreachable code paths** — logic after an early return, conditions that can never be true given the data types, switch cases that are structurally impossible. The code exists, it runs through linting, it will never execute
- **Legacy integration stubs** — code that connected to a service you no longer use (old analytics provider, deprecated payment gateway, sunset notification service). The integration is dead but the adapter, the types, and sometimes the retry logic live on
- **Dead localization/translation strings** — i18n keys defined in translation files that no component references. These accumulate as features get removed or rewritten but nobody cleans the translation files. They waste translator time during localization updates and inflate bundle size in apps that load all strings upfront

### Step 3: Impact Assessment

For each dead item, assess:
- **Maintenance cost**: Does it have tests? Does it appear in CI? Does it have dependencies that need updating? Is it included in code review when adjacent files change? Every dead item with a test suite is doubly wasteful — the code does nothing and the tests validate nothing
- **Risk level**: Could removing it break something non-obvious? Check for dynamic imports, reflection-based loading, string-based route matching, or external services that call the endpoint directly. Dead code that's truly dead is safe to remove. Dead code that's "dead except when X" is a bug waiting to happen
- **Cleanup effort**: How many files/lines to remove? Include associated test files, style files, type definitions, and config entries. A dead route isn't just one line in the router — it's the component, the tests, the styles, and any shared utilities that only served that component
- **Quick win classification**: Can this be removed in a single PR with no risk? Flag these separately — they're the cleanup sprint warm-up. Ship 10 easy deletions first, build momentum, then tackle the harder ones
- **Security surface**: Does the dead code expose an endpoint, accept user input, or access sensitive data? Dead endpoints that still respond to HTTP requests are security findings, not just tech debt

### Step 4: Output

**Summary** (always shown first):
- Total dead items found, broken down by type (dead routes, unused endpoints, orphan functions, stale flags, etc.)
- Estimated eng capacity being wasted (as % of maintenance burden) — e.g., "approximately 12% of test suite runs are testing dead code"
- Top 5 highest-cost dead items with one-line descriptions of what they're costing
- Quick wins: items that can be removed in < 1 hour with zero risk — the PR that's just deletions
- Security findings: any dead endpoints that still accept requests or dead code that accesses sensitive data
- False coverage alert: dead tests inflating your coverage metric — what does real coverage look like after removing them?

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Dead Item | Type | Location | Last Referenced | Maintenance Cost | Cleanup Effort | Risk |
|-----------|------|----------|----------------|-----------------|----------------|------|
| /api/v1/legacy-export | Unused endpoint | api.js:234 | Never called | Has 3 tests, 1 dep | 30 min | `[INFO]` Low |
| renderOldDashboard() | Orphan function | dashboard.js:89 | No imports | None | 10 min | `[INFO]` None |
| ENABLE_OLD_CHECKOUT | Stale flag (false 8 months) | flags.js:12 | Dead gate wrapping 200 lines | 40 lines of conditional logic | 20 min | `[INFO]` None |
| /admin/reports/v2 | Dead route | routes.js:67 | No inbound links | Has auth guard, 2 tests | 15 min | `[INFO]` Low |
| formatCurrencyLegacy() | Orphan function | utils.js:145 | Replaced by formatCurrency() | 1 test still references it | 10 min | `[INFO]` None |
| analytics-legacy.css | Dead stylesheet | styles/ | No component imports it | None | 5 min | `[INFO]` None |
| moment.js | Unused dependency | package.json | Nothing imports it (migrated to date-fns) | Adds 300KB to bundle, 2 known CVEs | 5 min | `[WARNING]` Check no dynamic imports |
| test/old-dashboard.test.js | Orphan test file | test/ | Tests renderOldDashboard which is itself dead | Passes but tests nothing real, false coverage | 10 min | `[INFO]` None |

**Cleanup Sprint Plan**:

| Phase | Items | Effort | Risk | Notes |
|-------|-------|--------|------|-------|
| Quick wins (do first) | Orphan functions, dead CSS, commented-out code | 1-2 hours | None | Pure deletions, no behavior change |
| Low risk | Stale feature flags, unused dependencies, dead env vars | 2-3 hours | Low | Verify no dynamic references first |
| Medium risk | Dead routes, unused endpoints | Half day | Medium | Check for external bookmarks, direct URL access, partner integrations |
| Verify carefully | Orphan test files, abandoned migrations | 1-2 hours | Low-Medium | Removing tests changes coverage metrics — document the real coverage after |
| Needs investigation | Legacy integration stubs, unreachable code paths | Variable | Check first | May have hidden consumers — flag for eng review before removing |

**Share-Ready Snippet**:

> I audited [module] for dead code. Found [N] items silently consuming eng time and attention:
>
> - [X] unused endpoints still being maintained and tested — [Y] tests running against code nobody calls
> - [Z] dead routes nobody navigates to — [A] have auth guards we're maintaining for zero users
> - [B] orphan functions nothing imports — including [specific example, e.g., "the entire legacy currency formatter"]
> - [C] stale feature flags that have been off for [N]+ months — dead conditional logic wrapping production code
> - [D] unused dependencies adding [N]KB to bundle size with [N] known CVEs
>
> Quick wins (< 1 hour total): [list the easiest items]. A [half-day/1-day] cleanup sprint would remove everything else.
>
> This isn't just dead weight — it's false test coverage, unnecessary onboarding confusion, and security surface we don't need. Want to slot this into next sprint?

### Step 5: Next Steps

- "Run `/flag-audit` to find stale feature flags that are effectively dead code — flags that have been on or off for 6+ months are dead conditional logic"
- "Run `/debt-cost-estimate` to quantify the broader tech debt beyond just dead code — dead code is the obvious waste, but the living code has costs too"
- "Run `/route-audit` to cross-reference dead routes with the full navigation map — some orphan routes are linked from external sources you don't control"
- "Run `/pre-ship-scan` before the cleanup PR ships to make sure removing dead code doesn't break anything that was silently depending on it"

## Sample Usage

```
"Find every dead route, unused API endpoint, and feature with no recent usage
in this repo. List them with last-called date and the eng effort keeping them
alive. I need a cleanup hit list."
```

**More examples:**

```
"We're over capacity. Scan /src/ and find everything we're maintaining
that nobody actually uses. I need to free up eng time."
```

```
"Before we add new features to the dashboard, tell me which existing
dashboard features are dead. Check /src/dashboard/."
```

```
"We're about to onboard 3 new engineers. I want to clean up the codebase
before they start so they're not reading dead code and asking about features
that don't exist anymore. Full scan of /src/."
```

```
"Security flagged unused dependencies with known CVEs. Scan the whole repo
and give me every unused dependency, dead endpoint, and orphan route — I need
to quantify the dead surface area for the security review."
```

## Tips

- Start with the module that feels most bloated. The first cleanup sprint always finds more than expected.
- Frame the cleanup as "making room for what's next" not "cleaning up your mess." Dead code isn't just wasted capacity — it's confusion that slows onboarding and clutters every code review. Same outcome, better reception.
- Orphan tests are sneaky. They pass, they count toward coverage, and they test nothing useful. When you find a dead function, check if it has tests — those tests are dead too, and they're inflating your coverage numbers. False confidence is worse than low confidence.
- Unused dependencies are a security concern, not just a cleanliness concern. Every package in your dependency tree is an attack surface. If nothing imports it, it's risk with zero value. Lead with the CVE count when making the case to remove them.
- Don't try to remove everything in one PR. Batch the cleanup into phases: quick wins first (zero-risk deletions), then medium risk, then items that need investigation. Cleanup PRs are the easiest to get merged — no new logic, no behavior changes, just deletions. Use them to build the eng team's cleanup muscle.
- Track before/after metrics: test suite runtime, bundle size, install time, coverage percentage. Document these wins so the next cleanup sprint has a track record — "Last cleanup saved 90s per CI run and removed 3 CVEs. This one targets the API layer."
- Check for dead code that's dead because of a feature flag, not because it was abandoned. If a flag is off but scheduled to turn on next quarter, that code isn't dead — it's dormant. Flag these as "verify with product" rather than "safe to remove."
- Time cleanup strategically: the best time is right before a major feature build (a clean module is easier to extend) and on a quarterly cadence (codebases accumulate dead code the way houses accumulate clutter — slowly, then suddenly). A quarterly sweep prevents paralysis.
- When presenting results, lead with the security angle for leadership and the simplicity angle for engineers. Execs care about "unused dependencies with CVEs." Engineers care about "40 fewer files to navigate, 90 fewer seconds in the test suite." Same cleanup, different pitches.
- Cross-reference dead endpoints with your API documentation. If the docs still reference a dead endpoint, external consumers might be trying to call it. Remove the code and update the docs at the same time, or you'll get support tickets from partners hitting 404s they didn't expect.
- Dead code audits pair well with onboarding and junior engineers. Have new team members run this scan on the module they're learning — they understand the codebase faster, and the team gets a cleanup list as a bonus. Dead code removal is low-risk, visible-impact work. Frame it as an opportunity, not a chore.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
