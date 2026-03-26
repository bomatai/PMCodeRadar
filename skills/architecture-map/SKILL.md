---
name: architecture-map
description: >
  Use this skill to map the full architecture impact of a code change before it ships.
version: 1.0
  Trigger on /architecture-map or when the user says things like
  "map the architecture", "what does this change touch", "show me the dependency chain",
  "architecture impact", "service map", "what systems are affected", "trace the impact",
  or "I need the full picture before the review."
  Also trigger when a PM is preparing for an architecture review, scoping a large refactor,
  or needs to understand the blast radius of a change across services.
---

# Architecture Impact Map

> Level 3 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

You're walking into an architecture review tomorrow. The engineer says "it's a small change." You nod. But you don't actually know what it touches. Every service. Every database write. Every API call. Every downstream system that quietly depends on the thing being changed. Now you do. The PM who shows up to an architecture review with a full impact map doesn't ask questions — they ask the *right* questions. That's a different person in the room. The PM equivalent of showing up to a knife fight with a lightsaber.

## What This Does

Traces every service, database table, API endpoint, message queue, and downstream dependency that a module or feature touches. Produces a full impact map so you know exactly what's in the blast radius before a single line of code ships. This isn't a diagram for a slide deck — it's a weapon for architecture reviews. You'll know what eng knows (sometimes more), and you'll know it in a format that makes the risk immediately visible.

## When to Use This

- You're prepping for an architecture review and need to know what a change actually touches
- Engineering says "it's isolated" and you want to verify that claim with data
- You're scoping a large feature and need to understand which systems are in play
- A cross-team dependency is suspected but nobody's confirmed it
- You're evaluating whether a "small refactor" is actually small
- Leadership wants a risk assessment and you need hard data, not vibes
- You're inheriting a module from another PM and need the full picture fast

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path or module is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which module to map — just start scanning.

If the user gives a feature name instead of a path, search the codebase for the most likely module and begin scanning it directly.

### Step 2: Analysis

Scan the target module and trace outward. For every connection found, follow it one more level deep. This is depth-2 tracing — the target, its direct dependencies, and their direct dependencies. Map:

- **Service-to-service calls** — HTTP requests, gRPC calls, internal API invocations between services. Include the method (GET, POST, PUT, DELETE) and the endpoint path
- **Database operations** — Every table read from, written to, or joined against. Include the operation type (SELECT, INSERT, UPDATE, DELETE) and the specific columns referenced
- **API endpoints exposed** — Routes this module defines that other services or clients consume. These are the contracts other teams depend on
- **API endpoints consumed** — External or internal endpoints this module calls. These are the contracts this module depends on
- **Message queues and events** — Events published, events subscribed to, queue producers and consumers. Include the event schema if defined
- **Shared libraries and utilities** — Common modules imported that create hidden coupling. A change to a shared utility affects every importer
- **Environment variables and config** — External configuration this module depends on. Missing config in a new environment = silent failure
- **Cron jobs and scheduled tasks** — Any timed processes tied to this module. These run silently and break silently
- **Cache layers** — Redis, Memcached, or in-memory caches read or written. Include cache key patterns and TTLs
- **Third-party integrations** — External vendor calls (Stripe, Twilio, etc.) made from this module
- **File system operations** — Any reads/writes to local or cloud storage (S3, GCS) from this module
- **WebSocket or real-time connections** — Long-lived connections that maintain state and break differently than HTTP
- **GraphQL resolvers and schema stitching** — Resolvers that federate data from multiple services, schema stitching or federation config that merges remote schemas. A change to one subgraph's types can break the composed supergraph. Trace resolver chains, dataloader patterns, and any @key or @external directives that create cross-service type dependencies
- **gRPC .proto file imports** — Protobuf definition files that services import to generate client/server stubs. A field renumbering or type change in a .proto file breaks every service that compiled against it. Trace import chains in .proto files and identify every service that depends on generated code from the target proto
- **Supabase direct DB calls from frontend** — `supabase.from('table')` calls in React hooks/components — these are the primary data access pattern in BaaS architectures, not API routes. Map which components query which tables directly
- **Supabase Edge Functions** — `supabase/functions/*/index.ts` as the backend service layer (Deno runtime, not Express). Each function directory is a deployable unit with its own dependencies
- **Supabase RLS policies** — Row Level Security in migration files (`CREATE POLICY`) as the access control layer — replaces traditional middleware auth checks. Map which tables have RLS enabled and what policies gate access

For each dependency found, classify:
- **Direction**: Inbound (something depends on this module) or Outbound (this module depends on something)
- **Coupling strength**: Hard (change here breaks there) or Soft (change here degrades there)
- **Ownership**: Which team owns the dependency? This determines who needs to be in the room

### Step 3: Output

**Summary** (always shown first):
- `[CRITICAL]` Total services directly affected by changes to this module
- `[CRITICAL]` Database tables with write operations (these carry the highest migration risk)
- `[WARNING]` Cross-team dependencies identified (other teams own services in the blast radius)
- `[WARNING]` External vendor integrations in the path (outage coupling)
- `[INFO]` Total API surface area: endpoints exposed + consumed
- `[INFO]` Hidden coupling: shared libraries or utilities that connect this module to unexpected places

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Dependency | Type | Direction | Location | Owner | Coupling | Risk if Changed |
|------------|------|-----------|----------|-------|----------|-----------------|
| users table | DB Write | Outbound | subscriptions/handler.js:45 | Auth team | Hard | `[CRITICAL]` Schema change breaks auth |
| /api/v2/billing | API Call | Outbound | subscriptions/billing-client.js:12 | Billing team | Hard | `[WARNING]` Contract change needed |
| subscription.created event | Event | Published | subscriptions/events.js:78 | Analytics, Notifications | Hard | `[CRITICAL]` 3 consumers depend on schema |
| Redis session cache | Cache | Read/Write | subscriptions/cache.js:23 | Platform team | Soft | `[WARNING]` TTL mismatch possible |
| Stripe API | Vendor | Outbound | subscriptions/stripe-adapter.js:34 | — | Hard | `[INFO]` Vendor SLA applies |
| formatCurrency() | Shared util | Imported | lib/format.js:12 | Platform team | Soft | `[INFO]` 14 other modules import this |
| SUBSCRIPTION_WEBHOOK_SECRET | Env var | Config | .env / config.js:8 | DevOps | Hard | `[WARNING]` Missing in new env = silent failure |

**Dependency Flow** (text-based):

```
[Target Module]
  |
  |-- OUTBOUND (this module depends on) --
  |-> users table (WRITE) -> Auth service depends on schema
  |                        -> Admin dashboard reads user data
  |-> billing API (CALL) -> Billing service -> Stripe
  |                       -> Billing service -> invoices table
  |-> Redis cache (READ/WRITE) -> Session service reads same keys
  |-> formatCurrency (IMPORT) -> shared by 14 modules
  |-> S3 bucket (WRITE) -> Invoice PDFs stored here
  |                      -> Export service reads from same bucket
  |-> Stripe API (VENDOR) -> Payment processing
  |
  |-- INBOUND (depends on this module) --
  |<- subscription.created (EVENT) <- Analytics consumer
  |                                 <- Notification consumer
  |                                 <- Webhook relay -> Partner API
  |<- /api/v2/subscriptions (API) <- Mobile app
  |                                <- Admin dashboard
  |<- subscription_status (CACHE) <- Status widget service
```

**Cross-Team Impact Summary**:

| Team | Dependencies | What They Need to Know |
|------|-------------|----------------------|
| Auth team | users table schema | Schema changes require auth service deploy |
| Billing team | /api/v2/billing contract | API contract changes need versioning |
| Analytics team | subscription.created event | Event schema changes break their pipeline |
| Platform team | Redis cache keys, formatCurrency | Cache key changes need coordinated deploy |

**Share-Ready Snippet**:

> Mapped the architecture impact for [module]. Here's what it actually touches:
>
> - [X] services with direct dependencies
> - [Y] database tables (including [Z] with write operations)
> - [N] cross-team dependencies ([team names])
> - [M] external vendor integrations
>
> The blast radius is [wider/narrower] than initially scoped. Key risks: [top 2-3 risks]. Recommend we review [specific areas] before shipping. Full map attached.

**Risk Assessment Matrix**:

| Risk Category | Count | Highest Severity | Action Required |
|---------------|-------|-----------------|-----------------|
| Cross-service dependencies | [N] | `[CRITICAL]` | Coordinate deploys with owning teams |
| Database write operations | [N] | `[CRITICAL]` | Review migration plan, assess lock times |
| Event schema dependencies | [N] | `[WARNING]` | Verify consumer compatibility before publishing changes |
| Vendor integrations | [N] | `[INFO]` | Check vendor SLA coverage for new usage patterns |
| Shared utility coupling | [N] | `[INFO]` | Confirm changes are isolated to target module |
| Configuration dependencies | [N] | `[WARNING]` | Verify config exists in all deployment environments |

### Step 4: Next Steps

- "Run `/removal-impact` if you're considering deprecating any of the services in this map"
- "Run `/pre-ship-scan` to validate this change is safe to ship once the architecture is approved"
- "Run `/migration-risk` if any database schema changes are part of this work"
- "Run `/dependency-map` to see which third-party vendors are in the critical path"
- "Run `/flag-audit` if any feature flags gate behavior in the affected modules"

## Sample Usage

```
"We're changing how subscriptions work. Map every service, database table,
API call, and downstream dependency that the subscription module touches.
I need the full impact map before the architecture review."
```

**More examples:**

```
"Engineering says the payments refactor is 'self-contained.' Trace every
dependency from /src/payments/ and show me what else is in the blast radius.
I want proof before I sign off on the timeline."
```

```
"We're adding a new field to user profiles. Map everything that reads from
or writes to the users table and any service that consumes user data
downstream. I need to know which teams to loop in."
```

```
"I'm inheriting the notifications module from another PM. Give me the
complete architecture map — every service it talks to, every table it
writes, every event it publishes. I need to understand what I own."
```

## Common Patterns This Catches

These are the patterns that trip teams up repeatedly. The map makes them visible:

- **The hidden event consumer** — Your module publishes a "user.updated" event. Three other teams subscribe to it. None of them are in your architecture review. You change the event schema. Their consumers break at 3 AM. The map shows every consumer before you change anything.
- **The shared database table** — Two services write to the same table. You change a column. The other service's writes start failing. The map traces both inbound and outbound database dependencies, not just the ones in your module.
- **The transitive vendor dependency** — Your module calls an internal billing service, which calls Stripe. You don't call Stripe directly, but a Stripe outage still breaks your feature. The depth-2 trace catches these transitive dependencies.
- **The forgotten cron job** — A nightly batch job reads from the same table you're modifying. Nobody mentioned it because it runs at midnight and nobody thinks about it during the day. The map finds scheduled tasks tied to your module's data.
- **The config-only dependency** — Your module reads an environment variable that another service also reads. You change the value for your use case. Their service picks up the change too. The map traces shared configuration.

## Tips

- Run this *before* the architecture review, not after. The PM who shows up with the map sets the agenda. The PM who doesn't is along for the ride. You want to be the person who says "I see this touches the auth service — are we aligned with that team?" not the person who discovers it in production.
- Pay special attention to event consumers. They're the dependencies nobody remembers until something breaks. A module might publish an event that three other teams consume — and none of them are in the meeting. Events are invisible coupling. If you find event consumers, invite those teams to the review.
- Cross-team dependencies are where timelines die. If your map shows services owned by other teams, that's not a technical finding — it's a scheduling constraint. Every cross-team dependency is a potential blocker. Flag it immediately and get alignment before the sprint starts, not during it.
- Shared utilities look harmless until someone changes them. If your module imports a shared function used by 14 other modules, a change to that function affects all 15. Ask eng whether the change is isolated to your module or if it touches shared code. If it touches shared code, your blast radius just expanded by 14x.
- The best time to run this is when someone says "it's a simple change." Simple changes that touch four services, two databases, and three event consumers aren't simple. The map proves it. And proving it before the work starts is how you avoid proving it in a post-mortem.
- Use the cross-team impact table in your kickoff doc. When you share the architecture map with stakeholders before the review, you're not just being thorough — you're showing the other teams that you've already identified the coordination points. That changes the tone of the entire conversation.
- Database write operations deserve extra attention. A module that reads from a table is loosely coupled — schema additions won't break it. A module that writes to a table is tightly coupled — any schema change, constraint addition, or validation rule change can cause write failures. The map classifies operation types for exactly this reason.
- Run this skill again after major architectural changes to keep the map current. An architecture map from six months ago is a historical document, not a planning tool. The codebase has changed. Dependencies have been added. The map should be refreshed before any major decision.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
