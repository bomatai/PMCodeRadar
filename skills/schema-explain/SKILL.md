---
name: schema-explain
description: >
  Use this skill to translate database schemas into plain product language.
  Trigger on /schema-explain or when the user says
  "explain the database", "what's in the schema", "database in product terms", "explain tables",
  "schema explainer", "what does this table store", "data model walkthrough", or "database for PMs".
  Also trigger when a PM needs to understand what data the product stores, wants to know how
  entities relate to each other, or is preparing for a data privacy review.
version: 1.0
---

# Database Schema Explainer

> Level 2 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

You opened the database diagram. It looked like a conspiracy board. You closed it. Then someone in a meeting said "that's stored in the users table" and you nodded like you knew what that meant. You didn't. And now you're writing a spec that involves user data and you're guessing at what fields actually exist.

The schema is the source of truth for what your product actually knows about its users, its content, and its state. Every feature you ship reads from it or writes to it. If you can't read it, you're not making informed product decisions — you're making educated guesses and hoping eng corrects you in review.

## What This Does

Reads the database schema — tables, columns, relationships, constraints — and explains every piece in product terms. What does each table store? What does each column mean in plain English? How do the tables connect to each other? You get a product doc, not a technical spec. Like subtitles for a foreign film.

This is the translation layer between how engineering thinks about data and how you think about the product. After running this, you can look at a table name in a meeting and know exactly what it means.

## When to Use This

- You inherited a product and need to understand what data it stores
- You're writing a spec that involves user data and need to know what fields exist
- A privacy review requires you to explain what personal data the product collects
- You're in a meeting about data modeling and want to actually follow the conversation
- You need to understand the relationship between entities (users, orders, teams, etc.)
- You're evaluating a feature request and want to know if the data model supports it
- You're onboarding and want to understand the product's data foundation before reading any code
- You're scoping a migration and need to know what data moves and how it connects
- Someone mentions a table name in a meeting and you want to know what it means before nodding

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user where the schema lives — just start scanning.

Also check for:
- Prisma schema: `schema.prisma` or `prisma/schema.prisma`
- Sequelize models: `/models/` directory
- TypeORM entities: `/entities/` directory
- Django models: `models.py` files
- Rails migrations: `/db/migrate/`
- Raw SQL: `.sql` files in `/db/` or `/sql/`
- Knex migrations: `/migrations/` directory
- Mongoose schemas: `.schema.js` or `.model.js` files
- Drizzle schema: `schema.ts` files
- Alembic migrations: `/alembic/versions/`
- GraphQL schema: `.graphql` or `.gql` files, `typeDefs`, `schema.graphql`, or inline `gql` template literals defining types, queries, and mutations

### Step 2: Analysis

Read and interpret every element of the schema:

- **Tables/collections** — what each one represents in product terms (e.g., "`orders` = every purchase a customer has ever made")
- **Columns/fields** — what each column stores, with product context (e.g., "`status` = where the order is in the fulfillment process: pending, paid, shipped, delivered, cancelled")
- **Primary keys** — how each record is uniquely identified
- **Foreign keys and relationships** — how tables connect (e.g., "every order belongs to one user, and one user can have many orders")
- **Join tables** — many-to-many relationships explained (e.g., "`user_roles` connects users to roles — this is how permissions work")
- **Indexes** — what the system is optimized to look up quickly (reveals what queries run most often and what product flows depend on fast lookups)
- **Constraints and defaults** — business rules baked into the database (e.g., "email must be unique", "status defaults to 'pending'")
- **Timestamps** — `created_at`, `updated_at`, `deleted_at` — what they tell you about data lifecycle
- **Soft deletes** — if `deleted_at` exists, records are hidden but not destroyed. Critical for privacy conversations.
- **Enums and type columns** — the finite set of states or categories something can be in (these are your product's state machine, encoded in the database)
- **JSON/JSONB columns** — flexible data storage that might contain important but unstructured product data
- **Polymorphic relationships** — columns like `commentable_type` and `commentable_id` that let one table connect to many different entities

For each table, determine:
1. What it stores (in one sentence a stakeholder would understand)
2. How many other tables reference it (is this a core entity or a peripheral one?)
3. What product feature it supports
4. What sensitive/personal data it contains (flag for privacy)
5. How large it likely is (is this a high-write table like events, or a low-write table like settings?)

### Step 3: Output

**Summary** (always shown first):
- `[INFO]` Total number of tables and their high-level grouping (user data, product data, transaction data, system data)
- `[INFO]` Core entities: the 3-5 most connected tables that form the backbone of the product
- `[INFO]` Data lifecycle: which tables use soft deletes vs. hard deletes
- `[WARNING]` Tables with personal/sensitive data (PII) — names, emails, addresses, payment info
- `[WARNING]` Tables with no obvious product purpose (could be legacy or dead)
- `[WARNING]` JSON columns with unstructured data (could contain anything — needs investigation)
- `[CRITICAL]` Schema inconsistencies — tables that reference deleted tables, orphaned foreign keys, columns with misleading names

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Table | What It Stores | Key Columns | Relationships | PII? | Product Feature |
|-------|---------------|-------------|--------------|------|----------------|
| `users` | Every registered account | email, name, plan_type, created_at | Has many orders, has many sessions, has many team_memberships | **Yes** — email, name | Auth, profiles |
| `orders` | Every purchase transaction | user_id, total, status, created_at | Belongs to user, has many line_items | No | Checkout, order history |
| `line_items` | Individual items in an order | order_id, product_id, quantity, price | Belongs to order, belongs to product | No | Cart, order details |
| `sessions` | Active login sessions | user_id, token, expires_at, ip_address | Belongs to user | **Yes** — session tokens, IP | Auth |
| `teams` | Organization/team accounts | name, plan_type, owner_id | Has many team_memberships, belongs to user (owner) | No | Team management |
| `team_memberships` | User-team associations | user_id, team_id, role | Belongs to user, belongs to team | No | Permissions |
| `feature_flags` | Feature flag definitions | name, enabled, rollout_pct | None | No | Feature management |
| `audit_logs` | Who did what and when | user_id, action, resource_type, resource_id, metadata | Belongs to user | **Yes** — action history | Compliance, debugging |

**Entity Relationship Summary** (always included):

Plain-English description of how the core entities connect:

> A **user** signs up and gets a record in `users`. When they purchase something, an **order** is created linking back to them. Each order contains one or more **line_items** pointing to **products**. If the user is part of a **team**, the `team_memberships` join table connects them with a role (admin, member, viewer). Their **subscription** (in `subscriptions`) determines what they can access. Everything they do is logged in `audit_logs`.

**State Machine Map** (always included):

For tables with status/state columns, show the possible states and what they mean:

| Table | Column | Possible States | What Each Means |
|-------|--------|----------------|----------------|
| `orders` | `status` | pending, paid, shipped, delivered, cancelled, refunded | Tracks the order from creation through fulfillment |
| `users` | `status` | active, suspended, deactivated | Controls whether the user can log in and use the product |
| `subscriptions` | `status` | trial, active, past_due, cancelled, expired | Billing lifecycle of a paid plan |

**Privacy Summary** (always included):

| Table | PII Fields | Data Type | Retention Policy | Soft Delete? |
|-------|-----------|-----------|-----------------|-------------|
| `users` | email, name, phone | Contact info | Unknown | Yes (`deleted_at`) |
| `sessions` | ip_address, user_agent | Technical identifiers | Unknown | No (hard delete) |
| `audit_logs` | user_id + action metadata | Behavioral data | Unknown | No |
| `orders` | billing_address | Financial/address | Unknown | Yes (`deleted_at`) |

**Share-Ready Snippet**:

> I mapped the database schema for [product/module]. Here's the overview:
>
> - [N] tables total, organized around [core entities: users, orders, teams, etc.]
> - Core data model: [1-2 sentence summary of how entities relate]
> - [X] tables contain PII (flagged for privacy review: users, sessions, audit_logs, orders)
> - [Y] tables look potentially unused (flagged for cleanup)
>
> Full breakdown attached with entity relationships, state machines, and privacy flags. Happy to walk through any specific area.

### Step 4: Next Steps

- "Run `/architecture-map` to see how the application code maps to these database tables — which services read/write which tables"
- "Run `/privacy-audit` to do a thorough privacy review based on the PII flagged in the schema"
- "Run `/event-inventory` to see what user actions are tracked — cross-reference with the data stored in these tables"
- "Run `/api-surface-map` to see which API endpoints read from and write to these tables — connects the schema to the product's external interface"

## Sample Usage

```
"Read the database schema and explain every table and relationship in
product terms. What does each table store? How do they connect? Write it
like a product doc, not a technical spec."
```

**More examples:**

```
"I'm new to this product. Walk me through the data model — what are
the core entities, how do they relate, and what does the product actually
store about its users? Check /src/models/ for the schema definitions."
```

```
"We have a privacy review next week. I need to know every table that
stores personal data — names, emails, addresses, anything PII. Scan the
schema and flag everything sensitive."
```

```
"I'm writing a spec for a reporting feature. Before I define what data
to show, I need to understand what data actually exists. Walk me through
the orders and products tables and how they connect."
```

## Tips

- The schema tells you what the product is actually built to do, not what the PRD said it should do. If there's a `referrals` table with five columns and foreign keys everywhere, someone built a referral system whether or not it's in your roadmap. That's a conversation worth having.
- Pay attention to tables with `deleted_at` columns. Soft deletes mean data is "deleted" from the user's perspective but still sitting in the database. This matters enormously for privacy, GDPR, and "right to be forgotten" conversations. If someone asks "do we delete user data when they cancel?" the answer is in the schema, not in the PRD.
- When you find a table you don't recognize, check its foreign keys. A mysterious `audit_logs` table that references `users` and `orders` tells you the system logs who does what. That's useful context even if nobody mentioned it in onboarding.
- JSON columns are the wild west. They can contain anything and they often do. If you see a `metadata` JSONB column, ask engineering what goes in there. It's usually where the "we'll figure out the schema later" decisions live, and it often contains important product data that's invisible to standard queries.
- Status columns are product state machines encoded in the database. Map them out. When a PM says "what happens after a user cancels?" the answer is in the state transitions. If `cancelled` can go back to `active`, re-subscriptions are supported. If it can't, they're not.
- Count the columns in each table. A `users` table with 40 columns is a different beast than one with 10. Wide tables often mean the product has evolved over time and accumulated fields that may not all be in use. That's a signal to run the dead-code-audit on the corresponding model.
- Share the entity relationship summary with your team. It's the kind of artifact that saves five minutes of explanation in every meeting where someone asks "wait, how does X relate to Y?" Pin it in Slack. Put it in Notion. Make it findable. The five minutes you save compounds across every person who would have asked the same question.
- If you find tables with no foreign keys pointing to or from them, they're either standalone utilities (like feature_flags or config) or they're orphaned. Orphaned tables are dead weight. Flag them for eng to confirm.
- Prisma schemas live in `prisma/schema.prisma` — look there first for Node/TypeScript projects. That single file defines every model, relation, and enum. If it's not in there, it's not in the database.
- Django models are the schema — check `models.py` in each app directory. There's no separate schema file; the Python classes ARE the table definitions. Run through every app folder and read every `models.py` to get the full picture.
- Rails uses `db/schema.rb` as the source of truth, not the migration files. Migrations show history, but `schema.rb` shows the current state. Always start there.

## Sample Output

```
Summary:
[INFO] 18 tables total — grouped into user data (5), product data (4),
       transaction data (6), system data (3)
[INFO] Core entities: users, workspaces, projects — these 3 tables are
       referenced by almost everything else in the schema
[WARNING] 4 tables contain PII: users (email, name), billing_profiles
          (address, card_last4), sessions (ip_address), audit_logs (action history)

Entity Breakdown (excerpt):

| Table             | What It Stores                              | Key Relationships                          |
|-------------------|---------------------------------------------|--------------------------------------------|
| users             | Every registered account in the product     | Has many projects, has many workspaces     |
| projects          | A unit of work owned by a user or workspace | Belongs to workspace, has many tasks       |
| billing_profiles  | Saved payment methods and billing addresses | Belongs to user, referenced by invoices    |

Privacy Flag:
[WARNING] billing_profiles stores card_last4 and billing_address —
          flag for GDPR data mapping. Soft delete enabled (deleted_at column present),
          so "deleted" billing data is still in the database.
```

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
