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

That is it. The installer:
1. Copies the session hook to `~/.claude/scripts/`
2. Registers it as a `SessionStart` hook in `~/.claude/settings.json`
3. Appends conversation logging instructions to `~/.claude/CLAUDE.md`

### Windows (Git Bash)

```bash
git clone https://github.com/saikodi/claude-conversations.git
cd claude-conversations
bash install.sh
```

## How It Works

### Session Start

A hook fires at the beginning of every Claude Code session, creating the `conversations/` directory and reminding Claude to log:

```
<your-project>/conversations/2026-04-09.md
```

### Deterministic Reminders (PostToolUse)

A second hook fires after every tool call. It checks a timestamp file (`conversations/.last_write`) and, if more than 5 minutes have elapsed since the last write, injects a reminder directly into Claude's context. Claude sees the reminder and writes the log.

This is deterministic because:

- **No tool calls = no activity = nothing to log.** If Claude is idle, the hook does not fire, and there is nothing to write.
- **Tool calls = Claude is working = the hook fires.** Every tool call checks the clock. Once the interval elapses, Claude gets the reminder on the very next tool call.
- **No repeated nagging.** The hook touches the timestamp when it fires, so it will not remind again until the next interval.
- **Multi-session safe.** The timestamp is per-directory (`conversations/.last_write`). Two sessions in the same project share the timestamp — the first to trigger writes, the second sees the fresh timestamp and skips.
- **Idle-safe.** If you leave a session open for hours with no activity, no tool calls fire, no reminders trigger, no empty writes happen.

You can tune the interval:

```bash
export CLAUDE_CONV_INTERVAL=600  # 10 minutes instead of default 5
```

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

**Can I share conversation logs with my team?**
The logs are local by default. Team sharing is a future consideration that requires privacy filtering (people say things to Claude they would not say in a PR description). For now, this is a personal productivity tool.

**What if I have multiple Claude Code sessions in the same project on the same day?**
Each new session appends to the same daily file. Sessions are separated by frontmatter blocks.

## License

MIT
