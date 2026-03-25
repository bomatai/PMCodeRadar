---
name: PMCodeRadar Skill Catalog
description: "Use this skill to see the full list of available PMCodeRadar skills. Trigger on /catalog or when the user says 'what skills are available', 'list all skills', 'show me the menu', 'what can I run', 'skill list', or 'PMCodeRadar catalog'."
version: 1.0
---

# PMCodeRadar Skill Catalog

**IMPORTANT: This skill is READ-ONLY. Do not create, modify, or delete any files. Only read and analyze.**

Print the full catalog of PMCodeRadar skills below, exactly as formatted.

---

## All PMCodeRadar Skills (22)

### Level 1 — Quick Wins (< 2 min)

| # | Name | Command | One-Liner |
|---|------|---------|-----------|
| 1 | Constraint Analysis | `/constraint-analysis` | Find hard limits (rate limits, file size caps, timeouts) buried in code |
| 2 | Debt Cost Estimate | `/debt-cost-estimate` | Estimate eng effort to fix tech debt in PM-friendly terms |
| 3 | Pre-Ship Scan | `/pre-ship-scan` | Last-minute readiness check before a feature ships |
| 4 | Dead Code Audit | `/dead-code-audit` | Find unused code that can be safely removed |

### Level 2 — Deep Dives (2-5 min)

| # | Name | Command | One-Liner |
|---|------|---------|-----------|
| 5 | Event Inventory | `/event-inventory` | Map every analytics event and find tracking gaps |
| 6 | Duplicate Check | `/duplicate-check` | Find redundant logic, repeated components, or copy-paste code |
| 7 | Schema Explain | `/schema-explain` | Translate database schema into plain-English data dictionary |
| 8 | Error Audit | `/error-audit` | Audit error handling: missing catches, vague messages, silent failures |
| 9 | API Surface Map | `/api-surface-map` | Map all API endpoints with auth, methods, and status |
| 10 | Onboarding Audit | `/onboarding-audit` | Trace the new-user onboarding flow for drop-off risks |
| 11 | Validation Audit | `/validation-audit` | Check input validation rules across forms and API inputs |
| 12 | Route Audit | `/route-audit` | Map all app routes with auth requirements and access control |
| 13 | Notification Audit | `/notification-audit` | Inventory all notifications: email, push, in-app, SMS |
| 14 | Search Audit | `/search-audit` | Evaluate search implementation: indexing, ranking, filters |

### Level 3 — Strategic Scans (5-10 min)

| # | Name | Command | One-Liner |
|---|------|---------|-----------|
| 15 | Architecture Map | `/architecture-map` | Generate a system architecture overview for PM consumption |
| 16 | Removal Impact | `/removal-impact` | Predict blast radius of removing a feature or component |
| 17 | Privacy Audit | `/privacy-audit` | Scan for PII exposure, missing consent, GDPR/CCPA risks |
| 18 | Flag Audit | `/flag-audit` | Inventory all feature flags with status and staleness |
| 19 | Dependency Map | `/dependency-map` | Map external dependencies with risk and update status |
| 20 | Migration Risk | `/migration-risk` | Assess risk of a planned migration or major refactor |

### Meta

| # | Name | Command | One-Liner |
|---|------|---------|-----------|
| 21 | Setup | `/setup` | Scan your repo and get personalized skill recommendations |
| 22 | Catalog | `/catalog` | Show this skill list (you are here) |

---

## Quick Start Workflows

Common PM scenarios and the skills to run:

| Scenario | Run These Skills (in order) |
|----------|----------------------------|
| Pre-launch checklist | `/pre-ship-scan` then `/error-audit` then `/privacy-audit` |
| New to a codebase | `/setup` then `/architecture-map` then `/schema-explain` |
| Planning a feature removal | `/removal-impact` then `/flag-audit` then `/dead-code-audit` |
| Sprint planning ammo | `/debt-cost-estimate` then `/constraint-analysis` |
| Analytics review | `/event-inventory` then `/search-audit` |
| Security/compliance prep | `/privacy-audit` then `/validation-audit` then `/route-audit` |
| Onboarding optimization | `/onboarding-audit` then `/notification-audit` then `/event-inventory` |

---

## Getting Started

Run `/setup` for personalized recommendations based on your repo.

---

*PMCodeRadar by pmplaybook.ai*
