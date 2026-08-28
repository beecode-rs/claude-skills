#!/usr/bin/env bash
set -euo pipefail

# Usage: ralph <task-file.TASK.md> [max-iterations] [sleep-seconds]
# Example: ralph ~/tasks/my-feature.TASK.md 50 3

TASK_FILE="${1:-}"
MAX=${2:-100}
SLEEP=${3:-2}

# Tunables (override via environment)
MAX_TURNS="${RALPH_MAX_TURNS:-50}"        # per-iteration cap on agent turns
STALL_LIMIT="${RALPH_STALL_LIMIT:-5}"     # stop after N iterations with no progress
PROMPT_FILE="${RALPH_PROMPT_FILE:-./RALPH-PROMPT.md}"

CLAUDE_BIN="${CLAUDE_BIN:-claude}"

if [[ -z "$TASK_FILE" ]]; then
    echo "Usage: ralph <task-file.TASK.md> [max-iterations] [sleep-seconds]"
    echo "Example: ralph ~/tasks/my-feature.TASK.md 50 3"
    exit 1
fi

TASK_FILE="$(realpath "$TASK_FILE")"

if [[ ! -f "$TASK_FILE" ]]; then
    echo "Error: Task file not found: $TASK_FILE"
    exit 1
fi

if [[ "$TASK_FILE" != *.TASK.md ]]; then
    echo "Error: Task file must end with .TASK.md"
    exit 1
fi

if [[ -z "${RALPH_PROMPT_FILE:-}" && ! -f "$PROMPT_FILE" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${SCRIPT_DIR}/RALPH-PROMPT.md" ]]; then
        PROMPT_FILE="${SCRIPT_DIR}/RALPH-PROMPT.md"
    fi
fi
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found: $PROMPT_FILE"
    echo "Provide RALPH-PROMPT.md in the working directory, install a copy next to the"
    echo "ralph script, or point RALPH_PROMPT_FILE at it."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required for streaming output"
    exit 1
fi

# Fail fast: CLAUDE_BIN must be a real executable on PATH. Shell aliases
# (like a claude alias in .zshrc) do NOT exist inside scripts — wrap the
# alias in an executable script (e.g. ~/.local/bin/claude) instead.
if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
    echo "Error: claude executable not found: '$CLAUDE_BIN'"
    echo "If '$CLAUDE_BIN' is a shell alias, create an executable wrapper for it,"
    echo "or point CLAUDE_BIN at the real binary (try: command -v claude)."
    exit 1
fi

TASK_DIR="$(dirname "$TASK_FILE")"
TASK_BASENAME="$(basename "$TASK_FILE" .TASK.md)"
PROGRESS_FILE="${TASK_DIR}/${TASK_BASENAME}.progress.txt"
LOG_DIR="${TASK_DIR}/${TASK_BASENAME}.logs"

WORK_DIR="$(pwd)"

# Colors
LIGHT_BLUE="\033[94m"
ORANGE="\033[38;5;208m"
DIM="\033[2m"
RESET="\033[0m"

display_main_header() {
    local message="$1"
    echo -e "${LIGHT_BLUE}===========================================${RESET}"
    echo -e "${LIGHT_BLUE}  $message${RESET}"
    echo -e "${LIGHT_BLUE}===========================================${RESET}"
}

display_iteration_header() {
    local message="$1"
    echo -e "${ORANGE}-------------------------------------------${RESET}"
    echo -e "${ORANGE}  $message${RESET}"
    echo -e "${ORANGE}-------------------------------------------${RESET}"
}

check_git_repository() {
    if ! git -C "$WORK_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        read -r -p "This is not a git repository. Do you want to continue? (y/N) " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Operation cancelled."; exit 1; }
        return
    fi

    local current_branch
    current_branch=$(git -C "$WORK_DIR" rev-parse --abbrev-ref HEAD)

    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        read -r -p "Warning: You are currently on the $current_branch branch. Do you want to continue? (y/N) " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Operation cancelled."; exit 1; }
    fi
}

initialize_progress_file() {
    if [[ ! -s "$PROGRESS_FILE" ]]; then
        printf '# Progress: %s\n\nStarted: %s\n\n---\n' \
            "$TASK_BASENAME" "$(date '+%Y-%m-%d %H:%M')" > "$PROGRESS_FILE"
    fi
    mkdir -p "$LOG_DIR"
}

# Replace {{PLACEHOLDER}} tokens with pure bash — no sed escaping issues
build_prompt() {
    local iteration="$1"
    local prompt
    prompt="$(<"$PROMPT_FILE")"
    prompt="${prompt//\{\{TASK_FILE\}\}/$TASK_FILE}"
    prompt="${prompt//\{\{PROGRESS_FILE\}\}/$PROGRESS_FILE}"
    prompt="${prompt//\{\{ITERATION\}\}/$iteration}"
    printf '%s' "$prompt"
}

count_pending_tasks() {
    grep -cE '^[[:space:]]*[-*] \[ \]' "$TASK_FILE" || true
}

# Stream agent activity to the terminal while logging raw events as jsonl.
# Shows assistant text plus a dim one-liner per tool call.
run_claude_streaming() {
    local prompt="$1"
    local log_file="$2"

    "$CLAUDE_BIN" --dangerously-skip-permissions \
        -p "$prompt" \
        --output-format stream-json \
        --verbose \
        --max-turns "$MAX_TURNS" \
        | tee "$log_file" \
        | jq -r --unbuffered '
            select(.type == "assistant") | .message.content[]?
            | if .type == "text" then
                .text
              elif .type == "tool_use" then
                "\u001b[2m⏺ \(.name): \((.input.file_path // .input.command // .input.pattern // .input.description // .input.prompt // "") | tostring | gsub("\n"; " ") | .[0:160])\u001b[0m"
              else
                empty
              end
        '

    return "${PIPESTATUS[0]}"
}

print_iteration_summary() {
    local log_file="$1"
    jq -r '
        select(.type == "result")
        | "  ↳ turns: \(.num_turns // "?")  cost: $\(.total_cost_usd // 0)  time: \((.duration_ms // 0) / 1000 | round)s"
    ' "$log_file" 2>/dev/null || true
    echo ""
}

extract_result_text() {
    local log_file="$1"
    jq -r 'select(.type == "result") | .result // empty' "$log_file" 2>/dev/null || true
}

report_blocked_tasks() {
    local blocked
    blocked=$(grep -E '^[[:space:]]*[-*] \[!\]' "$TASK_FILE" || true)
    if [[ -n "$blocked" ]]; then
        echo ""
        echo "Blocked tasks that need your attention:"
        echo "$blocked"
    fi
}

run_automation_loop() {
    local stall=0
    local fails=0
    local prev_pending pending result
    prev_pending=$(count_pending_tasks)

    for ((i = 1; i <= MAX; i++)); do
        display_iteration_header "Iteration $i of $MAX"

        local log_file="${LOG_DIR}/iteration-${i}.jsonl"
        local prompt
        prompt=$(build_prompt "$i")

        if ! run_claude_streaming "$prompt" "$log_file"; then
            (( ++fails ))
            if (( fails >= 3 )); then
                display_main_header "Aborting: claude failed $fails times in a row"
                echo "Last log: $log_file"
                exit 1
            fi
            echo -e "${DIM}Warning: claude exited with an error on iteration $i (log: $log_file) — retrying${RESET}" >&2
            sleep "$SLEEP"
            continue
        fi
        fails=0

        print_iteration_summary "$log_file"

        result=$(extract_result_text "$log_file")
        if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
            display_main_header "All tasks complete after $i iterations!"
            report_blocked_tasks
            exit 0
        fi

        # Belt and suspenders: don't rely on the agent remembering the sentinel
        pending=$(count_pending_tasks)
        if (( pending == 0 )); then
            display_main_header "No unchecked tasks left after $i iterations!"
            report_blocked_tasks
            exit 0
        fi

        if (( pending == prev_pending )); then
            (( ++stall ))
            if (( stall >= STALL_LIMIT )); then
                display_main_header "Stalled: no progress for $STALL_LIMIT consecutive iterations"
                echo "Check $PROGRESS_FILE for what keeps failing."
                exit 1
            fi
        else
            stall=0
        fi
        prev_pending=$pending

        if (( i < MAX )); then
            sleep "$SLEEP"
        fi
    done
}

trap 'echo ""; display_main_header "Interrupted at iteration ${i:-0}"; exit 130' INT

check_git_repository
initialize_progress_file

display_main_header "Starting Ralph - Max $MAX iterations"
echo "Working directory: $WORK_DIR"
echo "Task file: $TASK_FILE"
echo "Progress file: $PROGRESS_FILE"
echo "Logs: $LOG_DIR"
echo ""

run_automation_loop

display_main_header "Reached max iterations ($MAX)"
exit 1
