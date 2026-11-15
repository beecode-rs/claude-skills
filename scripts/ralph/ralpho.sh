#!/usr/bin/env bash
set -euo pipefail

TASK_FILE=""
MAX=100
SLEEP=2

SUPPRESS_THINKING="${RALPH_SUPPRESS_THINKING:-}"
STALL_LIMIT="${RALPH_STALL_LIMIT:-5}"
PROMPT_FILE="$HOME/Nextcloud/box/ai/collection/script/RALPH-PROMPT.md"
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"
MODEL="zai-coding-plan/glm-5.3"
MODEL_WAS_CHOSEN=false
THINKING_FLAG=()

MODEL_REFS=()
MODEL_LABELS=()

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
TOTAL_STEPS=0
TOTAL_COST=0
TOTAL_TOOL_CALLS=0
TOKENS_IN=0
TOKENS_OUT=0

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
    echo "Drive a Ralph automation loop on a task file with opencode."
    echo
    echo "Usage: ralpho.sh <task-file.TASK.md> [max-iterations] [sleep-seconds] [model]"
    echo
    echo "Arguments:"
    echo "  <task-file.TASK.md>   task file to run (must end with .TASK.md)"
    echo "  [max-iterations]      loop cap (default: 100)"
    echo "  [sleep-seconds]       pause between iterations (default: 2)"
    echo "  [model]               provider/model ref; omit it for the interactive picker (Z.AI + Ollama models)"
    echo
    echo "Environment:"
    echo "  RALPH_SUPPRESS_THINKING=1   run opencode without --thinking (thinking is on by default)"
    echo "  RALPH_STALL_LIMIT=N         stop after N iterations with no progress (default: 5)"
    echo "  OPENCODE_MODEL=ref          pin the model and skip the picker"
    echo "  OPENCODE_BIN=path           opencode executable to call (default: opencode)"
    echo
    echo "Example:"
    echo "  ralpho.sh ~/tasks/my-feature.TASK.md 50 3 zai-coding-plan/glm-5.3"
}

parse_arguments() {
    case "${1:-}" in
        -h|--help) print_usage; exit 0 ;;
    esac
    if (( $# > 4 )); then
        print_error "Too many arguments"
        print_usage
        exit 1
    fi
    TASK_FILE="${1:-}"
    MAX="${2:-100}"
    SLEEP="${3:-2}"
    if [[ -n "${OPENCODE_MODEL:-}" || -n "${4:-}" ]]; then
        MODEL="${OPENCODE_MODEL:-${4:-}}"
        MODEL_WAS_CHOSEN=true
    fi
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

check_opencode_installed() {
    if ! command -v "$OPENCODE_BIN" >/dev/null 2>&1; then
        print_error "opencode executable not found: '$OPENCODE_BIN'"
        echo "If '$OPENCODE_BIN' is a shell alias, create an executable wrapper for it,"
        echo "or point OPENCODE_BIN at the real binary (try: command -v opencode)."
        exit 1
    fi
}

set_thinking_flag() {
    if [[ -n "$SUPPRESS_THINKING" ]]; then
        return
    fi
    THINKING_FLAG=(--thinking)
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

add_model_group_header() {
    local title="$1"
    MODEL_REFS+=("")
    MODEL_LABELS+=("$title")
}

add_model_entry() {
    local ref="$1"
    local label="$2"
    MODEL_REFS+=("$ref")
    MODEL_LABELS+=("$label")
}

add_sorted_model_entries() {
    local entry
    while IFS= read -r entry; do
        if [[ -z "$entry" ]]; then continue; fi
        add_model_entry "${entry%%|*}" "${entry#*|}"
    done < <(printf '%s\n' "$@" | LC_ALL=C sort -t'|' -k1,1)
}

collect_zai_models() {
    add_model_group_header "Z.AI Coding Plan"
    add_sorted_model_entries \
        "zai-coding-plan/glm-5.3|GLM-5.3 (Free)" \
        "zai-coding-plan/glm-5.3-flash|GLM-5.3-Flash (Free)" \
        "zai-coding-plan/glm-5.3-highspeed|GLM-5.3 Highspeed"
}

collect_ollama_models() {
    local refs ref
    refs=()

    local models_cmd
    models_cmd=("$OPENCODE_BIN" models)
    command -v timeout >/dev/null 2>&1 && models_cmd=(timeout 10 "${models_cmd[@]}")
    while IFS= read -r ref; do
        if [[ -n "$ref" ]]; then
            refs+=("$ref")
        fi
    done < <("${models_cmd[@]}" 2>/dev/null | LC_ALL=C grep '^ollama/' | sort -f)

    if (( ${#refs[@]} > 0 )); then
        add_model_group_header "Ollama"
        for ref in "${refs[@]}"; do
            add_model_entry "$ref" "${ref#ollama/}"
        done
        return
    fi

    command -v ollama >/dev/null 2>&1 || return
    local names name
    names=()
    while IFS= read -r name; do
        if [[ -n "$name" ]]; then
            names+=("$name")
        fi
    done < <(ollama ls 2>/dev/null | tail -n +2 | awk 'NF {print $1}' | sort -f)
    if (( ${#names[@]} == 0 )); then
        return
    fi
    add_model_group_header "Ollama"
    for name in "${names[@]}"; do
        add_model_entry "ollama/${name}" "$name"
    done
}

draw_model_menu() {
    local selected="$1"
    local idx
    for idx in "${!MODEL_REFS[@]}"; do
        if [[ -z "${MODEL_REFS[$idx]}" ]]; then
            printf '  \033[38;5;208m%s\033[0m\033[K\n' "${MODEL_LABELS[$idx]}"
        elif (( idx == selected )); then
            printf '  \033[94m❯ %-40s\033[0m \033[2m%s\033[0m\033[K\n' "${MODEL_LABELS[$idx]}" "${MODEL_REFS[$idx]}"
        else
            printf '    %-40s \033[2m%s\033[0m\033[K\n' "${MODEL_LABELS[$idx]}" "${MODEL_REFS[$idx]}"
        fi
    done
}

erase_model_menu() {
    local total=$(( ${#MODEL_REFS[@]} + 1 ))
    local i
    for ((i = 0; i < total; i++)); do
        printf '\033[1A\033[2K'
    done
}

find_initial_model_selection() {
    local idx
    for idx in "${!MODEL_REFS[@]}"; do
        if [[ "${MODEL_REFS[$idx]}" == "$MODEL" ]]; then
            printf '%s' "$idx"
            return
        fi
    done
    for idx in "${!MODEL_REFS[@]}"; do
        if [[ -n "${MODEL_REFS[$idx]}" ]]; then
            printf '%s' "$idx"
            return
        fi
    done
    printf '0'
}

advance_model_selection() {
    local current="$1"
    local delta="$2"
    local count="${#MODEL_REFS[@]}"
    local i
    for ((i = 0; i < count; i++)); do
        current=$(( (current + delta + count) % count ))
        if [[ -n "${MODEL_REFS[$current]}" ]]; then
            printf '%s' "$current"
            return
        fi
    done
    printf '%s' "$1"
}

select_model_from_menu() {
    local count=${#MODEL_REFS[@]}
    local selected
    selected="$(find_initial_model_selection)"
    local key seq
    local esc_timeout=0.05
    if (( BASH_VERSINFO[0] < 4 )); then
        esc_timeout=1
    fi

    printf 'Select a model (\033[2m↑/↓\033[0m move, \033[2mEnter\033[0m select, \033[2mEsc\033[0m keep default: %s)\n' "$MODEL"
    draw_model_menu "$selected"

    while true; do
        if ! IFS= read -rsn1 key; then
            break
        fi
        case "$key" in
            $'\033')
                if ! IFS= read -rsn2 -t "$esc_timeout" seq; then
                    break
                fi
                case "$seq" in
                    '[A'|'OA') selected="$(advance_model_selection "$selected" -1)" ;;
                    '[B'|'OB') selected="$(advance_model_selection "$selected" 1)" ;;
                esac
                ;;
            $'\r'|"")
                MODEL="${MODEL_REFS[$selected]}"
                break
                ;;
            j|J) selected="$(advance_model_selection "$selected" 1)" ;;
            k|K) selected="$(advance_model_selection "$selected" -1)" ;;
        esac
        printf '\033[%dA' "$count"
        draw_model_menu "$selected"
    done

    erase_model_menu
}

resolve_model_selection() {
    if [[ "$MODEL_WAS_CHOSEN" == true ]]; then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        return 0
    fi

    collect_zai_models
    collect_ollama_models
    select_model_from_menu
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

run_opencode_streaming() {
    local prompt="$1"
    local log_file="$2"

    "$OPENCODE_BIN" run \
        --auto \
        ${THINKING_FLAG[@]+"${THINKING_FLAG[@]}"} \
        --model "$MODEL" \
        --title "ralph: $TASK_BASENAME" \
        --format json \
        "$prompt" \
        | tee "$log_file" \
        | jq -r --unbuffered '
            if .type == "text" then
                .part.text // empty
            elif .type == "tool_use" then
                "\u001b[2m⏺ \(.part.tool): \((.part.state.input.path // .part.state.input.command // .part.state.input.filePath // .part.state.input.pattern // .part.state.input.url // .part.state.input.description // .part.state.input.prompt // "") | tostring | gsub("\n"; " ") | .[0:160])\u001b[0m"
            elif .type == "error" then
                "\u001b[31m✖ \(.error.message // "unknown error")\u001b[0m"
            else
                empty
            end
        '

    return "${PIPESTATUS[0]}"
}

print_iteration_summary() {
    local log_file="$1"
    jq -sr '
        [ .[] | select(.type == "step_finish") ] as $steps
        | ($steps | map(.part.cost // 0) | add // 0) as $cost
        | ($steps | map(.part.tokens.input // 0) | add // 0) as $input
        | ($steps | map(.part.tokens.output // 0) | add // 0) as $output
        | "  ↳ steps: \($steps | length)  cost: $\($cost)  tokens: \($input)in/\($output)out"
    ' "$log_file" 2>/dev/null || true
    echo ""
}

extract_result_text() {
    local log_file="$1"
    jq -sr '[.[] | select(.type == "text")] | last | select(. != null) | .part.text // empty' "$log_file" 2>/dev/null || true
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

count_error_events() {
    local log_file="$1"
    local count
    count="$(jq -sr 'map(select(.type == "error")) | length' "$log_file" 2>/dev/null || true)"
    printf '%s' "${count:-0}"
}

accumulate_iteration_stats() {
    local log_file="$1"
    local steps cost tokens_in tokens_out tool_calls

    steps="$(jq -sr 'map(select(.type == "step_finish")) | length' "$log_file" 2>/dev/null || true)"
    cost="$(jq -sr 'map(select(.type == "step_finish")) | map(.part.cost // 0) | add // 0' "$log_file" 2>/dev/null || true)"
    tokens_in="$(jq -sr 'map(select(.type == "step_finish")) | map(.part.tokens.input // 0) | add // 0' "$log_file" 2>/dev/null || true)"
    tokens_out="$(jq -sr 'map(select(.type == "step_finish")) | map(.part.tokens.output // 0) | add // 0' "$log_file" 2>/dev/null || true)"
    tool_calls="$(jq -sr 'map(select(.type == "tool_use")) | length' "$log_file" 2>/dev/null || true)"

    TOTAL_STEPS=$(( TOTAL_STEPS + ${steps:-0} ))
    TOKENS_IN=$(( TOKENS_IN + ${tokens_in:-0} ))
    TOKENS_OUT=$(( TOKENS_OUT + ${tokens_out:-0} ))
    TOTAL_TOOL_CALLS=$(( TOTAL_TOOL_CALLS + ${tool_calls:-0} ))
    STREAM_ERRORS=$(( STREAM_ERRORS + $(count_error_events "$log_file") ))
    add_cost "${cost:-0}"
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
        printf '%s\n' "- **Agent:** opencode ($OPENCODE_BIN)"
        printf '%s\n' "- **Model:** $MODEL"
        printf '%s\n' "- **Task file:** $TASK_FILE"
        printf '%s\n' "- **Started:** $RUN_STARTED_AT"
        printf '%s\n' "- **Ended:** $ended_at"
        printf '%s\n' "- **Duration:** $(format_duration "$duration") (${duration}s)"
        printf '%s\n' "- **Iterations:** $ITERATIONS_RUN of max $MAX"
        printf '%s\n' "- **Steps:** $TOTAL_STEPS agent steps, $TOTAL_TOOL_CALLS tool calls"
        printf '%s\n' "- **Errors:** $AGENT_ERRORS agent failures, $STREAM_ERRORS stream errors"
        printf '%s\n' "- **Cost:** \$$TOTAL_COST"
        printf '%s\n' "- **Tokens:** $TOKENS_IN in / $TOKENS_OUT out"
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

        if ! run_opencode_streaming "$prompt" "$log_file"; then
            (( ++fails ))
            (( ++AGENT_ERRORS ))
            STREAM_ERRORS=$(( STREAM_ERRORS + $(count_error_events "$log_file") ))
            if (( fails >= 3 )); then
                RUN_OUTCOME="aborted: opencode failed $fails times in a row"
                display_main_header "Aborting: opencode failed $fails times in a row"
                echo "Last log: $log_file"
                exit 1
            fi
            echo -e "${DIM}Warning: opencode exited with an error on iteration $i (log: $log_file), retrying${RESET}" >&2
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
    display_main_header "Starting Ralph (opencode) - Max $MAX iterations"
    echo "Working directory: $WORK_DIR"
    echo "Model: $MODEL"
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
    set_thinking_flag
    check_task_file_given
    resolve_task_file_path
    check_task_file_exists
    check_task_file_extension
    check_prompt_file_exists
    check_jq_installed
    check_opencode_installed
    resolve_run_paths
}

run_ralph() {
    init_run_tracking
    set_signal_traps
    check_git_repository
    resolve_model_selection
    initialize_progress_file
    display_run_header
    run_automation_loop
    finish_at_max_iterations
}

parse_arguments "$@"
run_startup_checks
run_ralph
