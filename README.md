# Ralph (Deadstock Edition)

A dead simple autonomous AI agent loop for Claude Code.

## Why This Setup?

Shoutout to [Matt Pocock](https://x.com/mattpocockuk) for explaining [why the Anthropic Ralph plugin sucks](https://www.aihero.dev/why-the-anthropic-ralph-plugin-sucks).

*TL;DR: The plugin accumulates context across iterations until it bloats and dies. A bash loop starts fresh each turn—just your PRD and progress file. Clean context, every time.*

This is the most bare bones Ralph bash script loop that:
- **Just works** out of the box
- **Uses your existing Claude Code skills** — no extra config needed
- **One file for persistence** — edit `progress.txt` to change behavior, add tests, or bring your own tools
- **Non-opinionated** — aside from recommending [Vercel Agent Browser](https://github.com/vercel-labs/agent-browser) (it's too good not to)

Dead simple. Hackable. The best way to run Ralph loops.

## What is Ralph?

Ralph runs Claude Code in a loop, completing tasks from your PRD one at a time until done. That's it.

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- `jq` (for parsing streaming output)

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Arch
sudo pacman -S jq
```

## Installation

1. Clone this repo:
```bash
git clone https://github.com/topmass/ralph-deadstock ~/Code/ralph-deadstock
```

2. Add an alias to your shell config:

**bash** (`~/.bashrc`):
```bash
alias ralph="$HOME/Code/ralph-deadstock/ralph.sh"
```

**zsh** (`~/.zshrc`):
```bash
alias ralph="$HOME/Code/ralph-deadstock/ralph.sh"
```

**fish** (`~/.config/fish/config.fish`):
```fish
alias ralph="$HOME/Code/ralph-deadstock/ralph.sh"
```

3. Reload your shell:
```bash
source ~/.bashrc  # or ~/.zshrc
```

## Quick Start

### 1. Initialize
```bash
cd your-project
ralph init
```

### 2. Build Your PRD

Open `PRD.md` and define your project. Pro tip: **use Claude to write it for you in planning mode**:

```bash
claude "Read the files in this project and help me write a PRD.md with clear tasks for building [describe your feature]"
```

### 3. Customize Persistent Instructions (optional)

Edit `progress.txt` to change how Ralph behaves. The `RALPH PERSISTENT INSTRUCTIONS` section is read at the start of every iteration.

Default step 5 recommends [Vercel Agent Browser](https://github.com/vercel-labs/agent-browser) for browser testing. Change this to whatever browser testing approach you prefer or remove it entirely.

### 4. Run

```bash
ralph        # One iteration (taste test)
ralph 50     # 50 turns or until done (let it cook)
ralph afk    # Unlimited turns until done (let it cook until well done)
```

Ralph knows when to stop. When all tasks are complete, it outputs:
```
<promise>COMPLETE</promise>
```
This kills the loop early—so `ralph 50` might finish in 12 iterations if the PRD is done.

## How It Works

1. Ralph reads `PRD.md` and `progress.txt`
2. Picks the most important incomplete task
3. Completes it and updates `progress.txt`
4. Repeats until all tasks are done

## Customization

Ralph is intentionally non-prescriptive. The `progress.txt` file controls everything:

- **Testing**: Write your own tests, then add to persistent instructions: "Run `pnpm test` before committing"
- **Linting**: Add "Run `pnpm lint --fix` after code changes"
- **Patterns**: Add "Follow existing patterns in src/components"

Make it yours.

## Docker (Recommended for Autonomous Mode)

When running `ralph afk` or high iteration counts, consider running in Docker for isolation:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  your-claude-image \
  ralph 100
```

## Files

```
ralph-deadstock/
├── ralph.sh           # The main script
├── templates/
│   ├── PRD.md         # PRD template
│   └── progress.txt   # Progress template with persistent instructions
└── README.md
```

## License

MIT
