---
name: validation-audit
description: >
  Use this skill to find every input validation rule, character limit, and rejection rule in the codebase.
  Trigger on /validation-audit or when the user says things like
  "find all validation rules", "what are our input limits", "validation audit",
  "character limits", "why users get rejected", "form validation check",
  "input restrictions", or "what fields are required."
  Also trigger when a PM is debugging why users can't complete forms, why submissions
  get rejected, or when auditing the gap between what users expect and what the code allows.
version: 1.0
---

# Data Validation Audit

> Level 2 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

A user tried to sign up. Got silently rejected. No explanation. They left. You never knew why.

## What This Does

Finds every input validation rule in the codebase: character limits, regex patterns, required fields, file size caps, rate limits, and every other invisible wall between a user and a successful submission. For each rule, shows you where it lives, what the user sees when they hit it, and whether that limit still makes sense or is a relic from a layout that changed two redesigns ago.

Why can't users paste a 500-character bio? Because someone hardcoded 140 in 2019. Why do international users bounce off the phone number field? Because the regex only accepts US formats. This skill turns invisible rejection into visible, fixable rules.

## When to Use This

- Users complain they "can't submit" something but you can't reproduce the issue
- You're reviewing forms and want to know every hidden constraint before redesigning
- Support tickets mention mysterious rejections with no helpful error messages
- You're building a new feature and need to know what validation patterns already exist
- You suspect legacy limits are blocking users and nobody remembers why they were set
- You're localizing the product and need to know what rules assume US/English formats
- A competitor lets users do something your product doesn't, and you suspect it's a validation rule, not a feature gap

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which directory to scan — just start scanning.

Clarify what matters most:
- **Full audit**: every validation rule everywhere
- **Form-specific audit**: just the user-facing forms
- **API-specific audit**: just the backend validation
- **Cross-check audit**: compare frontend vs. backend rules to find mismatches

### Step 2: Analysis

Scan for every validation rule by searching for:

- **Character limits** — `maxLength`, `minLength`, `max`, `min`, hardcoded string length checks, database column sizes that enforce truncation, textarea limits, title/name field caps
- **Regex patterns** — email validation, phone number formats, URL patterns, username restrictions, password complexity rules, postal code formats, custom input patterns
- **Required fields** — `required`, `NOT NULL`, form validation that blocks submission, API validation that returns 400s, conditional requirements (required only if another field is set)
- **File upload restrictions** — file size caps, allowed file types (MIME types and extensions), image dimension limits, upload count limits, total storage quotas
- **Rate limits** — API rate limiting, submission throttling, retry limits, cooldown periods, per-user vs. per-IP limits
- **Enum restrictions** — dropdown options, allowed values, whitelist/blacklist patterns, country/language/currency restrictions
- **File upload validation** — file size limits vs. what the error message says, allowed extensions vs. MIME type checks (accepting `.jpg` but not checking MIME means a renamed `.exe` gets through), client-side size checks vs. server-side limits (frontend says 10MB, nginx rejects at 5MB with a 413 the user can't parse), missing dimension validation for images (avatar uploads accepting 8000x8000 images that crash the thumbnail generator)
- **Date/time format validation** — date pickers vs. freeform date inputs, timezone handling (does the backend store UTC? does the frontend display local?), date range validation (can the user set an end date before the start date?), locale-specific date formats (MM/DD/YYYY vs. DD/MM/YYYY — swapping month and day silently produces a valid but wrong date), minimum/maximum date boundaries (can a user set a birthday 200 years in the past? can they schedule something for the year 2099?)
- **Password complexity rules** — minimum/maximum length, required character types (uppercase, lowercase, number, symbol), banned passwords or dictionary checks, maximum length caps that silently truncate pasted passwords (a 72-character bcrypt limit that chops a 1Password-generated 128-character password without telling the user), rules that contradict each other (must include a symbol, but only these 4 symbols), and whether the error message actually lists the requirements upfront or only reveals them one at a time after each failed attempt
- **Custom validators** — business logic validation, cross-field validation (e.g., end date must be after start date), conditional requirements, domain-specific rules
- **Silent rejections** — validation that fails without showing the user an error message. The form just doesn't submit. The API returns a 400 with a generic body. The input gets silently truncated
- **Client vs. server mismatches** — frontend says 200 characters, backend says 150. User writes 175, submits, gets a server error they don't understand. These are the worst bugs because they only surface after the user has done the work
- **Hardcoded magic numbers** — limits embedded directly in code with no explanation, no config variable, no comment. Someone typed `140` or `5242880` and walked away
- **Locale-dependent validation** — phone formats that only work for one country, postal codes that assume a specific format, date formats that break for non-US users, name fields that reject accents or non-Latin characters
- **Deprecated but active rules** — validation from a feature that changed but the validation didn't get updated. The UI allows 1000 characters, the database column is still VARCHAR(255)
- **API request body validation vs. frontend form validation mismatches** — systematically compare what the frontend form allows against what the API endpoint actually validates. These often drift apart as different engineers update different layers. The frontend might add a new optional field that the backend rejects. The backend might tighten a regex that the frontend doesn't enforce. Map every field where the two layers disagree about what's valid input — these are the source of "I filled everything out correctly but it still failed" complaints

For each rule found, assess:
1. Is the error message helpful? Does it tell the user what went wrong and how to fix it?
2. Is the limit reasonable? Does it still match the current product design?
3. Do client and server agree? Or can you pass the frontend check and fail on the backend?
4. Is it documented anywhere? Or is it a mystery to everyone including the team that wrote it?

### Step 3: Output

**Summary** (always shown first):
- `[CRITICAL]` Validations that silently reject user input with no error message
- `[CRITICAL]` Client/server validation mismatches — different limits on frontend vs. backend
- `[CRITICAL]` Validation that blocks legitimate users (e.g., email regex rejecting valid addresses with +, international phone formats rejected)
- `[WARNING]` Hardcoded limits with no documentation or config — nobody knows why they exist
- `[WARNING]` Overly restrictive patterns that limit user input unnecessarily
- `[WARNING]` Required fields that may not actually need to be required
- `[INFO]` Total validation rules found, grouped by type
- `[INFO]` Rules with good error messages vs. generic or missing messages

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Field/Input | Validation Type | Rule | Location (Frontend) | Location (Backend) | User-Facing Error | Match? | Still Makes Sense? |
|-------------|----------------|------|--------------------|--------------------|-------------------|--------|-------------------|
| bio | Character limit | max 140 chars | profile.jsx:45 | api/profile.js:78 | None (silent truncation) | Yes | No — was set for old card layout |
| email | Regex | Custom pattern | signup.jsx:12 | validators.js:34 | "Invalid email" | Yes | No — rejects valid emails with + |
| avatar | File size | max 2MB | upload.jsx:88 | upload.js:92 | "File too large" | Yes | Reasonable |
| password | Complexity | 8 chars, 1 upper, 1 number, 1 special | auth.jsx:34 | auth.js:56 | Lists all requirements | Yes | Overly strict per NIST guidelines |
| username | Regex | alphanumeric only | signup.jsx:67 | api/users.js:23 | "Invalid characters" | Yes | No — blocks hyphens and underscores |
| phone | Regex | US format only | profile.jsx:90 | N/A | "Invalid phone number" | N/A — client only | No — blocks international users |
| project name | Character limit | max 50 chars (frontend), max 100 chars (backend) | projects.jsx:15 | api/projects.js:42 | "Name too long" | NO MISMATCH | Frontend is more restrictive than needed |

**Mismatch Report** (highlighted separately):

| Field | Frontend Rule | Backend Rule | Gap | Risk |
|-------|-------------|-------------|-----|------|
| project name | max 50 chars | max 100 chars | Frontend blocks valid input | Low — users never see backend error |
| bio | max 140 chars | max 255 chars | Frontend blocks valid input | Low |
| description | max 500 chars | max 200 chars | Backend rejects what frontend allows | HIGH — users type 300 chars, submit, get error |

**Share-Ready Snippet**:

> I audited every input validation rule in [module/repo, e.g., "the user profile and signup flows"]. Here's what I found:
>
> - [N, e.g., 47] total validation rules across [X, e.g., 6] forms and [Y, e.g., 12] API endpoints
> - [A, e.g., 5] rules that silently reject input with no user-facing error (e.g., bio field silently truncates at 255 characters, file upload fails with no message when over 5MB)
> - [B, e.g., 3] client/server mismatches where frontend and backend enforce different limits (e.g., description field allows 500 chars on frontend but API rejects at 200)
> - [C, e.g., 8] hardcoded limits with no documentation — some dating back to [year, e.g., 2019] (e.g., a 140-character bio limit from the old card layout that was redesigned 2 years ago)
> - [D, e.g., 4] rules that block legitimate users (e.g., phone regex rejects +44 UK numbers, name field strips accents, password max-length silently truncates at 72 chars)
>
> The most impactful fix: [specific finding, e.g., "the description field mismatch — users write 300 characters, pass frontend validation, then get a server error they can't understand. ~200 failed submissions/week in logs."]. I have the full list with file locations and severity ratings if the team wants to review.

### Step 4: Next Steps

- "Run `/error-audit` to see what error messages users actually see when validation fails — many are generic 'something went wrong' messages that don't help"
- "Run `/onboarding-audit` to trace the signup flow and find where validation blocks new users from activating"
- "Run `/schema-explain` to understand the database constraints behind these validation rules — sometimes the limit is in the column definition, not the code"
- "Run `/api-surface-map` to see the full list of API endpoints — then cross-reference which ones have proper request body validation and which accept anything"

## Sample Usage

```
"Find every input validation rule in the codebase: character limits, regex
patterns, required fields, file size caps, rate limits. For each, show me
where it lives and what the user sees when they hit it."
```

**More examples:**

```
"Users keep saying they can't update their profile. Scan /src/profile/ and
/src/api/profile/ and show me every validation rule that could reject their
input. I need to know what limits we're enforcing and whether the error
messages actually explain what went wrong."
```

```
"We're redesigning our forms. Before I write a single spec, I need a
complete inventory of every validation rule, required field, and input
restriction in /src/forms/. Include the ones that are only enforced on
the backend."
```

```
"We're expanding to Europe. Find every validation rule that assumes US
formats — phone numbers, postal codes, date formats, currency. I need
to know what breaks for international users."
```

## Common Patterns This Catches

These are the validation patterns that cause real user pain in almost every codebase. This audit surfaces all of them:

- **The 255-character limit nobody told the PM about** — A database column is VARCHAR(255). The frontend has no character counter. The user writes a 400-character bio, submits, and gets a cryptic server error — or worse, the text gets silently truncated to 255 characters and the user never notices half their content is gone. The limit exists in a migration file from three years ago. Nobody on the current team knows it's there.
- **The frontend that accepts what the API rejects** — The form lets you type 500 characters. The API rejects anything over 200. The user fills out the form, hits submit, and gets a vague "something went wrong." They did everything the UI told them was okay. From their perspective, the product is broken. These mismatches are the number one source of "I filled it out correctly but it didn't work" support tickets.
- **The password rule that blocks 1Password-generated passwords** — Password managers generate long, random passwords. Your system has a maximum length of 72 characters (bcrypt's actual limit) but the error message just says "invalid password." Or the system requires at least one special character but only allows 4 specific symbols — and the password manager used a different one. The user who uses a password manager is your most security-conscious user, and you're punishing them for it.
- **The phone number regex that only works in one country** — The regex was written for US 10-digit numbers. It rejects everything else. International users with +44 or +91 prefixes can't sign up. The field shows no format hint. The error says "invalid phone number" with no guidance on what format is expected. This single regex is silently blocking entire markets.
- **The date picker that doesn't know about timezones** — A user in Tokyo schedules a meeting for March 15. The system stores it in UTC. The confirmation email shows March 14. The user thinks the system is broken, or worse, shows up on the wrong day. Timezone validation isn't just about format — it's about whether the time the user intended is the time the system recorded.

## Tips

- The most dangerous validation rules are the ones with no error message. A user submits, nothing happens, they leave. You never see this in analytics because the event never fires. Your funnel chart shows a drop-off, but it can't tell you the cause was a silent rejection on a bio field. Start your fix list with silent rejections. They're invisible and they're costing you users.
- Client/server mismatches are the source of the worst user experience bugs. The frontend lets you type 500 characters, the backend rejects anything over 255, and the user gets a cryptic "Something went wrong." The user did everything right from their perspective. The product punished them for it. Always cross-check both sides.
- Question every hardcoded limit. Most were set once, by one person, for one reason that no longer exists. A 140-character bio limit probably made sense when the card layout was tiny. The card layout changed two years ago. The limit didn't. Legacy limits are not technical debt in the traditional sense — they're UX debt. The code works fine. The user experience doesn't.
- International users are the canary in the coal mine for bad validation. If your phone regex only accepts US formats, your postal code check assumes 5 digits, or your name field rejects accented characters, you're not just blocking edge cases — you're blocking entire markets. These are usually the easiest fixes with the highest impact for global products.
- When you find a mismatch between frontend and backend, the fix isn't always to make them match. Sometimes the frontend is too restrictive and the backend is right. Sometimes the backend has a database column constraint that should be migrated. Understand the source of truth before deciding which side to change.
- Password validation is where security theater meets user hostility. If your system requires 1 uppercase, 1 lowercase, 1 number, and 1 special character from a list of exactly four symbols — you're not improving security, you're training users to type "Password1!" and call it a day. Meanwhile, the user who pasted a 40-character random string from their password manager gets rejected because it's "too long" or "contains invalid characters." Check your password rules against NIST SP 800-63B. Most of the rules that annoy users are also the ones that don't actually improve security.
- File upload validation is a silent conversion killer because the user has already done the most expensive action — choosing and uploading a file — before they learn it was rejected. If your file size limit error says "file too large" but doesn't say the limit (is it 2MB? 5MB? 10MB?), you're making the user guess. Worse, if the frontend says 10MB but nginx or the API gateway rejects at 5MB, the user gets a network error instead of a validation message. Always check the full upload path: client-side check, server framework limit, reverse proxy limit, and storage service limit. They're almost never aligned.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
