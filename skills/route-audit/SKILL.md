---
name: route-audit
description: >
  Use this skill to map every route, page, and navigation path in the codebase.
  Trigger on /route-audit or when the user says things like
  "map all routes", "route audit", "find dead-end pages", "navigation map",
  "orphan pages", "what pages does our app have", "page inventory",
  or "find unused routes."
  Also trigger when a PM needs to understand the full scope of the product's
  navigation, is planning an IA restructure, or wants to find pages that exist
  in code but not in any design spec.
version: 1.0
---

# User Route Audit

> Level 2 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Your Figma file shows 6 pages. Your codebase has 11. Including one that leaks user tokens.

## What This Does

Maps every route, page transition, and navigation path in the codebase. Builds the actual sitemap of what your product supports — not what your PRD says it supports. Finds the dead ends nobody designed, the orphan pages nobody visits, and the routes that exist because someone merged a PR in 2021 and nobody deleted it when the feature was cut.

This is the difference between the product you think you have and the product users actually navigate. Most PMs are surprised by the gap. The code doesn't lie, but it also doesn't volunteer information. You have to ask.

## When to Use This

- You're restructuring the information architecture and need the real page inventory
- You suspect there are pages in the app that aren't in any design spec or PRD
- Users report "weird pages" or navigating somewhere unexpected
- You need to audit what a specific user role can actually access
- You're planning a migration and need to know the full surface area of the frontend
- Security flagged an unexpected endpoint and you need the complete route map fast
- A new PM joined and needs to understand the product's actual scope, not just what's in the docs

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/pages/`, `/src/routes/`, or `/src/app/` — whichever top-level source directory exists. Do not ask the user which directory to scan — just start scanning.

Clarify the focus:
- **Full route map**: every route in the entire application
- **Section-specific**: just one area (e.g., admin, settings, dashboard)
- **Role-based**: what routes does a specific user role see?
- **Security-focused**: which routes are unprotected?

### Step 2: Analysis

Build the complete route map by scanning for:

- **Router configuration** — route definitions in React Router, Next.js pages/app directory, Vue Router, Express routes, Django URLs, Rails routes, or whatever framework is in use. Include both file-based and config-based routing
- **Dynamic routes** — parameterized paths (`/user/:id`), catch-all routes (`/docs/**`), wildcard handlers, optional segments
- **Nested routes** — child routes, layout routes, route groups, shared layouts that wrap multiple pages
- **Protected routes** — auth guards, role-based access control, plan-gated pages, middleware that checks permissions before rendering
- **Navigation links** — every `<Link>`, `<a>`, `router.push()`, `navigate()`, `window.location`, and programmatic navigation that sends users somewhere. This is how you find which pages are actually reachable vs. just defined
- **Dead-end pages** — pages with no outbound navigation. The user arrives and has nowhere to go except the back button. Sometimes intentional (receipt page), often not (settings sub-page)
- **Orphan routes** — routes defined in the router but never linked to from anywhere in the app. They exist in the code. No user can naturally reach them. But they're accessible via direct URL
- **Redirect chains** — routes that redirect to other routes that redirect again. How many hops before the user lands somewhere real? Redirects that chain 3+ deep are a symptom of accumulated changes nobody cleaned up
- **404 handling** — what happens when a user hits a route that doesn't exist? Is there a fallback page? A redirect to home? Or just a blank screen?
- **Route conflicts** — two routes that could match the same URL pattern. Which one wins? Is the behavior consistent across all navigation methods?
- **Hidden routes** — routes not shown in any navigation menu, sidebar, or header but still accessible via direct URL. Debug panels, admin tools, legacy pages
- **API routes exposed to the client** — backend routes that the frontend knows about. Any that shouldn't be publicly known?
- **Deep link support** — can users bookmark and share URLs? Do parameterized routes resolve correctly when accessed directly?
- **Redirects and route aliases** — routes that redirect to other routes, or multiple URL paths that resolve to the same component. Map every redirect and alias to find confusion or dead loops. A redirect chain of `/old-pricing` -> `/pricing` -> `/plans` is three URLs for one page, and if any link in the chain breaks, users hit a 404 or loop. Also look for temporary redirects that became permanent, aliases that fragment analytics (same page tracked under different URLs), and circular redirects that trap users in an infinite loop

For each route found, determine:
1. Is it reachable from normal navigation? Or only via direct URL?
2. Who can access it? Any user? Logged-in users? Admins? Specific roles?
3. What links to it? What does it link to?
4. Is it in the current design spec? Or is it a ghost page?
5. Does it have its own error handling? Or does it rely on a global fallback?

### Step 3: Output

**Summary** (always shown first):
- `[CRITICAL]` Orphan routes accessible via direct URL but not linked from anywhere — potential security or data exposure risk
- `[CRITICAL]` Routes with no auth protection that should have it (admin pages, debug tools, user data endpoints)
- `[CRITICAL]` Route conflicts — two definitions matching the same URL with unpredictable behavior
- `[WARNING]` Dead-end pages — users arrive but have no clear next action
- `[WARNING]` Redirect chains longer than 2 hops
- `[WARNING]` Routes not in any design spec — product drift
- `[INFO]` Total routes: [N] defined, [X] actively linked, [Y] orphaned, [Z] dead-ends
- `[INFO]` Route tree depth: shallowest [N] levels, deepest [M] levels
- `[INFO]` Pages per user role breakdown

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Route | Page/Component | Inbound Links | Outbound Links | Auth Required | Role-Gated | In Design Spec? | Status |
|-------|---------------|---------------|----------------|---------------|------------|----------------|--------|
| / | HomePage | Direct + nav | 5 links | No | No | Yes | Active |
| /dashboard | DashboardPage | Nav menu | 3 links | Yes | No | Yes | Active |
| /admin/legacy | LegacyAdmin | None | 1 link | No (!) | No (!) | No | Orphan |
| /settings/billing | BillingPage | Settings menu | 0 links | Yes | Owner only | Yes | Dead-end |
| /api/debug | DebugPanel | None | None | No (!) | No | No | Orphan + Unprotected |
| /old-pricing | PricingPage | None | 2 links | No | No | No | Orphan — old landing page |

**Route Tree Visualization**:

```
/
  /signup
  /login
  /forgot-password
  /dashboard
    /dashboard/projects
    /dashboard/projects/:id
    /dashboard/settings
      /dashboard/settings/profile
      /dashboard/settings/billing  [DEAD END]
      /dashboard/settings/team
  /admin  [AUTH: admin role]
    /admin/users
    /admin/analytics
    /admin/legacy  [ORPHAN - no inbound links, NO AUTH]
  /api/debug  [ORPHAN - UNPROTECTED]
  /old-pricing  [ORPHAN - not in any nav]
```

**Role-Based Access Matrix**:

| Route | Anonymous | Logged-in User | Admin | Owner |
|-------|-----------|---------------|-------|-------|
| / | Yes | Yes | Yes | Yes |
| /dashboard | No | Yes | Yes | Yes |
| /admin/* | No | No | Yes | Yes |
| /settings/billing | No | No | No | Yes |
| /api/debug | Yes (!) | Yes (!) | Yes | Yes |

**Share-Ready Snippet**:

> I mapped every route in [module/repo]. The full picture:
>
> - [N] total routes defined in the codebase
> - [X] orphan pages — exist in code but no user can navigate to them naturally
> - [Y] dead-end pages — users arrive but have no clear next step
> - [Z] routes missing auth protection that probably need it
> - [A] routes not in any current design spec — accumulated product drift
>
> The Figma shows [B] pages. The codebase has [N]. The gap includes [specific examples]. Full route map and tree attached.

### Step 4: Next Steps

- "Run `/onboarding-audit` to trace the specific route a new user takes from signup to activation"
- "Run `/dead-code-audit` to find whether orphan routes have associated dead code that should be cleaned up — if the route is dead, the component and its tests are dead too"
- "Run `/privacy-audit` to check whether any orphan or unprotected routes expose user data"
- "Run `/event-inventory` to see which routes have analytics tracking and which are invisible to your data team"

## Sample Usage

```
"Map every route, page, and navigation path in the app. Show me the full
tree of where users can go. Flag dead-end pages, orphan routes with no
inbound links, and any loops users can get stuck in."
```

**More examples:**

```
"I'm restructuring our IA. Before I propose anything, I need the complete
route inventory. Every page, who can access it, and how users get there.
Scan /src/pages/ and /src/routes/."
```

```
"Security flagged an 'unexpected endpoint' in a pen test. Map every route
in the app and flag any that are accessible without authentication. I need
this for a meeting at 3pm."
```

```
"We're migrating to a new frontend framework. I need the complete route
surface area — every page, every dynamic parameter, every nested layout —
so we can plan the migration scope."
```

## Tips

- Orphan routes are the number one source of "how did a user find this?" bugs. If a route exists and has no auth guard, assume someone will find it. Browsers autocomplete. Search engines index. Users share URLs. Pentesters enumerate. An orphan route is not "hidden" — it's "undiscovered." Treat it accordingly.
- Dead-end pages aren't always a bug — sometimes they're a receipt or confirmation. But if a user lands on a settings page with no way to navigate back or forward without the browser back button, that's broken UX. Distinguish intentional dead ends from accidental ones. The test: would a designer have put a "back" or "next" button here? If yes, it's accidental.
- The gap between your Figma page count and your codebase route count tells you how much product drift has accumulated. A 2-page gap is normal. A 5+ page gap means the product has evolved in code without PM or design involvement. That's not a cleanup item — that's a conversation about process.
- Pay special attention to routes behind feature flags. A flagged-off route is still defined in the router. If the flag was turned off six months ago and nobody removed the route, it's an orphan. If the route has no auth guard, it's an unprotected orphan. Feature flags that stay off become dead code, and dead routes are the most dangerous kind.
- If you're doing a security-focused audit, sort the output by auth status first. Every unprotected route that serves user data or admin functionality is a finding, regardless of whether it's linked from the UI. The router doesn't know the difference between a "public page" and a "page nobody bothered to protect."
- Next.js uses file-based routing (`app/` or `pages/`) — every file is a route, so the directory tree IS the route map. Just list the file tree and you already have most of the audit. Watch for `route.ts`, `page.tsx`, and `layout.tsx` files that define segments.
- React Router defines routes in code (look for `<Route>` or `createBrowserRouter`) — they're scattered, not centralized. You'll need to grep across the codebase because routes can be defined in any component file, not just one config.
- Express routes live in `.get()`, `.post()`, `.use()` calls — grep for `router.` to find them fast. They're often split across multiple files in a `/routes/` directory, so make sure you scan all of them.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
