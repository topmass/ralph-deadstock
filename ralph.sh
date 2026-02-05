#!/bin/bash
set -e

# Ralph - Unified AI agent loop
# Usage:
#   ralph init       - Create PRD.md and progress.txt templates
#   ralph            - Run 1 iteration (human-in-the-loop)
#   ralph 50         - Run up to 50 iterations autonomously
#   ralph afk        - Run until complete (no limit) - use with caution!
#
# Requires: jq (for streaming output)

# Get the directory where this script lives (resolves symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# Handle "ralph init" - just create templates and exit
if [ "$1" == "init" ]; then
  echo "Initializing Ralph in $(pwd)..."

  if [ -f "PRD.md" ]; then
    echo "PRD.md already exists, skipping."
  elif [ -f "$TEMPLATE_DIR/PRD.md" ]; then
    cp "$TEMPLATE_DIR/PRD.md" ./PRD.md
    echo "Created PRD.md - edit this with your project tasks."
  fi

  if [ -f "progress.txt" ]; then
    echo "progress.txt already exists, skipping."
  elif [ -f "$TEMPLATE_DIR/progress.txt" ]; then
    cp "$TEMPLATE_DIR/progress.txt" ./progress.txt
    echo "Created progress.txt"
  fi

  # Prompt for claude.md
  if [ -f ".claude/CLAUDE.md" ]; then
    echo ".claude/CLAUDE.md already exists, skipping."
  elif [ -f "$TEMPLATE_DIR/claude.md" ]; then
    echo ""
    echo "Add CLAUDE.md with testing & code quality guidelines?"
    echo "  [1] Yes (recommended)"
    echo "  [2] No"
    read -p "Choice [1]: " claude_choice
    claude_choice=${claude_choice:-1}
    if [ "$claude_choice" == "1" ]; then
      mkdir -p .claude
      cp "$TEMPLATE_DIR/claude.md" ./.claude/CLAUDE.md
      echo "Created .claude/CLAUDE.md"
    else
      echo "Skipped CLAUDE.md"
    fi
  fi

  echo ""
  echo "Done! Next steps:"
  echo "  1. Edit PRD.md with your project details and tasks"
  echo "  2. Run 'ralph' to test one iteration"
  echo "  3. Run 'ralph 50' to go autonomous"
  exit 0
fi

# Determine iterations
if [ -z "$1" ]; then
  MAX_ITERATIONS=1
elif [ "$1" == "afk" ]; then
  MAX_ITERATIONS=9999  # Effectively unlimited
  echo "WARNING: Running in unlimited mode. Will continue until PRD complete."
  echo "Press Ctrl+C to stop at any time."
  echo ""
else
  MAX_ITERATIONS=$1
fi

# Check and create PRD.md if missing
if [ ! -f "PRD.md" ]; then
  if [ -f "$TEMPLATE_DIR/PRD.md" ]; then
    echo "No PRD.md found. Creating all templates..."
    cp "$TEMPLATE_DIR/PRD.md" ./PRD.md
    echo "  Created PRD.md"

    # Also create progress.txt
    if [ ! -f "progress.txt" ] && [ -f "$TEMPLATE_DIR/progress.txt" ]; then
      cp "$TEMPLATE_DIR/progress.txt" ./progress.txt
      echo "  Created progress.txt"
    fi

    echo ""
    echo "Please edit PRD.md with your project details, then run 'ralph' again."
    exit 0
  else
    echo "Error: PRD.md not found. Run 'ralph init' first or create a PRD.md file."
    exit 1
  fi
fi

# Ensure progress.txt exists (in case user has PRD but no progress.txt)
if [ ! -f "progress.txt" ]; then
  if [ -f "$TEMPLATE_DIR/progress.txt" ]; then
    cp "$TEMPLATE_DIR/progress.txt" ./progress.txt
    echo "Created progress.txt from template."
  else
    echo "# Ralph Progress Log" > progress.txt
  fi
fi

# jq filters for streaming
stream_text='select(.type == "assistant").message.content[]? | select(.type == "text").text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'
final_result='select(.type == "result").result // empty'

# Main loop
for ((i=1; i<=MAX_ITERATIONS; i++)); do
  if [ $MAX_ITERATIONS -gt 1 ]; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    printf "║  RALPH ITERATION %-4s of %-14s║\n" "$i" "$MAX_ITERATIONS"
    echo "╚════════════════════════════════════════╝"
    echo ""
  fi

  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT

  claude \
    --verbose \
    --print \
    --output-format stream-json \
    --dangerously-skip-permissions \
    --setting-sources user \
    "@progress.txt @PRD.md \

Follow the RALPH PERSISTENT INSTRUCTIONS in progress.txt.
Complete ONE task from PRD.md, then update progress.txt and mark the task done.
If you cannot complete it, mark it IN_PROGRESS with notes.

If ALL tasks in PRD.md are complete, output exactly: <promise>COMPLETE</promise>" \
  | grep --line-buffered '^{' \
  | tee "$tmpfile" \
  | jq --unbuffered -rj "$stream_text"

  result=$(jq -r "$final_result" "$tmpfile")

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    printf "║  PRD COMPLETE after %-4s iteration(s)!║\n" "$i"
    echo "╚════════════════════════════════════════╝"
    exit 0
  fi
done

echo ""
if [ $MAX_ITERATIONS -eq 1 ]; then
  echo "Iteration complete. Run 'ralph' again or 'ralph 50' for autonomous mode."
else
  echo "╔════════════════════════════════════════╗"
  printf "║  Completed %-4s iterations (not done) ║\n" "$MAX_ITERATIONS"
  echo "╚════════════════════════════════════════╝"
fi
