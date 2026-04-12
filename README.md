# Claude Conversations

Persistent conversation logging for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview). Never lose context across sessions again.

## The Problem

Claude Code starts every session with a blank slate. It has no memory of what you discussed yesterday, what you tried and failed, or what the code looked like before the last change. You end up repeating yourself, re-explaining context, and losing hours to conversations that should have taken minutes.

Claude Code's built-in memory system helps, but it only stores **outcomes** — the final decision, the conclusion. It does not store:

- **The reasoning** — why you chose Option A over Option B
- **Failed approaches** — what you tried that did not work
- **Previous states** — what the code/config looked like before the change
- **The actual conversation** — what you said, what Claude said, what was considered

When you say "we talked about this yesterday" or "bring it back to how it was," Claude cannot help you because none of that was saved.

## The Solution

Claude Conversations adds a structured logging layer to Claude Code. Every session is automatically logged to a markdown file in your working directory. No external services, no databases, no infrastructure — just markdown files on disk.

### What Gets Logged

This is a **transcript**, not a summary. Memory already stores outcomes. Conversations store everything memory cannot:

- **Your messages quoted verbatim** — exactly as typed, in blockquotes
- **Claude's actual replies** — what it said back, not a polished summary of what it did
- **Failed approaches** — what was tried that did not work and why. Next session you will ask "why did we not just do X?" and the answer is in the log.
- **Decisions and alternatives** — what the options were, why one was chosen, why the others were rejected
- **State transitions** — every change logged as BEFORE and AFTER with the reason, so you can always roll back
- **Open threads and TODOs** — every session ends with what is unfinished

### What Does Not Happen

- **No context bloat** — conversation logs live on disk, not in Claude's context window. They are only read on demand, and only the specific section needed.
- **No slowdown** — logging happens asynchronously in the background. You never wait for it.
- **No sharing** — logs are local to your machine. Nothing leaves your disk.
- **No preloading** — logs are not loaded at session start. Claude searches them only when you reference a past conversation.

## Install

```bash
git clone https://github.com/saikodi/claude-conversations.git
cd claude-conversations
chmod +x install.sh
./install.sh
```

### Windows (Git Bash)

```bash
git clone https://github.com/saikodi/claude-conversations.git
cd claude-conversations
bash install.sh
```

### What the Installer Does

1. Copies three hook scripts to `~/.claude/scripts/`:
   - `claude_conversations_hook.sh` — SessionStart hook
   - `claude_conversations_reminder.sh` — PostToolUse hook
   - `claude_conversations_session_end.sh` — SessionEnd hook
2. Copies the statusline snippet to `~/.claude/scripts/claude_conversations_statusline.sh`
3. Creates `~/.claude/conversation_timestamps/` for per-session timestamp files
4. Registers all three hooks in `~/.claude/settings.json`
5. Appends conversation logging instructions to `~/.claude/CLAUDE.md`

If `settings.json` already exists and `jq` is installed, the installer offers to auto-merge the hooks into your existing config (with a backup). Without `jq`, it prints the JSON you need to add manually.

## How It Works

Three hooks work together to ensure conversations are always logged:

```
┌─────────────────────────────────────────────────────────┐
│  SessionStart Hook                                      │
│  Fires once at session start                            │
│  → Creates per-session timestamp baseline                │
│  → Reminds Claude to begin logging                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  PostToolUse Hook (deterministic enforcement)           │
│  Fires after every tool call                            │
│  → Checks per-session timestamp in                      │
│    ~/.claude/conversation_timestamps/                    │
│  → If ≥5 min elapsed: injects reminder into context     │
│  → Touches timestamp to reset the timer                 │
│  → Sub-10ms — direct path checks, no find/glob          │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  SessionEnd Hook                                        │
│  Fires when session terminates                          │
│  → Deletes per-session timestamp file                   │
│  → Zero accumulation of stale files                     │
└─────────────────────────────────────────────────────────┘
```

### Key Design: Decoupled Timing and Location

Timestamp files live in `~/.claude/conversation_timestamps/`, keyed by session PID. Conversation logs live in `<working-dir>/conversations/`. This decouples **when to remind** (managed by hooks) from **where to write** (decided by Claude from conversation context).

Why this matters: if Claude Code is launched from a parent directory but the actual work happens in a subdirectory, a directory-relative timestamp would track the wrong location. Per-session timestamps in a fixed directory avoid this entirely.

### Hook 1: SessionStart

Fires once at the beginning of every Claude Code session. Creates the per-session timestamp baseline and outputs a message into Claude's context:

```
CONVERSATION LOGGING ACTIVE: Log this session to <working-subfolder>/conversations/2026-04-09.md
— save to the subfolder you are actively working in. If the folder is a git repo, ensure
conversations/ is in .gitignore.
```

This is the initial nudge. Claude reads this and begins logging. But instructions alone are not reliable — Claude sometimes forgets during long sessions. That is what the PostToolUse hook solves.

### Hook 2: PostToolUse (Deterministic Enforcement)

The core mechanism. This hook fires after every tool call and checks a per-session timestamp file (`~/.claude/conversation_timestamps/.conv_last_write_<PID>`):

**First tool call of the session:**
If the timestamp file does not exist, the hook creates it silently and exits. This sets the baseline — no reminder fires on the very first tool call.

**Subsequent tool calls:**
The hook reads the modification time of the timestamp file and compares it to the current time. If the configured interval (default 300 seconds) has elapsed, it:

1. Touches the timestamp file immediately (resets the timer before the reminder, preventing repeated firing)
2. Outputs a reminder directly into Claude's context:

```
CONVERSATION LOG DUE (8m since last write): Write conversation transcript to
./conversations/2026-04-09.md now. Append to existing content if the file exists.
Follow the transcript format in CLAUDE.md — verbatim quotes, tool calls, failed
approaches, state transitions. Write asynchronously (background agent or
run_in_background). Do NOT block the user's work.
```

Claude sees this in its context and writes the log. The reminder includes specific instructions so Claude does not need to look up what to do.

### Hook 3: SessionEnd (Cleanup)

Fires when the session terminates. Deletes the per-session timestamp file (`~/.claude/conversation_timestamps/.conv_last_write_<PID>`). This ensures zero accumulation of stale files — no cleanup logic needed.

### Why This Is Deterministic

| Property | How |
|---|---|
| **No tool calls = no reminder** | Hook only fires on PostToolUse. Idle sessions produce zero overhead. |
| **Tool calls = guaranteed check** | Every tool call checks the clock. Once the interval elapses, the next tool call triggers the reminder. |
| **No repeated nagging** | The hook touches the timestamp before outputting the reminder. The next reminder fires only after another full interval. |
| **Per-session isolation** | Each session has its own timestamp file keyed by PID. Session A writing does not reset Session B's timer. |
| **No stale files** | SessionEnd hook deletes the timestamp file when the session terminates. |
| **Sub-10ms** | One `stat` call, one integer comparison, one `touch`. No `find`, no globbing, no process spawning. |

### Tuning the Interval

```bash
export CLAUDE_CONV_INTERVAL=600  # 10 minutes instead of default 5
```

Set this in your shell profile (`~/.bashrc`, `~/.zshrc`) so it persists across sessions.

### During the Session

Claude logs the conversation incrementally in the background. State transitions are captured in a structured format:

```markdown
**BEFORE:** Order placement was synchronous PHP, single-threaded
→ **AFTER:** Temporal workflow with async execution, deterministic idempotency, OTEL tracing
— **WHY:** Needed retry semantics and observability for distributed order pipeline
```

### Across Sessions

When you reference a past conversation, Claude searches the logs before responding:

```
You: "Remember yesterday we discussed the dual-write approach?"
Claude: [searches conversations/2026-04-08.md, finds the relevant section, picks up where you left off]
```

### File Organization

Conversations are saved in the subfolder you are actively working in:

```
my-project/
  auth-service/
    conversations/
      2026-04-07.md
      2026-04-08.md
      2026-04-09.md
  payment-service/
    conversations/
      2026-04-09.md
```

If the folder is a git repo, `conversations/` is automatically added to `.gitignore`.

## Status Line (Optional)

If you use Claude Code's [status line](https://docs.anthropic.com/en/docs/claude-code/overview), you can add a conversation freshness indicator:

```
Session: [▓▓▓▓░░░░░░] 42% | Weekly: [▓░░░░░░░░░] 15% | Conv: 2m ago
```

The indicator shows three states:

| Status | Meaning |
|--------|---------|
| `Conv: 2m ago` | Log was written 2 minutes ago. All good. |
| `Conv: DUE` | Interval exceeded. Claude should be writing on the next tool call. |
| `Conv: --` | No conversation log exists for today yet. |

A snippet is included at `hooks/statusline_snippet.sh`. Add it to your existing `~/.claude/statusline-command.sh`:

```bash
# At the end of your statusline script, source the snippet:
conv_part=$(bash ~/.claude/scripts/claude_conversations_statusline.sh)
# Then append $conv_part to your output
```

Or copy the logic directly from the snippet into your statusline script.

## Uninstall

```bash
cd claude-conversations
chmod +x uninstall.sh
./uninstall.sh
```

Your existing conversation logs are not deleted.

## FAQ

**Does this use any external services?**
No. Everything is local markdown files on your disk.

**Will this slow down Claude?**
No. Logging is asynchronous. Claude writes logs during natural pauses or in background calls.

**Will this bloat Claude's context window?**
No. Logs are never preloaded. Claude reads them on demand using targeted search (grep + offset/limit), extracting only the lines it needs.

**Does this work with Claude Code's built-in memory?**
Yes. They complement each other. Memory stores curated conclusions. Conversations store the full reasoning, failed approaches, and state transitions that memory does not capture.

**Why two hooks instead of just CLAUDE.md instructions?**
CLAUDE.md instructions are probabilistic — Claude reads them at session start but can forget during long sessions. The PostToolUse hook is deterministic enforcement. It checks a timestamp on every tool call and injects a reminder directly into Claude's context when the interval elapses. Claude cannot ignore what is in its active context.

**Can I share conversation logs with my team?**
The logs are local by default. Team sharing is a future consideration that requires privacy filtering (people say things to Claude they would not say in a PR description). For now, this is a personal productivity tool.

**What if I have multiple Claude Code sessions in the same project on the same day?**
Each new session appends to the same daily file. Sessions are separated by frontmatter blocks.

## License

MIT
