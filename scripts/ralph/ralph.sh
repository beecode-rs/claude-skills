#!/usr/bin/env bash
set -euo pipefail

TASK_FILE=""
MAX=100
SLEEP=2

MAX_TURNS="${RALPH_MAX_TURNS:-50}"
STALL_LIMIT="${RALPH_STALL_LIMIT:-5}"
PROMPT_FILE="$HOME/Nextcloud/box/ai/collection/script/RALPH-PROMPT.md"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

TASK_DIR=""
TASK_BASENAME=""
PROGRESS_FILE=""
REPORT_FILE=""
LOG_DIR=""
WORK_DIR="$(pwd)"

RUN_STARTED_AT=""
RUN_STARTED_TS=0
RUN_OUTCOME=""
ITERATIONS_RUN=0
AGENT_ERRORS=0
STREAM_ERRORS=0
PENDING_AT_START=0
TOTAL_TURNS=0
TOTAL_COST=0
TOTAL_TOOL_CALLS=0
MODEL_USED=""

LIGHT_BLUE="\033[94m"
ORANGE="\033[38;5;208m"
DIM="\033[2m"
RESET="\033[0m"

print_error() {
    echo "Error: $1"
}

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

print_usage() {
    echo "Drive a Ralph automation loop on a task file with claude."
    echo
    echo "Usage: ralph.sh <task-file.TASK.md> [max-iterations] [sleep-seconds]"
    echo
    echo "Arguments:"
    echo "  <task-file.TASK.md>   task file to run (must end with .TASK.md)"
    echo "  [max-iterations]      loop cap (default: 100)"
    echo "  [sleep-seconds]       pause between iterations (default: 2)"
    echo
    echo "Environment:"
    echo "  RALPH_MAX_TURNS=N     per-iteration cap on agent turns (default: 50)"
    echo "  RALPH_STALL_LIMIT=N   stop after N iterations with no progress (default: 5)"
    echo "  CLAUDE_BIN=path       claude executable to call (default: claude)"
    echo
    echo "Example:"
    echo "  ralph.sh ~/tasks/my-feature.TASK.md 50 3"
}

parse_arguments() {
    case "${1:-}" in
        -h|--help) print_usage; exit 0 ;;
    esac
    if (( $# > 3 )); then
        print_error "Too many arguments"
        print_usage
        exit 1
    fi
    TASK_FILE="${1:-}"
    MAX="${2:-100}"
    SLEEP="${3:-2}"
}

check_task_file_given() {
    if [[ -z "$TASK_FILE" ]]; then
        print_usage
        exit 1
    fi
}

resolve_task_file_path() {
    TASK_FILE="$(realpath "$TASK_FILE")"
}

check_task_file_exists() {
    if [[ ! -f "$TASK_FILE" ]]; then
        print_error "Task file not found: $TASK_FILE"
        exit 1
    fi
}

check_task_file_extension() {
    if [[ "$TASK_FILE" != *.TASK.md ]]; then
        print_error "Task file must end with .TASK.md"
        exit 1
    fi
}

check_prompt_file_exists() {
    if [[ ! -f "$PROMPT_FILE" ]]; then
        print_error "Prompt file not found: $PROMPT_FILE"
        exit 1
    fi
}

check_jq_installed() {
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required for streaming output"
        exit 1
    fi
}

check_claude_installed() {
    if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
        print_error "claude executable not found: '$CLAUDE_BIN'"
        echo "If '$CLAUDE_BIN' is a shell alias, create an executable wrapper for it,"
        echo "or point CLAUDE_BIN at the real binary (try: command -v claude)."
        exit 1
    fi
}

resolve_run_paths() {
    TASK_DIR="$(dirname "$TASK_FILE")"
    TASK_BASENAME="$(basename "$TASK_FILE" .TASK.md)"
    PROGRESS_FILE="${TASK_DIR}/${TASK_BASENAME}.progress.txt"
    REPORT_FILE="${TASK_DIR}/${TASK_BASENAME}.report.md"
    LOG_DIR="${TASK_DIR}/${TASK_BASENAME}.logs"
    WORK_DIR="$(pwd)"
}

check_git_repository() {
    local confirm
    if ! git -C "$WORK_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        read -r -p "This is not a git repository. Do you want to continue? (y/N) " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { RUN_OUTCOME="cancelled at startup: not a git repository"; echo "Operation cancelled."; exit 1; }
        return
    fi

    local current_branch
    current_branch=$(git -C "$WORK_DIR" rev-parse --abbrev-ref HEAD)

    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        read -r -p "Warning: You are currently on the $current_branch branch. Do you want to continue? (y/N) " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { RUN_OUTCOME="cancelled at startup: on $current_branch branch"; echo "Operation cancelled."; exit 1; }
    fi
}

initialize_progress_file() {
    if [[ ! -s "$PROGRESS_FILE" ]]; then
        printf '# Progress: %s\n\nStarted: %s\n\n---\n' \
            "$TASK_BASENAME" "$(date '+%Y-%m-%d %H:%M')" > "$PROGRESS_FILE"
    fi
    mkdir -p "$LOG_DIR"
}

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

format_duration() {
    local total="$1"
    local hours=$(( total / 3600 ))
    local minutes=$(( (total % 3600) / 60 ))
    local seconds=$(( total % 60 ))
    if (( hours > 0 )); then
        printf '%dh %dm %ds' "$hours" "$minutes" "$seconds"
    elif (( minutes > 0 )); then
        printf '%dm %ds' "$minutes" "$seconds"
    else
        printf '%ds' "$seconds"
    fi
}

init_run_tracking() {
    RUN_STARTED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
    RUN_STARTED_TS="$(date +%s)"
    PENDING_AT_START="$(count_pending_tasks)"
}

add_cost() {
    TOTAL_COST="$(awk -v running="$TOTAL_COST" -v added="$1" 'BEGIN { printf "%.4f", running + added }')"
}

detect_model_from_log() {
    local log_file="$1"
    local model
    model="$(jq -sr '[.[] | select(.type == "system" and .subtype == "init")] | first | .model // empty' "$log_file" 2>/dev/null || true)"
    if [[ -n "$model" && -z "$MODEL_USED" ]]; then
        MODEL_USED="$model"
    fi
}

accumulate_iteration_stats() {
    local log_file="$1"
    local turns cost tool_calls error_results

    turns="$(jq -sr 'map(select(.type == "result")) | last | .num_turns // 0' "$log_file" 2>/dev/null || true)"
    cost="$(jq -sr 'map(select(.type == "result")) | last | .total_cost_usd // 0' "$log_file" 2>/dev/null || true)"
    tool_calls="$(jq -sr '[.[] | .message.content[]? | select(.type == "tool_use")] | length' "$log_file" 2>/dev/null || true)"
    error_results="$(jq -sr 'map(select(.type == "result" and .is_error == true)) | length' "$log_file" 2>/dev/null || true)"

    TOTAL_TURNS=$(( TOTAL_TURNS + ${turns:-0} ))
    TOTAL_TOOL_CALLS=$(( TOTAL_TOOL_CALLS + ${tool_calls:-0} ))
    STREAM_ERRORS=$(( STREAM_ERRORS + ${error_results:-0} ))
    add_cost "${cost:-0}"
    detect_model_from_log "$log_file"
}

write_run_report() {
    local exit_code="$1"
    local ended_at duration pending_now outcome

    ended_at="$(date '+%Y-%m-%d %H:%M:%S')"
    duration=$(( $(date +%s) - RUN_STARTED_TS ))
    pending_now="$(count_pending_tasks)"

    if [[ -n "$RUN_OUTCOME" ]]; then
        outcome="$RUN_OUTCOME"
    elif (( exit_code == 0 )); then
        outcome="finished"
    else
        outcome="unexpected failure"
    fi

    {
        if [[ -s "$REPORT_FILE" ]]; then
            printf '\n___\n\n'
        fi
        printf '%s\n' "# Run Report - $RUN_STARTED_AT"
        printf '\n'
        printf '%s\n' "- **Status:** $outcome (exit $exit_code)"
        printf '%s\n' "- **Agent:** claude ($CLAUDE_BIN)"
        printf '%s\n' "- **Model:** ${MODEL_USED:-not recorded in logs}"
        printf '%s\n' "- **Task file:** $TASK_FILE"
        printf '%s\n' "- **Started:** $RUN_STARTED_AT"
        printf '%s\n' "- **Ended:** $ended_at"
        printf '%s\n' "- **Duration:** $(format_duration "$duration") (${duration}s)"
        printf '%s\n' "- **Iterations:** $ITERATIONS_RUN of max $MAX"
        printf '%s\n' "- **Steps:** $TOTAL_TURNS agent turns, $TOTAL_TOOL_CALLS tool calls"
        printf '%s\n' "- **Errors:** $AGENT_ERRORS agent failures, $STREAM_ERRORS error results"
        printf '%s\n' "- **Cost:** \$$TOTAL_COST"
        printf '%s\n' "- **Tasks pending:** $PENDING_AT_START at start, $pending_now at end"
        printf '%s\n' "- **Working directory:** $WORK_DIR"
        printf '%s\n' "- **Logs:** $LOG_DIR"
    } >> "$REPORT_FILE"
}

handle_interrupt() {
    RUN_OUTCOME="interrupted by user"
    echo ""
    display_main_header "Interrupted at iteration ${i:-0}"
    exit 130
}

handle_terminate() {
    RUN_OUTCOME="terminated by SIGTERM"
    exit 143
}

run_automation_loop() {
    local stall=0
    local fails=0
    local prev_pending pending result
    prev_pending=$(count_pending_tasks)

    for ((i = 1; i <= MAX; i++)); do
        display_iteration_header "Iteration $i of $MAX"
        ITERATIONS_RUN=$i

        local log_file="${LOG_DIR}/iteration-${i}.jsonl"
        local prompt
        prompt=$(build_prompt "$i")

        if ! run_claude_streaming "$prompt" "$log_file"; then
            (( ++fails ))
            (( ++AGENT_ERRORS ))
            detect_model_from_log "$log_file"
            if (( fails >= 3 )); then
                RUN_OUTCOME="aborted: claude failed $fails times in a row"
                display_main_header "Aborting: claude failed $fails times in a row"
                echo "Last log: $log_file"
                exit 1
            fi
            echo -e "${DIM}Warning: claude exited with an error on iteration $i (log: $log_file), retrying${RESET}" >&2
            sleep "$SLEEP"
            continue
        fi
        fails=0

        accumulate_iteration_stats "$log_file"
        print_iteration_summary "$log_file"

        result=$(extract_result_text "$log_file")
        if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
            RUN_OUTCOME="completed: agent promised all tasks done"
            display_main_header "All tasks complete after $i iterations!"
            report_blocked_tasks
            exit 0
        fi

        pending=$(count_pending_tasks)
        if (( pending == 0 )); then
            RUN_OUTCOME="completed: no unchecked tasks left"
            display_main_header "No unchecked tasks left after $i iterations!"
            report_blocked_tasks
            exit 0
        fi

        if (( pending == prev_pending )); then
            (( ++stall ))
            if (( stall >= STALL_LIMIT )); then
                RUN_OUTCOME="stalled: no progress for $STALL_LIMIT consecutive iterations"
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

set_signal_traps() {
    trap handle_interrupt INT
    trap handle_terminate TERM
    trap 'write_run_report $?' EXIT
}

display_run_header() {
    display_main_header "Starting Ralph - Max $MAX iterations"
    echo "Working directory: $WORK_DIR"
    echo "Task file: $TASK_FILE"
    echo "Progress file: $PROGRESS_FILE"
    echo "Report file: $REPORT_FILE"
    echo "Logs: $LOG_DIR"
    echo ""
}

finish_at_max_iterations() {
    RUN_OUTCOME="stopped: reached max iterations ($MAX)"
    display_main_header "Reached max iterations ($MAX)"
    exit 1
}

run_startup_checks() {
    check_task_file_given
    resolve_task_file_path
    check_task_file_exists
    check_task_file_extension
    check_prompt_file_exists
    check_jq_installed
    check_claude_installed
    resolve_run_paths
}

run_ralph() {
    init_run_tracking
    set_signal_traps
    check_git_repository
    initialize_progress_file
    display_run_header
    run_automation_loop
    finish_at_max_iterations
}

parse_arguments "$@"
run_startup_checks
run_ralph
