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

- Your messages exactly as written
- Claude's responses and the actions it took
- **State transitions** — every change is logged as BEFORE and AFTER with the reason, so you can always roll back
- Decisions, reasoning, and alternatives considered
- Open threads and TODOs

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

A hook fires at the beginning of every Claude Code session, reminding Claude to log the conversation to your active working directory:

```
<your-project>/conversations/2026-04-09.md
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

If you use Claude Code's [status line](https://docs.anthropic.com/en/docs/claude-code/overview), you can add a conversation freshness indicator that shows when the log was last written:

```
Session: [▓▓▓▓░░░░░░] 42% | Weekly: [▓░░░░░░░░░] 15% | Conv: 2m ago
```

This gives you at-a-glance confirmation that logging is active. If you see `Conv: --` or the time keeps growing, Claude is not writing.

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
