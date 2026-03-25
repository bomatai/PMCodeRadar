---
name: api-surface-map
description: >
  Use this skill to catalog every public API endpoint the product exposes.
  Trigger on /api-surface-map or when the user says
  "list all endpoints", "API surface map", "what endpoints do we have", "API inventory",
  "endpoint documentation", "partner integration prep", "what APIs do we expose",
  or "public API audit". Also trigger when a PM is preparing for a partner integration call,
  needs to understand the product's external surface, or wants an API overview before a
  security review.
version: 1.0
---

# API Surface Mapper

> Level 2 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Partner call at 2pm. "What endpoints do you expose?" You have no idea. You know the product. You know the features. But you've never once mapped the API surface and now you're stalling while someone pings eng in a side Slack. The partner is polite about it. Your VP is not.

Every product has an external surface — the set of endpoints, webhooks, and interfaces that the outside world can touch. If you don't know what that surface looks like, you can't have an informed conversation about integrations, security, or what to open up next. One PM used this before a partner integration call. Answered every question without pinging eng once.

## What This Does

Lists every public API endpoint your product exposes. Method. Path. What it actually does in product terms. What it accepts. What it returns. Know your product's attack surface before the security review asks you to explain it. Gives you a table you can share with partners, drop into a security review, or use to prep for any conversation where someone asks "what can external systems do with your product?"

## When to Use This

- You have a partner integration call and need to know what endpoints you expose
- Security review requires a list of all public-facing API surfaces
- You're writing API documentation and need an accurate starting point
- You want to understand what external systems can do with your product
- You're evaluating which endpoints to open up (or lock down) for a new integration
- A new engineer asks "what's our API?" and you want to actually answer
- You're preparing a proposal for a public API and need to inventory the internal one first

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user where the API routes live — just start scanning.

Also check for:
- Express/Koa: `app.get()`, `router.post()`, etc.
- Next.js: `/pages/api/` or `/app/api/` directory
- Django: `urlpatterns` in `urls.py`
- Rails: `routes.rb`
- FastAPI/Flask: decorator-based routes
- GraphQL: schema definitions and resolvers
- OpenAPI/Swagger: `swagger.yaml` or `openapi.json` spec files

### Step 2: Analysis

Scan for every API endpoint definition in the codebase:

- **Route definitions** — Express `app.get()`, `app.post()`, etc.; Next.js `/pages/api/` files; Django `urlpatterns`; Rails `routes.rb`; FastAPI decorators; whatever framework is in use
- **HTTP method** — GET, POST, PUT, PATCH, DELETE for each route
- **Path and parameters** — the URL path including dynamic segments (`:id`, `[slug]`, `{user_id}`, etc.)
- **Request body / query params** — what the endpoint accepts as input (types, required fields, validation)
- **Response shape** — what the endpoint returns (or the model/serializer it uses)
- **Authentication requirements** — is it public, requires auth token, requires specific role/permission, API key only?
- **Middleware** — rate limiting, CORS, validation, logging, caching applied to each route
- **Versioning** — `/api/v1/` vs `/api/v2/` — how many API versions exist and which are active
- **Internal vs. external** — routes meant for the frontend vs. routes exposed to third parties
- **Webhook endpoints** — incoming webhook receivers from external services (Stripe, Slack, etc.)
- **Webhook dispatchers** — outgoing webhooks your product sends to external systems
- **GraphQL resolvers** — if the product uses GraphQL, map every query and mutation as its own "endpoint"
- **WebSocket endpoints and event-based APIs** — real-time connections, what messages they accept and emit. These are not REST endpoints and they're easy to miss, but they're a real part of your API surface. Map every WebSocket event name, the payload it carries, and which client actions trigger it. Also look for Server-Sent Events (SSE), socket.io event handlers, and any pub/sub patterns that external consumers might rely on
- **File upload endpoints** — routes that accept file uploads (important for security)
- **Batch/bulk endpoints** — routes that accept arrays of operations (important for rate limiting)

For each endpoint found:
1. HTTP method and full path
2. What it does in plain English (not just "handles request")
3. What it accepts (params, body, headers)
4. What it returns (response shape, status codes)
5. Auth requirements (public, user auth, admin only, API key, webhook signature)
6. Whether it's documented anywhere
7. Rate limiting status

### Step 3: Output

**Summary** (always shown first):
- `[INFO]` Total number of endpoints by HTTP method (GET: X, POST: Y, PUT: Z, DELETE: W)
- `[INFO]` API versions in use and endpoint count per version
- `[INFO]` Auth breakdown: how many are public vs. authenticated vs. admin-only
- `[WARNING]` Endpoints with no authentication requirement (open to the internet)
- `[WARNING]` Endpoints with no rate limiting
- `[WARNING]` Endpoints that accept file uploads without visible size limits
- `[CRITICAL]` DELETE endpoints accessible without admin role
- `[CRITICAL]` Endpoints that accept user input with no visible validation
- `[CRITICAL]` Undocumented endpoints that appear to be externally accessible

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Method | Path | What It Does | Accepts | Returns | Auth | Rate Limited | Documented |
|--------|------|-------------|---------|---------|------|-------------|-----------|
| GET | `/api/v1/users/:id` | Fetch a single user's profile | `id` param | User object (name, email, plan) | User token | Yes | Yes |
| POST | `/api/v1/orders` | Create a new order | Cart items, payment method, address | Order confirmation + ID | User token | Yes | Yes |
| DELETE | `/api/v1/users/:id` | Delete a user account | `id` param | 204 No Content | Admin only | No | No |
| GET | `/api/v1/products` | List all products | Query: category, page, limit | Paginated product list | Public | Yes | Yes |
| POST | `/webhooks/stripe` | Receive Stripe payment events | Stripe webhook payload | 200 OK | Stripe signature | No | No |
| GET | `/api/v1/search` | Search products and users | Query: q, type, page | Search results | Public | Yes | Partial |
| PUT | `/api/v1/users/:id/settings` | Update user preferences | Settings object (notifications, theme, timezone) | Updated settings | User token | Yes | No |
| POST | `/api/v1/exports` | Trigger a data export | Export type, date range, format | Job ID + status URL | User token | No | No |
| GET | `/api/v1/health` | Health check | None | Status: OK | Public | No | No |
| POST | `/api/v1/uploads` | Upload a file | Multipart file + metadata | File ID + URL | User token | Yes | No |

**By Category** (always included):

| Category | Endpoints | Auth Level | Description |
|----------|-----------|-----------|-------------|
| User Management | 6 | User/Admin | CRUD operations on user accounts and profiles |
| Orders & Checkout | 8 | User | Order creation, status, history, refunds |
| Products | 4 | Public/User | Product catalog queries and management |
| Webhooks (Inbound) | 3 | Signature | External service callbacks (Stripe, Slack, etc.) |
| Webhooks (Outbound) | 2 | N/A | Events your product pushes to external systems |
| Admin | 5 | Admin | Internal management, reports, user moderation |
| Search | 2 | Public | Full-text search across products and content |
| File Operations | 3 | User | Upload, download, and manage files |
| System | 2 | Public | Health checks, version info |

**Security Quick Scan**:

| Concern | Endpoints Affected | Severity | Notes |
|---------|-------------------|----------|-------|
| No auth required | `/api/v1/products`, `/api/v1/health`, `/api/v1/search` | `[INFO]` — intentionally public | Verify these should be public |
| No rate limiting | `/webhooks/stripe`, `/api/v1/admin/export`, `/api/v1/health` | `[WARNING]` — potential abuse vector | Webhooks should at least have signature verification |
| DELETE without admin check | None found | `[INFO]` — good | |
| No input validation visible | `/api/v1/search` | `[WARNING]` — accepts raw query string | SQL injection risk if not sanitized |
| File upload no size limit | `/api/v1/uploads` | `[WARNING]` — potential DoS vector | Should enforce max file size |
| Undocumented endpoints | 4 endpoints | `[WARNING]` — unknown external exposure | Need to confirm if these are intentionally exposed |

**Partner-Ready View** (always included):

Filtered view showing only endpoints relevant to external integrations:

| Method | Path | Description | Auth Required | Rate Limit | Notes for Partners |
|--------|------|------------|--------------|-----------|-------------------|
| GET | `/api/v1/products` | List products | API key | 100/min | Supports pagination, filtering |
| GET | `/api/v1/orders/:id` | Get order status | API key + user scope | 60/min | Returns current status + history |
| POST | `/api/v1/orders` | Create order | API key + user scope | 30/min | Requires valid product IDs |
| POST | `/webhooks/outbound` | Receive order updates | Your webhook URL | N/A | We push status changes to you |

**Share-Ready Snippet**:

> Here's our API surface for the integration discussion:
>
> - [N] total endpoints across [X] API versions
> - [Y] public endpoints (no auth required): [list them]
> - [Z] endpoints relevant to your integration: [specific ones]
> - Authentication: [method — API key, OAuth, token]
> - Rate limits: [summary]
>
> Full endpoint table attached with methods, paths, auth requirements, and what each one does. Let me know which ones you need access to and I'll coordinate with eng on credentials.

### Step 4: Next Steps

- "Run `/schema-explain` to understand the data models behind these endpoints — what you're actually sending and receiving"
- "Run `/privacy-audit` to check which endpoints expose or accept personal data — important before opening them to partners"
- "Run `/error-audit` to see what error responses your API returns — partner integrations break loudly when your error payloads are inconsistent or generic"
- "Run `/validation-audit` to understand what input validation each endpoint enforces — partners need to know what your API will reject and why"

## Sample Usage

```
"List every public API endpoint in this repo. For each: HTTP method, path,
what it does in plain English, what it accepts, what it returns. Format as
a table I can share with the partner integration team."
```

**More examples:**

```
"We have a security review next week. I need a full inventory of every
endpoint our product exposes, whether it requires authentication, and
whether it's rate limited. Scan /src/api/ and /src/routes/."
```

```
"I'm prepping for a partner call about integrating with our order system.
Map every endpoint related to orders — what they accept, what they return,
and what auth they need. I want to answer their questions without pinging eng."
```

```
"We're thinking about launching a public API. Before I scope it, show me
every endpoint we have internally so I can decide which ones to expose.
Include auth requirements and rate limiting status."
```

## Tips

- Sort endpoints by auth level for security reviews and by product domain for partner calls. Same data, different lens. The audience determines the grouping. A CISO wants to see unauthenticated endpoints first. A partner wants to see the ones relevant to their integration.
- Endpoints with no rate limiting are the ones that will bite you first. A partner hammering an unprotected endpoint at scale is how you get an incident on a Friday afternoon. Flag these even if nobody asked. It's the kind of proactive finding that makes PMs look sharp.
- If you find undocumented endpoints, that's your first action item. Undocumented doesn't mean unused — it usually means "someone built it for a specific integration and forgot to tell anyone." Those are the endpoints that cause surprises during security reviews and partner calls.
- The gap between your internal API and what you'd want in a public API is your public API roadmap. This audit gives you the starting inventory. The endpoints that are clean, well-documented, and properly authenticated are your first candidates for external exposure.
- Webhook endpoints (both inbound and outbound) are often the most neglected. They were set up once for a specific integration and never revisited. Check that inbound webhooks verify signatures and that outbound webhooks have retry logic. These are the quiet integrations that break loudly.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
