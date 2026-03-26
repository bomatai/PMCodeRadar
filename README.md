# PMCodeRadar

### 23 Claude Code Skills for Product Managers Who Refuse to Be Spectators

> Built by **Boma Tai-Osagbemi** | [pmplaybook.ai](https://pmplaybook.ai)

---

## The Problem

Most PMs treat the codebase like a foreign country. They know it exists. They've seen photos. They've never been.

So when eng says "not possible," they nod. When the funnel drops, they Slack the analyst. When a feature ships broken, they write the post-mortem instead of preventing it.

PMCodeRadar changes that. 23 Claude Code skills that turn your terminal into a codebase co-pilot. You don't need to write code. You need to read it — and know what to do with what you find.

Each skill installs as a standalone Claude Code skill in `~/.claude/skills/`. No plugins, no config files, no dependencies. Just copy, restart, and go.

---

## Three Levels

### Level 1 — Stop accepting "not possible"
4 skills that help you challenge engineering objections with actual data from the actual code. "Not possible" usually means "not obvious."

### Level 2 — Stop being the PM who has to ask
10 skills that give you answers before you need to ask anyone. Know your product's error messages, tracking events, API surface, database schema, and navigation map — without waiting for someone to get back to you.

### Level 3 — Change how people treat you in the room
6 skills that give you architectural insight most PMs never develop. Walk into design reviews with dependency maps. Know the blast radius of removing a service. Surprise legal with a PII audit they didn't ask for. This is how you earn a different kind of respect.

### Meta — Get Started
2 skills: one that diagnoses your repo and tells you exactly where to begin, and one that lists every available skill.

---

## Quick Start

**Time:** 5 minutes. **Coding required:** None. **Things you can break:** Nothing.

### Before You Begin

You need two things:

1. **Claude Code** — the CLI tool from Anthropic (not the chat app, not the API).
   If you don't have it yet, install it first: [Claude Code installation guide](https://docs.anthropic.com/en/docs/claude-code)
2. **A terminal** — Terminal on Mac, PowerShell on Windows. If you've never opened a terminal before, search your computer for "Terminal" (Mac) or "PowerShell" (Windows) and open it.

That's it. You don't need to know how to code.

---

### Install the Skills

Pick one method. Option A is easier.

#### Option A: Run the Install Script (Recommended)

The install script copies all 23 skills into `~/.claude/skills/` and verifies everything — so you don't have to.

**Step 1.** Open your terminal (PowerShell on Windows, Terminal on Mac/Linux).

**Step 2.** Navigate to the PMCodeRadar folder you downloaded. Replace the example path below with the **actual path** where you saved it:

**Windows (PowerShell):**
```powershell
# First, allow PowerShell to run scripts (one-time setup):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then navigate to your PMCodeRadar folder and run the installer:
cd "C:\Users\YourName\Downloads\PMCodeRadar"
.\install.ps1
```

**Mac/Linux:**
```bash
# Navigate to your PMCodeRadar folder and run the installer:
cd ~/Downloads/PMCodeRadar
chmod +x install.sh
./install.sh
```

> **Not sure what path to use?** Open File Explorer (Windows) or Finder (Mac), find the PMCodeRadar folder, and look at the address bar. That's your path. On Windows you can also right-click the folder while holding Shift and select "Copy as path."

**Step 3.** Follow the on-screen prompts. The script will tell you if anything goes wrong.

**Step 4.** Close Claude Code completely and reopen it.

**Step 5.** Navigate to any codebase and type:
```
/pmcoderadar
```

> **If the install script worked, you're done.** Skip to [Your First 10 Minutes](#your-first-10-minutes) below.

---

#### Option B: Manual Install (If the Script Didn't Work)

Do this step by step. Don't skip any.

**Step 1 — Create the skills folder** (if it doesn't exist yet):

Mac/Linux:
```bash
mkdir -p ~/.claude/skills
```

Windows (PowerShell):
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills" -Force
```

**Step 2 — Copy each skill folder into it:**

Mac/Linux:
```bash
cp -r ~/Downloads/PMCodeRadar/skills/* ~/.claude/skills/
```

Windows (PowerShell):
```powershell
Copy-Item -Recurse -Path "C:\Users\YourName\Downloads\PMCodeRadar\skills\*" -Destination "$env:USERPROFILE\.claude\skills\" -Force
```

> Replace the download path with wherever you actually saved PMCodeRadar.

After copying, your `~/.claude/skills/` folder should contain 23 subfolders (e.g. `pmcoderadar/`, `error-audit/`, `schema-explain/`, etc.), each with a `SKILL.md` inside. That's the only file structure that matters.

**Step 3 — Restart Claude Code.** Close it completely and reopen it.

**Step 4 — Verify it works.** Navigate to any codebase and type:
```
/pmcoderadar
```

If you see output about your repo, you're good. If you see "skill not found," check the [Troubleshooting](#troubleshooting) section below.

---

### Your First 10 Minutes

After installation, here's exactly what to do:

1. **Open your terminal**, `cd` into any codebase you work on, and start Claude Code.
2. **Run setup first**: `/pmcoderadar` — it scans your repo and tells you what to run next.
3. **Try one of these beginner skills:**

| Try This | What It Does | Why Start Here |
|----------|-------------|----------------|
| `/schema-explain` | Explains your database in plain English | Finally understand what the product actually stores |
| `/error-audit` | Shows every error message users see | Find "Something went wrong" messages you didn't know existed |
| `/dead-code-audit` | Finds unused features and code | Quick win — show eng what can be cleaned up |

**Good to know:**
- Every skill will ask you for a target directory if you don't specify one. You don't need to memorize paths.
- These skills **only read** your code. They never change, delete, or commit anything.
- If something looks wrong, just close Claude Code. Nothing persists.

---

## All 23 Skills

| # | Skill | Command | Level | One-Liner |
|---|-------|---------|-------|-----------|
| 1 | Technical Constraint Analyzer | `/constraint-analysis` | 1 | Break down eng objections into real vs. perceived constraints |
| 2 | Tech Debt Cost Estimator | `/debt-cost-estimate` | 1 | Translate tech debt into product cost with numbers |
| 3 | Pre-Ship Impact Scanner | `/pre-ship-scan` | 1 | Catch breaking conflicts before they ship |
| 4 | Dead Code & Feature Audit | `/dead-code-audit` | 1 | Find unused code eating eng capacity |
| 5 | Event Tracking Inventory | `/event-inventory` | 2 | Map every analytics event to user actions |
| 6 | Duplicate Functionality Check | `/duplicate-check` | 2 | Find existing features before you spec new ones |
| 7 | Database Schema Explainer | `/schema-explain` | 2 | Explain the database in product terms |
| 8 | Error Handler Audit | `/error-audit` | 2 | Audit every error message users see |
| 9 | API Surface Mapper | `/api-surface-map` | 2 | List every public endpoint in plain English |
| 10 | Onboarding Path Audit | `/onboarding-audit` | 2 | Trace signup-to-activation in the code |
| 11 | Data Validation Audit | `/validation-audit` | 2 | Find every input limit and rejection rule |
| 12 | User Route Audit | `/route-audit` | 2 | Map every page and navigation path |
| 13 | Notification System Audit | `/notification-audit` | 2 | List every email, push notification, and alert |
| 14 | Search Logic Audit | `/search-audit` | 2 | Explain how search works in plain English |
| 15 | Architecture Impact Map | `/architecture-map` | 3 | Full dependency map of any proposed change |
| 16 | Service Removal Impact Audit | `/removal-impact` | 3 | Blast radius if you deprecate a service |
| 17 | Data Privacy Compliance Audit | `/privacy-audit` | 3 | Every PII location in the codebase |
| 18 | Feature Flag Impact Audit | `/flag-audit` | 3 | Every flag, what it gates, what breaks if removed |
| 19 | Third-Party Dependency Map | `/dependency-map` | 3 | Every external vendor and what depends on it |
| 20 | Migration Risk Assessment | `/migration-risk` | 3 | Risk map for database migrations |
| 21 | Setup & Repo Diagnostic | `/pmcoderadar` | Meta | Scan your repo and get personalized skill recommendations |
| 22 | Skill Catalog | `/catalog` | Meta | See the full list of available skills and workflows |
| 23 | Feedback | `/feedback` | Meta | Share feedback and suggest improvements |

---

## How to Use

### Basic Usage

Navigate to any git repository and invoke a skill:

```
/constraint-analysis
```

Each skill will ask you for a target directory if you don't provide one.

### With a Target

Point a skill at a specific module:

```
/error-audit /src/api/
```

### Pick and Choose

Don't want all 23? Just copy the skill folders you want into `~/.claude/skills/`:

```bash
# Example: just the constraint analysis and error audit skills
cp -r PMCodeRadar/skills/constraint-analysis ~/.claude/skills/constraint-analysis
cp -r PMCodeRadar/skills/error-audit ~/.claude/skills/error-audit
```

Each skill is self-contained — no dependencies on the others.

### Example Workflow

A typical PM session might look like:

1. **Start with setup**: `/pmcoderadar` — get the lay of the land
2. **Map the surface**: `/api-surface-map` — know what your product exposes
3. **Understand the data**: `/schema-explain` — know what your product stores
4. **Find the waste**: `/dead-code-audit` — find what can be cleaned up
5. **Check the errors**: `/error-audit` — know what users see when things break
6. **Before shipping**: `/pre-ship-scan` — catch conflicts before deploy

### Output Format

Every skill outputs in three layers:

1. **Summary** — 3-5 bullet findings with severity tags (`[CRITICAL]`, `[WARNING]`, `[INFO]`)
2. **Full Breakdown** — detailed table (shown on request)
3. **Share-Ready Snippet** — pre-written Slack/email message you can paste directly to eng

---

## UX Features

Every skill includes:

- **Smart Triggers** — invoke with the command name or natural language ("audit my error messages")
- **Guided Prompts** — if you forget to specify a target, the skill asks instead of failing
- **Progressive Disclosure** — summary first, details on request
- **Severity Tagging** — `[CRITICAL]`, `[WARNING]`, `[INFO]` across all skills
- **Cross-Skill Recommendations** — each skill suggests what to run next
- **Share-Ready Output** — every result includes a Slack/email snippet for eng

---

## Skill Cross-Reference Map

Each skill recommends related skills to run next. Here's the full map:

```
                        /pmcoderadar
                          |
            +-------------+-------------+
            v             v             v
     LEVEL 1          LEVEL 2        LEVEL 3
   (Challenge)    (Self-Serve)    (Lead the Room)

   constraint --> architecture --> removal-impact
   -analysis      -map              |
       |              |              v
       v              v          dependency-map
   pre-ship <-- route-audit
   -scan    |        |
       |    |        v
       v    +-- onboarding
   dead-code       -audit
   -audit  |        |
       |   |        v
       v   +-- event-inventory
   debt-cost
   -estimate        |
                    v
              +-- error-audit --> notification
              |                    -audit
              v
         validation --> schema --> privacy-audit
         -audit        -explain
                          |
              +-----------+
              v
         api-surface --> duplicate
         -map             -check
                                    flag-audit
                                       |
                                       v
                                  migration-risk
                                       |
                                       v
                                  search-audit
```

**Common workflows:**

| Goal | Run These (in order) |
|------|---------------------|
| **New to the codebase** | setup → schema-explain → api-surface-map → route-audit |
| **Preparing to ship** | pre-ship-scan → error-audit → notification-audit |
| **Roadmap planning** | dead-code-audit → debt-cost-estimate → constraint-analysis |
| **Architecture review** | architecture-map → dependency-map → removal-impact |
| **Privacy/compliance** | privacy-audit → schema-explain → validation-audit |
| **Onboarding optimization** | onboarding-audit → event-inventory → validation-audit |
| **Partner integration prep** | api-surface-map → schema-explain → dependency-map |

---

## Troubleshooting

### "Skill not found" or command doesn't work

1. **Did you restart Claude Code?** After installing, you must close and reopen Claude Code for it to pick up new skills.
2. **Are the skills in the right directory?** Each skill should be a folder inside `~/.claude/skills/` with a `SKILL.md` inside (e.g. `~/.claude/skills/pmcoderadar/SKILL.md`). Not nested deeper.
3. **Did you copy the right thing?** The install script handles this, but if you did it manually: copy the _contents_ of `PMCodeRadar/skills/` into `~/.claude/skills/`, not the PMCodeRadar folder itself.

### "I ran a skill but nothing happened"

- Make sure you're inside a git repository. Open your terminal, navigate to the repo, then open Claude Code from there.
- Try being more specific: `/error-audit /src/` instead of just `/error-audit`.

### "The output is too long / too short"

- Every skill starts with a **Summary** (3-5 bullets). It then asks if you want the **Full Breakdown**. If you're getting too much, just say "summary only." If you're getting too little, say "show me the full breakdown."

### "I don't know which skill to run"

- Start with `/pmcoderadar` — it scans your repo and recommends skills based on what it finds.
- Or use the [Common Workflows](#skill-cross-reference-map) table above to pick a workflow that matches your goal.

### Install script errors

**Windows: "running scripts is disabled on this system"**
This is the most common issue. PowerShell blocks scripts by default. Fix it once:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Then run `.\install.ps1` again.

**Windows: script runs but nothing happens / path error**
Make sure you `cd` into the actual PMCodeRadar folder first. The script needs to be in the same folder as the `skills/` directory. If you downloaded a zip, you may need to unzip first and cd into the inner folder.

**Mac/Linux: "Permission denied"**
```bash
chmod +x install.sh
./install.sh
```

---

## How It Works (Under the Hood)

Each skill is a single `SKILL.md` file inside its own folder in `~/.claude/skills/`. Claude Code automatically discovers skills in this directory when it starts up. No settings file changes needed, no plugin registration.

```
~/.claude/skills/
  pmcoderadar/SKILL.md
  error-audit/SKILL.md
  schema-explain/SKILL.md
  constraint-analysis/SKILL.md
  ... (23 total)
```

Each `SKILL.md` contains:
- **Frontmatter** — name and trigger description so Claude knows when to activate the skill
- **Instructions** — what to scan, how to analyze, what format to output
- **Examples** — sample usage and expected output patterns

You can read, edit, or extend any skill. They're just markdown files.

---

## About

**PMCodeRadar** is built by **Boma Tai-Osagbemi**, creator of [pmplaybook.ai](https://pmplaybook.ai) — the PM's guide to building products that matter.

These skills are based on real patterns from real PMs who stopped being spectators in their own product's codebase. They're opinionated, practical, and designed to change how engineering treats you in the room.

### Follow Boma for More

- [pmplaybook.ai](https://pmplaybook.ai) — frameworks, tools, and skills for modern PMs
- **LinkedIn**: Follow Boma Tai-Osagbemi for weekly PM insights and Claude Code tips
- **Newsletter**: Subscribe at [pmplaybook.ai](https://pmplaybook.ai) for the weekly PM playbook

---

## Contributing

Found a bug? Have a skill idea? Want to improve an existing skill?

Open an issue or submit a PR. PMCodeRadar is built for PMs, by PMs.

---

## License

MIT License. Use it. Share it. Make your team better.

---

**Stop being a spectator. Start reading the code.**

*PMCodeRadar by [pmplaybook.ai](https://pmplaybook.ai)*
