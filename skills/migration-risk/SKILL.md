---
name: migration-risk
description: >
  Use this skill to assess the risk of a database migration before it ships.
version: 1.0
  Trigger on /migration-risk or when the user says things like
  "migration risk", "database migration impact", "what could this migration break",
  "is this migration safe", "migration rollback plan", "schema change risk",
  "what tables does this migration touch", or "assess the migration before we ship."
  Also trigger when a PM needs to evaluate migration risk before a deploy window,
  understand rollback options, or prepare for a migration-related architecture review.
---

# Migration Risk Assessment

> Level 3 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

There are two kinds of PMs during a database migration. The one who asks "is it done yet?" and the one who asks "what's the rollback plan?" The first PM is a passenger. The second PM earns trust that compounds for years. Because when a migration goes wrong — and eventually one will — the PM who already mapped every table, column, and relationship it touches, who already documented the rollback steps, who already identified which features are at risk during the migration window — that PM doesn't panic. They execute. The rest of the room is scrambling to understand what happened. You already know. That's the difference.

## What This Does

Takes a database migration (or proposed schema change) and maps every table, column, index, and relationship it touches. Identifies which features, services, and queries depend on the affected schema. Assesses what could break during the migration window and what could break permanently if the migration has bugs. Produces a risk assessment with a phased execution plan and a rollback strategy so you go into the deploy window knowing exactly what's at stake.

## When to Use This

- A database migration is scheduled and you need to understand the risk before approving the deploy window
- Engineering is proposing a schema change and you need to know which features are affected
- You're planning a large data model refactor and need to scope the blast radius
- A migration failed in staging and you need to quickly assess the production implications
- You want a rollback plan documented before the migration runs, not after something breaks
- The team is debating whether a migration needs a maintenance window or can run online
- You're evaluating the user impact during the migration execution window

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no migration file or schema change is specified, auto-detect the project root from the current working directory and scan for migration files (e.g., `/db/migrations/`, `/migrations/`, `/prisma/migrations/`, or similar directories). If the repo is very large (10,000+ files), start with the most likely migration directory. Do not ask the user which migration to analyze — just find and scan all pending or recent migration files.

If a migration file is provided, parse it. If a description is provided, search the codebase for the relevant tables and model definitions to understand the current schema before assessing the change.

### Step 2: Analysis

Parse the migration and trace its impact across the codebase. For every table touched, follow the dependency chain to every service, query, and feature that interacts with that table. Assess:

- **Tables modified** — Every table the migration creates, alters, or drops. For ALTER TABLE operations, identify the specific columns, constraints, and indexes being changed
- **Column-level impact** — New columns: nullable or NOT NULL? Default value? Backfill required for existing rows? Dropped columns: what queries, models, and services reference them? Type changes: is the cast implicit and safe, or could it truncate or fail on existing data? Renamed columns: every query referencing the old name breaks
- **Index changes** — New indexes: what's the lock time on the target table? How many rows? Can the index be created concurrently? Dropped indexes: which queries relied on that index for performance? Modified indexes: will the query optimizer choose a different plan?
- **Foreign key and constraint changes** — New constraints: will existing data pass validation? (orphan rows = migration failure). Dropped constraints: what data integrity guarantees are you losing? Cascade rules: does a DELETE CASCADE exist that could wipe rows in related tables?
- **Dependent queries** — Every ORM model, raw SQL query, stored procedure, view, and materialized view that references the affected tables. These are the queries that could break, return wrong results, or slow down after the migration
- **Service dependencies** — Which services read from or write to the affected tables? In a microservice architecture, multiple services might share a database. Cross-service schema dependencies are the highest risk because the migration has to be coordinated with multiple deploys
- **Data volume assessment** — How large are the affected tables? Row count matters because migrations on tables with millions of rows have lock time implications that can cause user-facing downtime. Check table size estimates from model files or schema definitions
- **Migration execution risk** — Will this lock the table? For how long? Is it an online migration (no downtime using tools like gh-ost, pt-online-schema-change) or offline (requires maintenance window)? Will it block reads, writes, or both?
- **Backward compatibility** — Can the old application code run against the new schema during a rolling deploy? If the migration adds a NOT NULL column without a default, the old code will fail on INSERT. This means the migration and code deploy must be coordinated
- **Rollback feasibility** — Can this migration be reversed cleanly? Adding a column is trivially reversible (DROP COLUMN). Dropping a column is NOT reversible without a backup. Renaming is reversible but requires coordinated query updates. Data transformations may be lossy and irreversible
- **Sequence and ordering risks** — If multiple migrations run in sequence, does the order matter? Can a later migration be run independently if an earlier one fails?
- **ORM migration hooks and seed scripts** — Lifecycle hooks (beforeMigrate, afterMigrate in Flyway; pre/post hooks in Sequelize, Rails after_commit callbacks) and seed scripts that execute during or after migration. These can trigger side effects: sending emails, calling external APIs, updating caches, or writing to other tables. A migration that looks like a simple schema change might trigger a seed script that backfills data by calling a third-party API 10 million times. Check for migration hooks, seed files, and any callbacks attached to the ORM's migration lifecycle
- **Materialized view refresh implications** — Materialized views that depend on tables being modified. Altering a source table can invalidate a materialized view, cause refresh failures, or change the data the view returns. If a materialized view is used by a dashboard or reporting query, the refresh failure is silent — the view serves stale data until someone notices. Check for CREATE MATERIALIZED VIEW, REFRESH MATERIALIZED VIEW, and any scheduled refresh jobs tied to the affected tables
- **Supabase migrations** — raw SQL files in `supabase/migrations/*.sql` — not ORM-managed, applied via `supabase db push` or `supabase migration up`. These are plain SQL with no rollback generation — assess each statement individually for reversibility
- **RLS policy changes** — `CREATE POLICY`, `ALTER POLICY`, `DROP POLICY` in migration files — these can accidentally expose or restrict data access. A dropped policy on a table with RLS enabled makes that table inaccessible; a badly scoped new policy can leak data across tenants
- **`SECURITY DEFINER` functions** — functions that bypass RLS — changes to these affect privilege escalation. If a migration modifies a SECURITY DEFINER function, it changes what data can be accessed outside normal row-level security rules
- **Supabase Auth trigger modifications** — changes to triggers on `auth.users` table. These triggers fire on signup/login and often handle profile creation, welcome emails, and initial data setup — modifying them can silently break onboarding

### Step 3: Output

**Summary** (always shown first):
- `[CRITICAL]` Irreversible changes: [N] operations that cannot be rolled back without data loss
- `[CRITICAL]` Table lock risk: [N] tables with estimated [row count] rows that may lock during migration
- `[CRITICAL]` Backward incompatibility: [N] changes that require coordinated code deploy (old code breaks on new schema)
- `[WARNING]` Dependent services: [N] services read/write to affected tables — coordination required
- `[WARNING]` Query breakage risk: [N] queries reference affected columns/indexes
- `[WARNING]` Constraint validation: [N] new constraints that may fail on existing data
- `[INFO]` Total schema changes: [N] tables, [M] columns, [P] indexes affected

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Change | Table | Details | Dependent Services | Query Impact | Risk | Rollback |
|--------|-------|---------|-------------------|-------------|------|----------|
| ADD COLUMN subscription_tier | users (12M rows) | VARCHAR(50), nullable, no default | Auth, Billing, Dashboard | No existing query impact | `[INFO]` Safe — nullable, no lock | DROP COLUMN |
| ADD COLUMN billing_cycle_end | users (12M rows) | TIMESTAMP, NOT NULL, default NOW() | Billing, Notifications | Backfill needed for 12M rows | `[WARNING]` Backfill time: ~2 min | DROP COLUMN |
| CREATE INDEX idx_users_tier | users (12M rows) | btree on subscription_tier | All user queries | May change query plans | `[CRITICAL]` Lock: ~3 min on 12M rows | DROP INDEX |
| ADD COLUMN order_status_v2 | orders (45M rows) | ENUM type, nullable | Checkout, Fulfillment, Analytics | No existing query impact | `[WARNING]` Large table, verify lock behavior | DROP COLUMN |
| DROP COLUMN legacy_status | orders (45M rows) | Referenced by 3 queries, 1 view | Reporting (legacy) | 3 queries break, 1 view breaks | `[CRITICAL]` Irreversible, breaks reporting | Restore from backup (2 hr recovery) |
| ADD FK orders.user_id -> users.id | orders (45M rows) | CASCADE on delete | All services writing to orders | Constraint check on all 45M rows | `[CRITICAL]` Fails if orphan rows exist | DROP CONSTRAINT |

**Risk Timeline** (what happens when):

```
PRE-MIGRATION CHECKLIST:
  [ ] Verify no orphaned rows in orders (SELECT WHERE user_id NOT IN users.id)
  [ ] Backup orders.legacy_status column data
  [ ] Notify Auth, Billing, Dashboard, Fulfillment teams of window
  [ ] Verify new code is backward-compatible with old schema
  [ ] Confirm rollback scripts are tested in staging

DURING MIGRATION (estimated: 10-18 minutes):
  0:00  ADD COLUMN subscription_tier (instant — nullable, no lock)
  0:01  ADD COLUMN billing_cycle_end (instant — nullable with default)
  0:02  CREATE INDEX idx_users_tier (~3 min LOCK on 12M rows)
        >>> Users cannot update profiles during this window <<<
  0:05  ADD COLUMN order_status_v2 (instant — nullable)
  0:06  ADD FK orders.user_id -> users.id (~5-8 min validating 45M rows)
        >>> Inserts to orders table blocked during validation <<<
  0:14  DROP COLUMN legacy_status (instant but IRREVERSIBLE)

POST-MIGRATION CHECKLIST:
  [ ] Verify all dependent queries execute correctly
  [ ] Check query performance — no regressions from index changes
  [ ] Backfill billing_cycle_end for existing users (batch job, ~30 min)
  [ ] Confirm reporting queries updated to not use legacy_status
  [ ] Monitor error rates for 2 hours

TOTAL USER-FACING IMPACT:
  - 3 minutes: profile updates blocked (index creation lock)
  - 5-8 minutes: new orders blocked (FK validation lock)
  - Workaround: schedule during low-traffic window (2-4 AM)
```

**Rollback Plan**:

```
IF MIGRATION FAILS AT ANY STEP:

Steps 1-2 (ADD COLUMNS):
  Rollback: DROP COLUMN subscription_tier; DROP COLUMN billing_cycle_end;
  Risk: None — trivially reversible
  Time: instant

Step 3 (CREATE INDEX):
  Rollback: DROP INDEX idx_users_tier;
  Risk: None — index creation is independent
  Time: instant

Step 4 (ADD COLUMN):
  Rollback: DROP COLUMN order_status_v2;
  Risk: None — trivially reversible
  Time: instant

Step 5 (ADD FK):
  Rollback: ALTER TABLE orders DROP CONSTRAINT fk_orders_user_id;
  Risk: None — constraint removal is clean
  Time: instant

Step 6 (DROP COLUMN):
  Rollback: RESTORE FROM BACKUP — requires backup restoration
  Risk: 2-hour recovery window, potential data loss for writes during window
  Time: ~2 hours

RECOMMENDATION:
  Run steps 1-5 in Migration A. Verify for 48 hours.
  Run step 6 in Migration B after bake period.
  This makes Migration A fully reversible with zero data loss risk.
```

**Backward Compatibility Check**:

| Change | Old Code + New Schema | New Code + Old Schema | Coordinated Deploy? |
|--------|----------------------|----------------------|-------------------|
| ADD subscription_tier (nullable) | Safe — column ignored | Safe — column doesn't exist yet | No |
| ADD billing_cycle_end (NOT NULL, default) | Safe — default handles it | Safe — column doesn't exist yet | No |
| CREATE INDEX | Safe — transparent to app | Safe — index doesn't exist yet | No |
| ADD order_status_v2 (nullable) | Safe — column ignored | Safe — column doesn't exist yet | No |
| DROP legacy_status | BREAKS — old code queries this column | Safe — new code doesn't use it | YES — deploy new code FIRST |
| ADD FK constraint | Safe — transparent to app | Safe — constraint not yet applied | No |

**Share-Ready Snippet**:

> Assessed the migration risk for [migration name]. Here's the breakdown:
>
> - [N] tables affected, [M] total schema changes
> - [X] CRITICAL risks: table locks (~[time]), irreversible column drop, FK validation on [row count] rows
> - [Y] services need coordination: [team names]
> - Estimated migration window: [time] with [downtime minutes] of user-facing lock time
> - Backward compatibility issue: legacy_status drop requires deploying new code FIRST
>
> Recommendation: split into two migrations. Migration A (reversible): add columns, create index, add FK. Migration B (after 48-hour bake): drop legacy_status column. Rollback plan documented for every step. Full risk timeline attached.

### Step 4: Next Steps

- "Run `/architecture-map` to see every service that reads from the affected tables — all of them need regression testing post-migration"
- "Run `/schema-explain` on the affected tables to understand the full data model context around the changes"
- "Run `/pre-ship-scan` on the deploy that includes this migration to catch code-level issues before it ships"
- "Run `/flag-audit` if migration behavior is gated by a feature flag — flag-controlled migrations add a layer of conditional logic that changes which schema is active for which users"
- "Run `/removal-impact` if this migration is part of a deprecation — the migration might be removing columns or tables that other services still depend on"

## Sample Usage

```
"We have a database migration adding new columns to the users and orders
tables. Map every table, column, index, and relationship this migration
touches. What could break? What's the rollback plan? What features are
at risk during the migration window?"
```

**More examples:**

```
"Engineering wants to add a foreign key constraint to the orders table
linking to users. The orders table has 45 million rows. Assess the
migration risk — lock time, existing data issues, rollback options.
I need to know if this needs a maintenance window or can run online."
```

```
"We're dropping three columns from the users table that were marked
deprecated six months ago. Before I approve, scan the codebase for
any remaining references to those columns. I need to know if anything
still reads from or writes to them, and what the rollback plan is
if something breaks after removal."
```

```
"There's a migration that changes the type of the 'amount' column in
the transactions table from INTEGER to DECIMAL. Assess the risk —
can existing data be cast safely? What queries might return different
results? What's the user impact if the cast fails on some rows?"
```

## Common Patterns This Catches

These are the migration patterns that cause real incidents. This assessment surfaces all of them:

- **The NOT NULL column without a default during rolling deploy** — The migration adds a NOT NULL column without a default value. The new code handles it. But during a rolling deploy, old application instances are still running — and their INSERT statements don't include the new column. Every write from an old instance fails with a constraint violation. Users see 500 errors for the 2-3 minutes it takes the deploy to roll out. The fix is simple: add the column as nullable first, deploy the new code, then add the NOT NULL constraint. But if nobody checks backward compatibility, this pattern causes an outage every time.
- **The orphan row that blocks FK creation** — The migration adds a foreign key constraint from orders.user_id to users.id. The constraint validation scans all 45 million rows. Row 12,847,293 has a user_id that doesn't exist in the users table — an orphan from a bug fixed six months ago. The migration fails. The table is locked during the failed validation. The rollback takes minutes. Meanwhile, no orders can be placed. The fix: run a pre-migration check for orphan rows and clean them up before the migration runs.
- **The index that locks the table** — CREATE INDEX on a large table acquires a lock that blocks writes for the duration of the index build. On a 50-million row table, that's 5-10 minutes of no writes. For the users table, that means no signups, no profile updates, no password resets. PostgreSQL supports CREATE INDEX CONCURRENTLY, which avoids the lock but takes longer. MySQL has online DDL. The assessment flags every index creation and estimates lock time.
- **The seed script with side effects** — A migration runs cleanly in staging. In production, it triggers an ORM after-migration hook that runs a seed script. The seed script calls an external API to backfill data. That API has rate limits. The seed script hammers the API with 500,000 requests. The API rate-limits you. The seed script fails halfway through, leaving the data in an inconsistent state. The assessment traces migration hooks and seed scripts to catch these hidden side effects.
- **The materialized view that silently serves stale data** — A migration alters a column type in a source table. A materialized view that depends on that table now fails to refresh. The view continues serving the last successfully refreshed data — which is now hours or days old. The reporting dashboard that uses this view shows outdated numbers. Nobody notices until the monthly review when the numbers don't match. The assessment traces materialized view dependencies for every modified table.

## Tips

- Always push for irreversible operations (DROP COLUMN, DROP TABLE, column type narrowing) to be in a separate migration that runs after a bake period. Migration A adds, creates, and modifies. Migration B — days later — removes. This gives you a clean rollback path for everything in Migration A and time to verify nothing is broken before the destructive Migration B runs. This is the single most impactful piece of advice for migration safety.
- Lock time estimates matter more than most PMs realize. A 3-minute table lock on the users table means 3 minutes where no user can sign up, log in, or update their profile. That's not a technical detail — it's a user-facing decision. Push for concurrent index creation (CREATE INDEX CONCURRENTLY in PostgreSQL) and online schema change tools (gh-ost, pt-online-schema-change) whenever possible.
- The PM who asks "what's the rollback plan?" before the migration runs is trusted differently than the PM who asks "what happened?" after it fails. Same information, completely different perception. This skill exists to make you the first PM every single time.
- Check backward compatibility explicitly. If the migration runs before the new code deploys (common in rolling deploys), the old code has to work with the new schema. If you're adding a NOT NULL column without a default, the old code's INSERT statements will fail. This is the most common migration-related incident and it's completely preventable.
- Always ask about materialized views. Engineers think about tables and indexes, but materialized views are the silent downstream dependency that nobody remembers during migration planning. If the migration alters a source table, every materialized view that depends on it needs to be checked. A failed refresh means stale data in dashboards, and stale data in dashboards means bad decisions made with confidence. One question in the review — "do any materialized views depend on this table?" — can save the team a week of debugging bad metrics.
- Run a pre-migration orphan check for any migration that adds foreign key constraints. This is the single most preventable migration failure. A 30-second SELECT query that finds rows violating the constraint before the migration runs is infinitely cheaper than a locked table and a failed migration during the deploy window. Make it part of the pre-migration checklist. If the orphan check finds bad data, you clean it up in a separate migration first, then add the constraint in a follow-up. Two clean migrations beat one that explodes.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
