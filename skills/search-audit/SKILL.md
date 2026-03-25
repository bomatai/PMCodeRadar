---
name: search-audit
description: >
  Use this skill to understand how search works in the product at the code level.
  Trigger on /search-audit or when the user says things like
  "how does search work", "search audit", "why can't users find things",
  "search logic explained", "search index audit", "diagnose search issues",
  "search is broken", or "search results are bad."
  Also trigger when a PM is debugging search quality complaints, planning search
  improvements, or needs a plain-English explanation of what the search system actually does.
version: 1.0
---

# Search Logic Audit

> Level 2 | PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai) | Follow Boma Tai-Osagbemi for more

Users say "search is broken." It's not broken. It's searching 3 fields out of 12, ignoring typos, and ranking by creation date instead of relevance. Now you can explain exactly why.

## What This Does

Explains how search actually works in the product at the code level. What fields it queries. How it ranks results. What filters exist. What user input gets ignored or silently dropped. What happens when nothing matches. Turns "search doesn't work" from a vague complaint into a specific diagnosis with actionable fixes.

Gives you a plain-English breakdown you can use in a meeting, a ticket, or a conversation with engineering — without needing to read the code yourself. Most search problems aren't algorithm problems. They're scope problems: the search doesn't look where users expect it to look.

## When to Use This

- Users complain they "can't find anything" and you can't explain why
- You're planning search improvements and need to understand the current implementation before proposing changes
- A stakeholder asks "how does our search work?" and you don't have a confident answer
- Search results feel wrong but nobody can articulate what's wrong about them
- You're evaluating whether to build better search or buy a search service (Algolia, Elasticsearch, etc.)
- Support tickets mention search quality issues and you need a root cause analysis
- You're adding new content types and need to know if they'll be searchable by default or require explicit indexing

**IMPORTANT — READ-ONLY BEHAVIOR:** This skill is strictly read-only. Never ask the user questions. Never offer to delete, modify, or create files. Never ask "Want me to run X next?" or "Should I do Y?" Just scan, analyze, and present the results. If recommending next skills, list them as statements (e.g., "Recommended next: /schema-explain"), not as questions.

## How It Works

### Step 1: Target Selection

If no path is specified, auto-detect the project root from the current working directory and scan for search-related endpoints, then trace from there. If the repo is very large (10,000+ files), start with `/src/` or the most likely top-level source directory. Do not ask the user which directory to scan — just start scanning.

Clarify the focus:
- **Full search audit**: the complete search implementation from query to results
- **Index audit**: what's searchable vs. what's not
- **Ranking audit**: how results are ordered and why
- **Filter audit**: what filtering options exist and what's missing

### Step 2: Analysis

Reverse-engineer the full search implementation by scanning for:

- **Search endpoint(s)** — API routes that handle search queries, GraphQL resolvers with search arguments, server-side search handlers, autocomplete endpoints, typeahead implementations
- **Indexed fields** — which database fields or document properties are actually searchable? Title only? Title + description? Full text of content? Tags? Metadata? Custom fields?
- **Non-indexed fields** — fields that exist in the data model but are NOT included in search. These are the blind spots. Tags? Comments? File contents? Custom attributes? User bios?
- **Search engine** — is it database LIKE queries? Full-text search (Postgres `tsvector`, MySQL FULLTEXT)? Elasticsearch? Algolia? MeiliSearch? Typesense? A third-party API? A combination?
- **Ranking algorithm** — how are results ordered? By relevance score? By date? By popularity? By some custom formula? Is there boosting for exact matches vs. partial matches? Field-level weighting?
- **Query processing** — does it handle typos (fuzzy matching)? Stemming (search "running" finds "run")? Synonyms? Stop word removal? Special character handling? What happens to queries with quotes, operators, or Boolean logic?
- **Tokenization** — how are search terms split? Whitespace only? CamelCase splitting? Hyphen handling? Does "real-time" match "realtime"?
- **Filters** — what filters exist? Category, date range, author, status, type? Are filters AND or OR? Can they be combined? Are filters applied before or after search scoring?
- **Autocomplete/typeahead** — is there a separate autocomplete endpoint? What does it search? How many results does it return? Is it debounced?
- **Pagination** — how many results per page? Is there a maximum? Offset-based or cursor-based pagination? Does deep pagination degrade performance?
- **Input sanitization** — what happens to user input before it becomes a query? Is anything silently stripped? Length limits on queries? HTML/script injection protection?
- **Empty state handling** — what happens when search returns zero results? Suggestions? "Did you mean?" Spelling correction? Blank page? Related content?
- **Performance** — are search queries cached? What's the timeout? What happens when search is slow? Is there a fallback? Are there query complexity limits?
- **Permissions** — does search respect access controls? Can a user find content they shouldn't be able to see? Are results filtered before or after pagination? (This matters enormously for pagination accuracy)
- **Multi-entity search** — does one search box query multiple types (users, projects, documents)? Or are they separate searches?
- **Search analytics and logging** — is the product logging what users search for? Are zero-result queries being captured? This is the goldmine most teams ignore. If you know that 200 users searched for "integrations" last month and got nothing, that's a feature signal AND a search fix. Look for search query logging, zero-result event tracking, click-through tracking on results, and any search analytics dashboard or pipeline. If none of this exists, that's a critical gap — you're flying blind on what users want to find

For each component found, assess:
1. Does it match user expectations? Users expect to find things by any word they remember
2. Are there gaps? Fields that should be searchable but aren't
3. Is the ranking sensible? Does the most relevant result appear first?
4. How does it handle imperfect input? Typos, partial words, wrong order

### Step 3: Output

**Summary** (always shown first):
- `[CRITICAL]` Search ignores fields users expect to be searchable (e.g., tags, descriptions, comments, content body)
- `[CRITICAL]` Search returns results the user doesn't have permission to access (access filtering happens after pagination = wrong counts)
- `[CRITICAL]` No fuzzy matching — a single typo returns zero results instead of close matches
- `[WARNING]` Results ranked by creation date instead of relevance — old content always outranks new, better content
- `[WARNING]` No autocomplete or typeahead — users must type the full query and press enter
- `[WARNING]` Empty state is a dead end — no suggestions, no "did you mean," no related content
- `[INFO]` Search covers [N] fields out of [M] total data fields
- `[INFO]` Search engine: [type] with [filters available]
- `[INFO]` Pagination: [method], [N] results per page

Then immediately show the full breakdown below the summary (no need to ask — always include it).

**Full Breakdown (always included):**

| Component | Implementation | Details | Impact on Users |
|-----------|---------------|---------|-----------------|
| Engine | PostgreSQL full-text search | `tsvector` on 3 columns | Limited fuzzy matching, no synonyms |
| Indexed fields | title, name, email | description, tags, notes NOT indexed | Users can't find items by tag or description |
| Non-indexed | description, tags, comments, file content | 9 out of 12 content fields are invisible to search | Major gap — most user-relevant content is unsearchable |
| Ranking | `ts_rank()` with default weights | No boost for exact matches, no field weighting | Partial matches rank same as exact — feels random |
| Fuzzy matching | None | Exact token match only | "projct" returns 0 results for "project" |
| Tokenization | Whitespace split | No CamelCase, no hyphen handling | "real-time" doesn't match "realtime" |
| Filters | status, created_date | No filter for category, owner, type, or tag | Users can't narrow results effectively |
| Autocomplete | None | Users must type full query + press Enter | Slower, more frustrating search experience |
| Pagination | 20 per page, OFFSET-based | No cursor pagination | Page 50+ is very slow, counts may be wrong |
| Permissions | Post-query filter | Search returns all, then filters by access | Pagination counts are wrong — shows "200 results" but user sees 40 |
| Empty state | "No results found" | No suggestions, no "did you mean" | Dead end for the user |
| Performance | No caching, 5s timeout | No query complexity limits | Complex queries can time out silently |

**Field Coverage Map**:

| Data Field | In Search Index? | Searchable by Users? | Should It Be? |
|-----------|-----------------|---------------------|---------------|
| title | Yes | Yes | Yes |
| name | Yes | Yes | Yes |
| email | Yes | Yes | Depends on context |
| description | No | No | YES — major gap |
| tags | No | No | YES — major gap |
| comments | No | No | Probably yes |
| file content | No | No | Nice to have |
| custom fields | No | No | Yes for power users |
| created_by | No | No | Yes |
| status | Filter only | Filter only | Appropriate |

**Plain-English Explanation** (for stakeholders):

> Here's how search works right now: when a user types a query, we search
> only the title, name, and email fields using PostgreSQL's built-in
> full-text search. We don't search descriptions, tags, comments, or any
> other field. Results are ranked by a basic relevance score with no
> boosting for exact matches. There's no fuzzy matching, so a single typo
> returns zero results. Filters are limited to status and date. There's no
> autocomplete. The zero-results page is a dead end with no suggestions.
>
> The biggest gaps: users can't find items by tag or description (9 of 12
> content fields are invisible to search), typos kill the search entirely,
> and the result count includes items the user can't access — making
> pagination feel broken.

**Share-Ready Snippet**:

> I audited how search works in [product/module]. Here's the plain-English version:
>
> - We search [N] fields out of [M] total — [specific missing fields] are not indexed
> - No fuzzy matching — a single typo returns zero results
> - Results ranked by [method] — not optimized for what users actually want to find first
> - [X] filters available, but [Y] commonly requested ones are missing
> - Zero-results page is a dead end — no suggestions, no "did you mean"
>
> The #1 reason users say "search is broken": [specific finding]. Fix list and technical details attached.

### Step 4: Next Steps

- "Run `/schema-explain` to understand the full data model — see all the fields that COULD be searchable but aren't. This gives you the roadmap for what to add to the index"
- "Run `/validation-audit` to check what input sanitization happens to search queries — users might be typing things that get silently stripped or rejected"
- "Run `/event-inventory` to see if search queries are being logged — you need this data to understand what users are actually searching for and what returns zero results"
- "Run `/error-audit` to check how search handles failure states — a timed-out search with a generic error message feels worse than a slow search with a loading spinner"

## Sample Usage

```
"Explain how search works in this product. What fields are indexed? How
are results ranked? What filters are available? What user input gets
ignored? Give me a plain-English breakdown I can use to diagnose why
users say they can't find things."
```

**More examples:**

```
"Users keep saying search is broken. I need to understand exactly what
happens when someone types a query. Trace the search from input to
results in /src/search/ and tell me what fields we're searching, what
we're ignoring, and how we rank results."
```

```
"I'm writing a spec for search improvements. Before I propose anything,
I need the full picture of how search currently works — the engine,
the indexed fields, the ranking, the filters, everything. Give me
something I can share with the team."
```

```
"We're evaluating Algolia vs. improving our current Postgres search.
Before I can make that call, I need to understand exactly what our
current search does and doesn't do. Full audit of /src/."
```

## Tips

- The most common search problem isn't the algorithm — it's the indexed fields. If you only search titles and users expect to search descriptions, tags, and content, no ranking improvement will fix the complaints. Start by listing what IS and ISN'T searchable. That field coverage map is your highest-leverage diagnosis. One PM found that 9 of 12 fields were invisible to search. Adding 3 more fields to the index resolved 70% of "search is broken" complaints.
- "Search is broken" almost always means one of three things: (1) the field they're searching isn't indexed, (2) a typo returned zero results because there's no fuzzy matching, or (3) the result they wanted was on page 4 because ranking is suboptimal. This audit tells you which one. Don't redesign the entire search experience when the fix might be adding one field to the index.
- Permission-filtered search with wrong pagination counts is a silent UX disaster. If search says "200 results" but the user can only see 40 of them because the other 160 are access-controlled, every page has gaps and the count is a lie. Users don't know their results are being filtered — they just think search is buggy. This is more common than you'd think, especially in B2B products with role-based access. The fix is to filter before pagination, but that often requires an architecture change.
- The zero-results experience is where you lose users permanently. If someone searches, gets nothing, and sees a blank page with no guidance — they've learned that search doesn't work and they'll never trust it again. Even basic suggestions ("try searching for...") or spelling corrections ("did you mean...") dramatically improve the experience. Check whether your zero-state does anything useful.
- Before you evaluate third-party search tools, get the field coverage map from this audit. If your current search only indexes 3 fields and the fix is indexing 8 fields in the same Postgres setup you already have, you don't need Algolia. You need a migration script. Save the vendor evaluation for when you've hit the limits of what your current engine can do with the right data.

---

## Output Footer

At the end of every output, include this line:

```
---
PMCodeRadar v1.0 | pmplaybook.ai | Follow Boma Tai-Osagbemi for more
```
