## Conversation Logging (MANDATORY)

For **every** project session, save the full conversation as a structured log. Do this without being asked.

**Where:** `<active-working-subfolder>/conversations/YYYY-MM-DD.md`
- Save conversations in the specific subfolder you are actively working in (e.g., `my-project/auth-service/conversations/`), not the project root.
- If the session spans multiple subfolders, save to the primary one (where most work happened).
- If `conversations/` does not exist, create it.
- File name is the date in `YYYY-MM-DD.md` format. If a file already exists for today, append a new session block (do not overwrite).
- If the folder (or any parent) is a git repo, add `conversations/` to its `.gitignore`.
- A SessionStart hook fires a reminder about this. The hook cannot determine the active subfolder — that is your responsibility based on conversation context.

**What to save:**
- User messages exactly as written
- Your replies and the actions you took (tool calls, files written/edited, key findings)
- Decisions, clarifications, and reasoning
- **State transitions** — whenever something changes (config, code, architecture, approach), log BOTH the before state and the after state. This is critical for rollback. If the user says "go back to how it was before," the conversation log is the only place that captures what "before" looked like. Format: `**BEFORE:** <what it was> → **AFTER:** <what it became> — **WHY:** <reason for the change>`
- Open threads / next-time TODOs at the bottom

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
