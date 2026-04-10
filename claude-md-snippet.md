## Conversation Logging (MANDATORY)

For **every** project session, save the full conversation as a structured log. Do this without being asked.

**Where:** `<active-working-subfolder>/conversations/YYYY-MM-DD.md`
- Save conversations in the specific subfolder you are actively working in (e.g., `my-project/auth-service/conversations/`), not the project root.
- If the session spans multiple subfolders, save to the primary one (where most work happened).
- If `conversations/` does not exist, create it.
- File name is the date in `YYYY-MM-DD.md` format. If a file already exists for today, append a new session block (do not overwrite).
- If the folder (or any parent) is a git repo, add `conversations/` to its `.gitignore`.
- A SessionStart hook fires a reminder about this. The hook cannot determine the active subfolder — that is your responsibility based on conversation context.

**What to save — THIS IS A TRANSCRIPT, NOT A SUMMARY:**

This is not a report. This is not a summary of outcomes. Memory already does that. The conversation log exists specifically to capture what memory cannot: the actual back-and-forth, the reasoning, the failed attempts, and the previous states. If it reads like a polished document, you are doing it wrong.

- **User messages quoted verbatim** — exactly as typed, not paraphrased. Use `>` blockquotes. If the user said "this @#$% API keeps timing out," log that, not "user reported API timeout issues."
- **Your replies** — what you actually said back, not a summary of what you did. Include your reasoning, recommendations, and explanations.
- **Tool calls and results** — what you ran, what came back, what you learned from it. Not every tool call, but the ones that shaped decisions or revealed something.
- **Failed approaches** — what you tried that did not work and why it failed. This is one of the most valuable things to log. Memory only stores the approach that worked. Next session, the user will ask "why did we not just do X?" and the answer is in the log.
- **Decisions and alternatives considered** — when choosing between options, log what the options were, why one was chosen, and why the others were rejected.
- **State transitions** — whenever something changes (config, code, architecture, approach), log BOTH the before state and the after state. This is critical for rollback. If the user says "go back to how it was before," the conversation log is the only place that captures what "before" looked like. Format: `**BEFORE:** <what it was> → **AFTER:** <what it became> — **WHY:** <reason for the change>`
- **Open threads / next-time TODOs at the bottom** — what is unfinished, what needs follow-up, what the user said they would do. Every session log must end with this section.

**Example of what NOT to do (too summarized):**
```
Sai's request: Query New Relic for checkout errors.
Actions taken: Ran 6 NRQL queries. Saved results.
Key findings: Error growth of 43%.
```

**Example of what TO do (actual transcript):**
```
> Query New Relic for checkout and place-order errors from Feb 1 to April 10.
> Here are the 6 queries I want you to run...

Ran Q1 (transaction errors by URI). Got 12 results — top error is "Array to string
conversion" on /order endpoint with 27,861 occurrences. This looks like a code
regression, not an infrastructure issue.

Q5 failed — Log table query timed out. The LIKE scan across 2+ months is too
expensive. We would need to narrow the time window or use a different approach
like querying by specific log attributes instead of free-text search.

> What about the temporal-place-order service?

Ran Q3 — got 0 results. The appName filter did not match. Tried alternate names
but the service may not be reporting TransactionErrors to NR. Need to check if
it uses Span events instead.

**BEFORE:** Assumed all services report TransactionError events
→ **AFTER:** temporal-place-order likely uses Span/Log events only
— **WHY:** Q3 returned 0 results despite known errors in this service
```

**Frontmatter format:**
```markdown
---
name: <Project Name> — YYYY-MM-DD Session
description: <one-line summary of what the session covered>
type: project
---
```

**When to write:** At the end of each meaningful exchange, and definitely before the session ends. Do not wait to be asked. If the conversation is long, update incrementally.

**Performance:** Conversation logging must NEVER block or slow down the main work. Always write conversation logs asynchronously — use background agents, `run_in_background` bash calls, or batch writes during natural pauses. Never make the user wait for logging.

**When to read:** If the user references a prior conversation ("we talked about this", "yesterday we discussed", "remember when", "bring it back"), ALWAYS check the conversation logs before responding. Never say "I don't know what you're talking about" without first checking the logs.

**How to read (context-efficient):** Conversation logs live on disk, NOT in context. Never preload them at session start. When you need to reference a prior conversation:
1. Use Grep to search across `<working-subfolder>/conversations/*.md` for the relevant keyword or topic
2. Read only the specific lines/section you need (use offset + limit), not the whole file
3. Extract the answer, then move on — do not keep the conversation content in context
