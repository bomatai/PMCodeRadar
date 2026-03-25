---
name: privacy-audit
description: >
  Use this skill to find every location where PII is stored, processed, or transmitted in a codebase.
version: 1.0
  Trigger on /privacy-audit or when the user says things like
  "where is PII stored", "data privacy audit", "find personal data", "GDPR compliance check",
  "where do we store user data", "PII scan", "privacy compliance", "data handling audit",
  or "what personal data are we collecting."
  Also trigger when a PM is preparing for a compliance review, responding to a legal request,
  or needs to understand the data footprint before a privacy-related feature launch.
---

# Data Privacy Compliance Audit

> Level 3 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Legal asks "where is user PII stored?" and the room goes quiet. Engineering says "mostly in the database." Mostly. That word does a lot of heavy lifting when regulators come knocking. The truth is PII ends up everywhere — database tables, log files, API responses, error tracking services, analytics payloads, cache layers, third-party vendor calls, CSV exports sitting in /tmp, test fixtures committed to the repo with realistic-looking data. Nobody has a complete map because nobody's ever built one from the code. They build it from memory, and memory is wrong. When you walk into the compliance review with every PII location documented, the type of data at each location, and whether it's encrypted — legal won't expect it. That's the point.

## What This Does

Scans the entire codebase to find every location where personally identifiable information is stored, processed, logged, cached, or transmitted. Classifies the data type (email, name, address, payment info, IP address, device ID), identifies the storage mechanism (database, log, cache, API call, file), and flags whether appropriate protections are in place. Produces a compliance-ready PII map that legal can actually use.

## When to Use This

- Legal or compliance is asking for a data inventory and nobody has one
- You're launching a feature that handles new types of user data and need to audit the existing footprint
- A GDPR, CCPA, or SOC 2 audit is coming and you need to prepare
- You suspect PII is leaking into logs, error tracking, or analytics where it shouldn't be
- A data breach response requires knowing exactly what data is stored where
- You're evaluating a new third-party vendor and need to understand current data flows first
- A "right to be deleted" request came in and you need to know every location to purge

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan everything from there for a full compliance audit. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which directory to scan — just start scanning.

### Step 2: Analysis

Scan every file in scope for PII patterns and data handling. This isn't just string matching — it's tracing data flows from input to storage to output. Look for:

- **Database schemas and models** — Table definitions, column names, ORM models that store user data. Flag columns named email, name, phone, address, ssn, dob, date_of_birth, ip_address, device_id, credit_card, and similar patterns. Also check for generic columns like "metadata" or "payload" that might contain embedded PII
- **API request/response bodies** — Endpoints that accept or return PII in payloads. Check request validation schemas, response serializers, and GraphQL type definitions for personal data fields
- **Log statements** — Any logging that includes user data. This means console.log, logger.info, logger.debug, logger.error with user objects, email addresses, request bodies, or interpolated user fields. This is the most common compliance gap in every codebase
- **Error tracking** — Sentry, Bugsnag, Datadog, or similar integrations that might capture PII in error context. Check setUser, setContext, addBreadcrumb, and exception handler payloads
- **Analytics events** — Mixpanel, Amplitude, Segment, or custom analytics that track user-identifiable properties. Check track(), identify(), and page() calls for PII in event properties
- **Cache operations** — Redis, Memcached, or in-memory cache storing user data. Check what's serialized into cache values, and whether TTL and encryption are configured
- **Third-party API calls** — Data sent to external vendors. Stripe customer objects include email and name. Twilio calls include phone numbers. SendGrid calls include email addresses. Each is a PII transmission point
- **File storage** — S3 uploads, local file writes, CSV exports, PDF generation containing user data. Check for temp files that aren't cleaned up
- **Environment variables** — API keys or tokens that grant access to PII stores. These aren't PII themselves but they're the keys to PII
- **Email/notification templates** — Templates that interpolate user data (name, email, account details, order info). These generate PII-containing messages
- **Test fixtures and seed data** — Test files containing real or realistic PII. This is a compliance gap nobody thinks about until an auditor finds it
- **Backup and migration scripts** — Scripts that dump, transform, or move user data. These often skip encryption and access controls
- **Cookies and browser storage** — Cookies, localStorage, and sessionStorage that store PII in the frontend. Check for document.cookie writes, localStorage.setItem, and sessionStorage.setItem calls that persist user emails, names, tokens with user identifiers, or preferences tied to identity. These are accessible to any JavaScript on the page, including third-party scripts and browser extensions
- **GraphQL introspection responses** — GraphQL schemas that expose PII field names (email, phone, ssn, dateOfBirth) through introspection queries. If introspection is enabled in production, anyone can query the schema and discover exactly which PII fields exist and how to request them. Check whether introspection is disabled in production and whether PII field names are exposed in the type system

For each PII location found, assess:
- **Data type**: What category of PII? Contact info (email, phone, address). Financial (payment card, bank account). Identity (SSN, passport, DOB). Behavioral (IP, device ID, browsing history). Health (medical records, conditions)
- **Protection status**: Encrypted at rest? Encrypted in transit? Hashed? Tokenized? Plaintext?
- **Retention**: Is there a TTL, deletion mechanism, or retention policy? Or does it persist indefinitely?
- **Access control**: Who/what can read this data? Is access logged? Are there role restrictions?
- **Minimization**: Is only the necessary data collected, or is the full object stored when only one field is needed?

### Step 3: Output

**Summary** (always shown first):
- `[CRITICAL]` PII found in logs or error tracking with no redaction — [N] locations
- `[CRITICAL]` Plaintext sensitive data (passwords, SSNs, payment info) — [N] locations
- `[CRITICAL]` PII in test fixtures committed to version control — [N] files
- `[WARNING]` PII sent to third-party vendors without documented DPA — [N] locations
- `[WARNING]` No TTL or deletion mechanism for PII stores — [N] locations
- `[WARNING]` Over-collection: full objects stored when only specific fields needed — [N] locations
- `[INFO]` Total PII touchpoints across the codebase: [N] locations, [M] data types

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Location | Data Type | Storage | Protected? | Retention | Access | Risk Level |
|----------|-----------|---------|------------|-----------|--------|------------|
| users table, email column | Email address | PostgreSQL | Encrypted at rest | No TTL (permanent) | App + admin | `[INFO]` Acceptable |
| users table, password column | Password | PostgreSQL | bcrypt hashed | No TTL | App only | `[INFO]` Acceptable |
| logger.info(req.body) in auth.js:45 | Full request body (includes password) | Log files | Plaintext | 30-day rotation | Ops team | `[CRITICAL]` PII in logs |
| Sentry.setUser() in error-handler.js:12 | User object (name, email, id) | Sentry cloud | Vendor-encrypted | Sentry retention | Sentry admins | `[WARNING]` Verify DPA exists |
| analytics.track('purchase') in checkout.js:89 | Email, purchase amount, address | Mixpanel | Vendor-encrypted | Mixpanel retention | Analytics team | `[WARNING]` Over-collection — only need user_id |
| /tmp/export-*.csv in export-service.js:34 | Full user records (name, email, phone, address) | Local filesystem | Plaintext | No cleanup mechanism | Server access | `[CRITICAL]` Unprotected PII with no TTL |
| Redis cache key user:{id} in session.js:56 | Session data with email, preferences | Redis | No encryption | 24h TTL | App services | `[WARNING]` Add encryption to cache |
| test/fixtures/users.json | Realistic names, emails, phones | Git repository | Plaintext in VCS | Permanent (committed) | All repo contributors | `[WARNING]` Use synthetic data |
| backup-users.sh:12 | Full user table dump | Backup server | No encryption noted | Unknown | DevOps | `[CRITICAL]` Unencrypted PII backup |

**PII Flow Diagram** (text-based):

```
User Input (browser/app)
  |-> API endpoint (HTTPS — encrypted in transit)
      |-> Database (encrypted at rest) — ACCEPTABLE
      |-> Log file (plaintext) — CRITICAL: add PII redaction
      |-> Sentry error context — WARNING: minimize to user_id only
      |-> Redis cache — WARNING: add encryption, verify TTL
      |-> Analytics vendor — WARNING: reduce to user_id, verify DPA
      |-> CSV export to /tmp — CRITICAL: add encryption + auto-cleanup
      |-> Backup script — CRITICAL: add encryption to backup files
      |-> Test fixtures — WARNING: replace with synthetic data
```

**Data Type Inventory**:

| Data Type | Category | Locations Found | Encrypted? | Deletion Path Exists? |
|-----------|----------|----------------|------------|----------------------|
| Email address | Contact | 8 locations | 5/8 encrypted | Partial (DB yes, logs no) |
| Full name | Contact | 6 locations | 4/6 encrypted | Partial |
| Phone number | Contact | 3 locations | 2/3 encrypted | Yes |
| IP address | Technical | 4 locations | 0/4 encrypted | No |
| Password | Credential | 2 locations | 1/2 (DB hashed, log plaintext) | N/A |
| Payment card | Financial | 1 location | Tokenized via Stripe | Yes (Stripe handles) |

**GDPR/CCPA Readiness Check**:

| Requirement | Status | Gap |
|-------------|--------|-----|
| Right to access (data export) | Partial | No automated export mechanism |
| Right to deletion | Partial | DB deletion exists, but logs/cache/backups retain PII |
| Data minimization | Failing | Analytics and error tracking collect more than needed |
| Encryption at rest | Partial | DB encrypted, logs/cache/exports not |
| Vendor DPAs | Unknown | Need to verify Sentry, Mixpanel, SendGrid agreements |
| Breach notification data | Available | PII map enables rapid breach scope assessment |

**Share-Ready Snippet**:

> Completed a PII audit of [scope]. Found [N] locations where personal data is stored or transmitted:
>
> - [X] CRITICAL issues: PII in logs, unencrypted exports, plaintext backups
> - [Y] WARNING items: third-party vendors without verified DPAs, over-collection in analytics
> - [Z] data types tracked: [list types]
>
> Key gaps for GDPR/CCPA: no automated deletion path for logs, cache, and backups. Analytics over-collecting. Recommended immediate actions: add log redaction, encrypt exports, verify vendor DPAs. Full PII map with remediation steps available.

**Remediation Priority Matrix**:

| Issue | Severity | Fix Complexity | Fix Description | Priority |
|-------|----------|---------------|-----------------|----------|
| PII in logs | `[CRITICAL]` | Low | Add redaction middleware to logger | Fix this week |
| Unencrypted file exports | `[CRITICAL]` | Medium | Encrypt exports, add TTL cleanup job | Fix this sprint |
| Unencrypted backups | `[CRITICAL]` | Medium | Add encryption to backup scripts | Fix this sprint |
| Error tracking PII | `[WARNING]` | Low | Reduce Sentry context to user_id only | Fix this sprint |
| Analytics over-collection | `[WARNING]` | Low | Replace user object with user_id in track calls | Fix next sprint |
| Test fixture PII | `[WARNING]` | Low | Replace with Faker-generated synthetic data | Fix next sprint |
| Missing vendor DPAs | `[WARNING]` | Non-technical | Legal to review and execute DPAs | Initiate this week |
| Cache encryption | `[WARNING]` | Medium | Enable encryption on Redis, verify TTL | Fix next sprint |

### Step 4: Next Steps

- "Run `/schema-explain` on any database table flagged to understand the full data model around PII storage"
- "Run `/api-surface-map` to see every API endpoint that accepts or returns PII — useful for building the data flow diagram compliance needs"
- "Run `/architecture-map` to trace how PII flows between services in a microservice architecture"
- "Run `/dependency-map` to verify DPAs exist for every third-party vendor receiving PII"

## Sample Usage

```
"Find every location where PII is stored, processed, or transmitted
in this codebase. Include: what type of data (email, name, address,
payment), where it lives (DB table, log file, API call), and whether
it's encrypted."
```

**More examples:**

```
"We have a GDPR audit next month. Scan the entire repo and build me
a PII inventory. I need every table, log, cache, and third-party
integration that touches personal data. Flag anything that's not
encrypted or doesn't have a deletion mechanism."
```

```
"We're adding phone number collection to the signup flow. Before we
ship, audit everywhere we currently handle PII to make sure we're
not going to repeat any existing gaps. Focus on /src/services/auth/
and /src/services/user-profile/."
```

```
"A user submitted a 'right to be deleted' request. I need to know
every location where their data exists so we can confirm complete
deletion. Map every PII storage point and whether it has an
automated purge mechanism."
```

## Common Patterns This Catches

These are the privacy gaps that show up in almost every codebase. This audit finds all of them:

- **The debug log with PII** — `logger.info('User login:', req.body)` writes the entire request body — including the password — to a plaintext log file that rotates every 30 days. This is in every codebase I've audited. Every single one. The fix is simple (add a redaction middleware), but nobody does it until an auditor or this skill finds it.
- **The Sentry breadcrumb with user context** — Error tracking tools capture context to help engineers debug. That context often includes the user's email, name, and sometimes their request payload. Now PII is sitting in a third-party vendor's cloud with whatever retention policy they default to. The fix: use user_id only in error context.
- **The analytics event with the full user object** — `analytics.track('purchase', { user })` sends the entire user object to Mixpanel or Amplitude. That includes email, name, address, and whatever else is on the user model. The analytics team only needs user_id and event properties. Over-collection is the silent compliance gap.
- **The CSV export with no cleanup** — An export feature writes user data to `/tmp/export-12345.csv`. The export downloads. The temp file stays on the server forever. No encryption. No TTL. No cleanup job. Meanwhile, that file contains full user records accessible to anyone with server access.
- **The test fixture with real data** — `test/fixtures/users.json` contains names, emails, and phone numbers that look real. Maybe they are real — copied from production during debugging and never replaced with synthetic data. That file is committed to version control, visible to every repo contributor, and backed up to cloud storage.
- **The queue message with PII** — Message queues (SQS, RabbitMQ, Kafka) with user data embedded directly in the message payload. The producer serializes the full user object into the message body because it was easier than passing just the user_id and having the consumer look it up. Now PII is sitting in a queue with its own retention policy, potentially replayed during debugging, and visible to anyone with queue read access. Dead letter queues are even worse — failed messages with PII sit there indefinitely until someone manually processes or deletes them.

## Tips

- The most common compliance gap isn't the database — it's the logs. Engineers log request bodies for debugging and forget that those bodies contain passwords, emails, and addresses. Every PII audit I've seen finds at least one instance of plaintext PII in logs. Check logs first. Fix logs first.
- Test fixtures with realistic PII are a compliance risk that nobody thinks about. If your test files contain real-looking names, emails, and phone numbers, and they're committed to a repo that contractors or vendors can access, that's an audit finding. Push for synthetic data generators like Faker.
- Analytics over-collection is the second most common gap. Teams track events with the full user object when they only need a user_id. That means email addresses, names, and sometimes addresses are sitting in Mixpanel or Amplitude with no deletion mechanism. Minimization isn't just a best practice — it's a regulatory requirement.
- Frame the results as "here's what we need to fix before the audit" not "here's everything that's wrong." Same data, very different meeting energy. PMs who help eng fix compliance gaps before auditors find them build lasting trust.
- Run this before any feature launch that involves new user data collection. The best time to fix PII handling is before it ships, not after a compliance team finds it in production. Establishing the audit as a pre-launch gate is how you prevent privacy debt from accumulating.
- Check your message queues. This is the PII hiding spot that even experienced engineers miss. When a producer drops the full user object into an SQS message or Kafka event because it's convenient, that PII now lives in queue infrastructure with its own retention, replay, and dead letter policies — none of which were designed with privacy in mind. Push for passing user_id in messages and having consumers fetch what they need. It's a small architectural change that eliminates an entire class of compliance risk.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
