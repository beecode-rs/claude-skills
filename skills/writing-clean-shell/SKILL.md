---
name: writing-clean-shell
description: Expert in organizing shell scripts so anyone can read, update, and maintain them. Use this skill whenever you write or create any shell script (bash, zsh, sh, or PowerShell, on Linux, macOS, or Windows), and whenever you edit, refactor, clean up, or reorganize an existing script, make a script readable or maintainable, add flags, options, or a help screen to a script, structure a main function or orchestrator, or split a monolithic script into functions - even if the user never mentions organization or clean code, and even for a quick one-off script. The skill also runs a full cleanup checklist (commands/cleanup.md) that checks every rule and fixes violations when the user asks to clean up, review, or validate a shell script. Covers function extraction, verb-first naming, guard clauses, steps-array orchestrators, print_usage help screens, and consistent output vocabulary. This is an organization skill, not a syntax skill: the principles apply to any shell on any platform.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Writing Clean Shell

## Purpose

Organize shell scripts so anyone can read them top to bottom, update them, and maintain them, where reading the orchestrator function equals reading the script's outline. This skill teaches organization, not syntax: it is agnostic to platform (Linux, macOS, Windows) and shell (bash, zsh, sh, PowerShell). Bash appears in the examples only because it is the reference material; translate the shapes into the target shell's idioms.

## Script Anatomy

Fixed top-to-bottom layout of every script:

```bash
#!/bin/bash                          shebang

DAYS=30                              setup: config and flag defaults
DRY_RUN=false                        UPPER_CASE, declared before functions
print_info() { echo "[INFO] $1"; }   setup: output vocabulary, or source the repo print library

parse_arguments() { ... }            argument parsing (only when the script takes parameters)

print_usage() { ... }                help screen (only when the script takes parameters)

check_downloads_dir_exists() { ... } guard checks: named, reusable, return 1 on failure
display_stale_files() { ... }        task functions, one job each
delete_stale_files() { ... }         verb-first names, guard clauses first

run_cleanup() { ... }                orchestrator: steps array plus loop,
                                     defined after the functions it calls

parse_arguments "$@"                 main flow: parse, then run
run_cleanup
```

## Core Rules

1. **No comments.** A comment is a name you failed to give, and comments rot during refactors while names stay correct; the only tolerated comment is a temporary `# TODO: Remove when [condition]`.
2. **Make every behavior a function.** The top level holds only the shebang, minimal setup (defaults, print layer, or library sourcing when the environment provides one), argument parsing, and the final orchestrator call, because top-level logic runs exactly once and can never be named, skipped, or reused.
3. **Use verb-first, snake_case names that state exactly what the function does** (update_homebrew_packages, check_ollama_installed, pull_each_model, display_models_to_update), so the function list becomes the script's table of contents and readers navigate by names alone.
4. **Give each function one job.** If the description needs the word "and", split it in two, because single-job functions earn precise names and simple guards.
5. **Put guard clauses first.** Each function checks its own preconditions at the top (tool installed, directory exists, file present), prints a warning, and returns when they fail; skipping is a normal outcome, not an error, and the orchestrator never knows about step preconditions, so every step stays independently callable.
6. **Put the orchestrator at the bottom.** A run_* function (or main) holds a steps array of function names and loops over it; multiple phases mean multiple orchestrators (run_user_updates, run_system_updates), each defined after the functions it calls, so reading the steps array equals reading the whole flow.
7. **Offer help whenever the script accepts parameters.** Handle -h and --help with a print_usage function that prints description, usage line, options, and an example; unknown arguments also print usage and exit non-zero. A script with no parameters needs no help.
8. **Keep one output vocabulary.** Every user-visible message comes from the script's print layer: repo helper functions when they exist (print_info at step start, print_success on completion, print_warning when skipping), otherwise plain echo with the same [INFO]/[SUCCESS]/[WARNING] prefixes; one vocabulary per script makes the output a trustworthy progress log.
9. **Declare variables local inside functions.** Script-level flag variables from argument parsing are UPPER_CASE and declared before functions, so the configurable surface is visible at the top and functions leak nothing.
10. **Parse arguments simply.** A for loop over "$@" with a case statement setting UPPER_CASE flag variables, where anything unrecognized triggers usage; switch to a while loop with shift only when a flag consumes a value (--days N). A parser should stay smaller than the script it configures.

## Worked Example

Dependency-free bash, runs anywhere, zero comments:

```bash
#!/bin/bash

DOWNLOADS_DIR="${DOWNLOADS_DIR:-$HOME/Downloads}"
DAYS=30
DRY_RUN=false

print_header() { echo; echo "=== $1 ==="; echo; }
print_info() { echo "[INFO] $1"; }
print_success() { echo "[SUCCESS] $1"; }
print_warning() { echo "[WARNING] $1"; }

parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run) DRY_RUN=true ;;
            --days)    DAYS="$2"; shift ;;
            -h|--help) print_usage; exit 0 ;;
            *)         print_warning "Unknown argument: $1"; print_usage; exit 1 ;;
        esac
        shift
    done
}

print_usage() {
    echo "Delete old files from the downloads folder."
    echo
    echo "Usage: clean-downloads.sh [--dry-run] [--days N]"
    echo
    echo "Options:"
    echo "  --dry-run    list candidates without deleting anything"
    echo "  --days N     delete files older than N days (default: 30)"
    echo "  -h, --help   show this help"
    echo
    echo "Example:"
    echo "  clean-downloads.sh --dry-run --days 14"
}

check_downloads_dir_exists() {
    if [ ! -d "$DOWNLOADS_DIR" ]; then
        print_warning "Downloads folder not found: $DOWNLOADS_DIR, skipping..."
        return 1
    fi
}

find_stale_files() {
    find "$DOWNLOADS_DIR" -maxdepth 1 -type f -mtime +"$DAYS" 2>/dev/null
}

display_stale_files() {
    check_downloads_dir_exists || return

    local files
    files=$(find_stale_files)

    if [ -z "$files" ]; then
        print_warning "No files older than $DAYS days, skipping..."
        return
    fi

    print_info "Files older than $DAYS days:"
    echo "$files" | while read -r file; do
        echo "  - $file"
    done
}

delete_stale_files() {
    check_downloads_dir_exists || return

    if [ "$DRY_RUN" = true ]; then
        print_warning "Dry run, skipping deletion..."
        return
    fi

    local files
    files=$(find_stale_files)

    if [ -z "$files" ]; then
        print_warning "No files older than $DAYS days, skipping..."
        return
    fi

    echo "$files" | while read -r file; do
        rm "$file"
    done

    print_success "Deleted files older than $DAYS days"
}

run_cleanup() {
    local steps=(
        display_stale_files
        delete_stale_files
    )

    print_header "Clean downloads"

    for step in "${steps[@]}"; do
        $step
    done

    print_success "Cleanup complete"
}

parse_arguments "$@"
run_cleanup
```

## Patterns

Argument parsing (boolean flags; the worked example shows the while plus shift variant a value flag needs):

```bash
parse_arguments() {
    for arg in "$@"; do
        case "$arg" in
            --root-only) ROOT_ONLY=true ;;
            -h|--help)   print_usage; exit 0 ;;
            *)           print_warning "Unknown argument: $arg"; print_usage; exit 1 ;;
        esac
    done
}
```

print_usage:

```bash
print_usage() {
    echo "One-line description of the script."
    echo
    echo "Usage: script.sh [options]"
    echo
    echo "Options:"
    echo "  --flag      what the flag does"
    echo "  -h, --help  show this help"
    echo
    echo "Example:"
    echo "  script.sh --flag"
}
```

Steps-array orchestrator:

```bash
run_updates() {
    local steps=(
        update_homebrew_packages
        update_docker_containers
        update_claude
    )

    print_header "Updates"

    for step in "${steps[@]}"; do
        $step
    done

    print_success "Updates complete"
}
```

Guard clause:

```bash
update_ollama() {
    if ! command -v ollama &> /dev/null; then
        print_warning "Ollama not found, skipping..."
        return
    fi

    print_info "Updating Ollama..."
}
```

A named check can also be reused by several steps, each invoking it as its guard:

```bash
check_ollama_installed || return
```

## Commands

- **Cleanup**: [commands/cleanup.md](commands/cleanup.md) - Full checklist review and cleanup of a shell script against these rules. Use when the user says "cleanup this script", "clean up this shell script", "review this script", "check this script's structure", or "fix this script's organization".

## Refactoring

1. Read the messy script once and list every verb it performs (check, install, update, pull, display, clean).
2. Turn each verb into a verb-first snake_case function and move its code in unchanged, splitting any function whose description needs "and".
3. Find every precondition (tool missing, directory absent, file absent) and turn it into a guard clause at the top of the function that needs it: print_warning, then return.
4. Group the functions into phases, give each phase a run_* orchestrator with a steps array, and order the orchestrators into the final main flow.
5. Hoist flag variables into UPPER_CASE declarations above the functions and replace inline parsing with parse_arguments.
6. Add print_usage if the script takes any parameter, and route unknown arguments to it.
7. Route every message through the print layer.
8. Delete every comment; wherever a comment explained something, rename or extract until it is unnecessary.

## Pitfalls

- **Logic creeping into top level.** If it is not shebang, setup, parsing, or the final call, it hides a step from the orchestrator's outline; put it in a function.
- **Orchestrator knowing step preconditions.** If run_* checks for ollama before calling update_ollama, every future caller must repeat the check; guards live inside the step.
- **Deep nesting instead of guards.** An if/else pyramid pushes the main path off screen; invert each check into an early return at the top.
- **A comment explaining what a name could say.** A "# update the models" line above update_models() is noise; rename the function or delete the comment.
- **Flags without a help option.** Every accepted parameter must appear in print_usage and unknown input must print it, or the flags are undiscoverable.
- **Giant multi-job functions.** A name needing "and" (install_and_configure) is two functions; the steps array expresses the sequence.
