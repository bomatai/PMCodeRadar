---
name: event-inventory
description: >
  Use this skill to find and catalog every analytics event, tracking call, and instrumentation
  in the codebase. Trigger on /event-inventory or when the user says
  "find all tracking events", "what do we track", "analytics inventory", "event tracking audit",
  "do we track that", "instrumentation check", "tracking coverage", or "analytics map".
  Also trigger when a PM needs to understand tracking coverage before a launch, wants to find
  gaps in instrumentation, or is preparing for an analytics review.
version: 1.0
---

# Event Tracking Inventory

> Level 2 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

"Do we track that?" You said "I'll check." Then you Slacked the analyst. Then you forgot. Two weeks later the VP asks for funnel data on a feature that's been live for a quarter. Nobody knows if you instrumented it. Nobody wants to ask engineering to dig through the code. So the whole conversation stalls and someone puts "revisit tracking" on a doc that nobody revisits.

This is not a tools problem. It's a visibility problem. The tracking events exist somewhere in the code. They were added by engineers who had context at the time. But that context walked out the door with the sprint retro and now the events are just strings in files that nobody can map back to product behavior without a scavenger hunt.

## What This Does

Scans the entire codebase for every analytics event, tracking call, pixel fire, and instrumentation hook. Maps each one to the user action it actually tracks. Gives you a single table that answers the question "do we track that?" without pinging anyone.

You get a complete inventory of what your product observes about user behavior — and, just as importantly, what it doesn't. The gaps are where your next tracking spec starts.

## When to Use This

- Someone asks "do we track that?" and you don't want to guess
- You're launching a new feature and need to know what tracking already exists nearby
- You're prepping for a quarterly analytics review and want to know your coverage
- An analyst asks "what events fire on the checkout page?" and you want a real answer
- You're onboarding onto a product and need to understand what data you're collecting
- You're writing a tracking spec and want to avoid duplicating events that already exist
- The data team says funnel numbers don't look right and you need to verify what's firing
- You're migrating analytics providers and need a complete inventory of what to move
- A compliance audit requires you to document what behavioral data you collect

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which directory to scan — just start scanning.

### Step 2: Analysis

Scan for every tracking and analytics pattern in the codebase:

- **Analytics SDK calls** — `analytics.track()`, `analytics.identify()`, `analytics.page()`, `analytics.group()` and any wrapper functions around them
- **Event names and properties** — the string event name passed to each tracking call, plus the properties/payload object
- **Google Analytics / gtag** — `gtag('event', ...)`, `ga('send', ...)`, `dataLayer.push()` calls
- **Mixpanel / Amplitude / Segment** — SDK-specific calls like `mixpanel.track()`, `amplitude.logEvent()`, `window.analytics.track()`
- **Custom tracking utilities** — grep for internal wrapper functions (often named `trackEvent`, `logEvent`, `sendAnalytics`, `fireEvent`, `reportAction`, or similar)
- **Pixel fires** — Facebook pixel, ad tracking pixels, conversion pixels, `fbq('track', ...)`
- **Error tracking as analytics** — Sentry breadcrumbs, LogRocket, FullStory custom events that double as behavioral tracking
- **Server-side events** — API endpoints that log user actions to analytics services
- **Server-side event tracking (backend analytics)** — backend calls that send analytics data directly to providers without going through the frontend SDK. These often live in API handlers, background jobs, or webhook processors and are invisible to anyone looking only at the client code. Common patterns include direct HTTP calls to analytics APIs, server-side Segment libraries, or custom event pipelines that bypass the browser entirely
- **A/B test instrumentation** — experiment exposure events, variant assignment logging
- **Feature flag exposure tracking** — events that fire when a user encounters a flagged feature
- **Timing and performance events** — `performance.mark()`, custom load time tracking, LCP/FID instrumentation
- **Revenue and conversion events** — purchase tracking, subscription events, upgrade/downgrade events

For each event found, determine:
1. The event name (exact string as it appears in analytics)
2. The user action that triggers it (button click, page load, form submit, etc.)
3. The file and line number where it fires
4. What properties/data it sends along with the event
5. Whether it's client-side or server-side
6. Whether the event is conditionally fired (behind a flag, in a specific env, etc.)
7. Which analytics provider receives it (Segment, GA, Mixpanel, custom, etc.)
8. Whether the event name follows a consistent naming convention or is ad hoc

### Step 3: Output

**Summary** (always shown first):
- `[INFO]` Total number of unique tracking events found
- `[INFO]` Breakdown by type: page views, clicks, form submissions, transactions, errors
- `[INFO]` Analytics providers detected (Segment, Mixpanel, GA, custom, etc.)
- `[WARNING]` Events with no properties (firing but sending no useful data)
- `[WARNING]` Duplicate event names used in different contexts (same name, different meaning)
- `[WARNING]` Events with hardcoded values instead of dynamic properties
- `[CRITICAL]` User flows with zero tracking coverage (pages or features with no events at all)
- `[CRITICAL]` Events that track PII without obvious anonymization (emails, names in event properties)

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Event Name | User Action | Location | Properties Sent | Type | Provider | Notes |
|------------|-------------|----------|----------------|------|----------|-------|
| `checkout_started` | User clicks "Checkout" button | checkout.tsx:45 | cart_value, item_count, user_id | Client | Segment | Fires on every checkout attempt |
| `page_view` | Dashboard loads | dashboard.tsx:12 | page_name, referrer | Client | GA | Auto-tracked via router |
| `export_completed` | CSV export finishes | api/export.js:89 | export_type, row_count | Server | Custom | Logged to internal analytics DB |
| `error_displayed` | Error modal shown | ErrorBoundary.tsx:34 | error_code, page | Client | Sentry | Breadcrumb, not a formal event |
| `payment_succeeded` | Stripe webhook confirms payment | webhooks/stripe.js:112 | amount, plan_type | Server | Segment | Server-side only |
| `signup_completed` | User finishes onboarding | onboarding.tsx:201 | referral_source, plan | Client | Segment + Mixpanel | Dual-tracked |

**Coverage Map** (always included):

| Page / Flow | Events Tracked | Key Events | Coverage |
|-------------|---------------|------------|----------|
| Signup flow | 4 events | signup_started, email_entered, plan_selected, signup_completed | Good |
| Checkout flow | 7 events | checkout_started, payment_entered, coupon_applied, payment_succeeded, payment_failed, order_confirmed, receipt_viewed | Good |
| Settings page | 0 events | — | **GAP** |
| Admin dashboard | 1 event | admin_page_view | Sparse |
| Search | 2 events | search_initiated, search_result_clicked | Partial — no "zero results" tracking |
| Onboarding | 6 events | Full funnel covered | Good |

**Naming Consistency Report** (always included):

| Issue | Events Affected | Recommendation |
|-------|----------------|---------------|
| Mixed casing | `checkoutStarted` vs `checkout_started` | Standardize to snake_case |
| Duplicate names | `page_view` used in 3 files with different properties | Consolidate or differentiate |
| Vague names | `button_click` with no context property | Add `button_name` or `button_location` property |
| Inconsistent prefixes | Some use `user_` prefix, others don't | Adopt naming convention |

**Provider Map** (always included):

Which analytics providers are in use and how events flow to them:

| Provider | SDK/Method | Events Sent | Location | Notes |
|----------|-----------|-------------|----------|-------|
| Segment | `analytics.track()` | 23 events | Client + Server | Primary analytics pipe |
| Google Analytics | `gtag()` | 8 events | Client only | Mostly page views |
| Mixpanel | `mixpanel.track()` | 5 events | Client only | Used for A/B test events |
| Sentry | Breadcrumbs | 12 events | Client only | Error context, not true analytics |
| Custom internal | `logEvent()` | 4 events | Server only | Writes to internal DB |

**Dead or Broken Events** (always included):

Events that exist in code but are likely not functioning:

| Event | Issue | Location | Impact |
|-------|-------|----------|--------|
| `legacy_signup_track` | References removed SDK | signup-old.tsx:34 | Not firing — dead code |
| `purchase_complete` | Missing required property `transaction_id` | checkout.tsx:201 | Fires but rejected by Segment |
| `dashboard_load` | Inside unreachable code block | dashboard.tsx:15 | Never executes |

**Share-Ready Snippet**:

> I inventoried all tracking events in [module/repo]. Found [N] unique events across [X] files.
>
> - [Y] user actions are tracked (clicks, page views, submissions)
> - [Z] pages/flows have zero tracking coverage — biggest gap is [specific flow]
> - [W] events fire with no properties (wasted instrumentation)
> - [V] naming inconsistencies that will cause analytics headaches
>
> Attached the full inventory with coverage map. Flagged the gaps and naming issues. Happy to walk through what we should add before [launch/review].

### Step 4: Next Steps

- "Run `/onboarding-audit` to see if the onboarding flow has adequate tracking for funnel analysis"
- "Run `/route-audit` to cross-reference tracked events against actual user-facing routes — find pages with no instrumentation"
- "Run `/privacy-audit` to check if any tracked events are collecting PII that shouldn't be sent to third-party analytics"
- "Run `/duplicate-check` to see if similar tracking patterns were implemented in different modules — duplicated events with slightly different names are a common analytics headache"

## Sample Usage

```
"Find every analytics event, tracking call, and instrumentation in the codebase.
Map each one to the user action it tracks. Output as a table: event name,
user action, location in code."
```

**More examples:**

```
"We're launching the new pricing page next week. Scan /src/pricing/ and
tell me every tracking event that already exists. I need to know what
we're measuring before I write the instrumentation spec."
```

```
"The analyst says our checkout funnel data has gaps. Scan the checkout
module and map every event that fires during the purchase flow. Flag
any steps with no tracking."
```

```
"I just joined this team. Give me a full inventory of what we track
across the entire product. I need to understand our analytics coverage
before I make any roadmap decisions."
```

## Tips

- Run this before writing any tracking spec. Half the time, the event already exists and you just didn't know about it. The other half, you'll discover you're double-tracking something with slightly different names. Either way, you avoid wasting eng time.
- Pay special attention to events with no properties. An event that says "button clicked" without saying which button is technically tracking something but practically useless. Flag those for your analyst — they're the reason dashboards show big numbers that mean nothing.
- This pairs well with your analytics tool's event explorer. Run the inventory here, then compare against what's actually showing up in Mixpanel/Amplitude. Events in code but not in your dashboard usually mean broken instrumentation. Events in your dashboard but not in code mean someone's tracking via a tag manager and it's not version-controlled.
- Look for events that track PII. User emails, full names, or IP addresses in event properties are a compliance risk. If you find them, flag them immediately — that's a conversation with legal, not just analytics. GDPR and CCPA have opinions about what you send to third-party analytics tools.
- The naming consistency report matters more than you think. When two engineers name similar events differently, your analyst ends up maintaining a translation layer in every query. Fix naming now or pay for it in every dashboard forever.
- After running this, create a shared tracking spec template for your team. If the inventory reveals chaos, the fix isn't just cleaning up existing events — it's establishing a convention so new events don't add to the mess. Event name format, required properties, where to put the tracking call. Write it once, reference it forever.
- Check for events that fire on every page load or every API call. High-frequency events consume your analytics quota fast. If you're on a usage-based analytics plan, these are costing real money. Sometimes the fix is sampling, sometimes it's removing the event entirely.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
