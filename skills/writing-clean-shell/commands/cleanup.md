# Cleanup Command

Full checklist review and cleanup of a shell script against the organization rules in the writing-clean-shell SKILL.md: walk every Core Rule, check the script, fix every violation, and report. Cleanup reorganizes; it NEVER changes behavior.

## Usage

When the user says: "cleanup this script", "clean up this shell script", "review this script", "check this script's structure", or "fix this script"

## Process

1. Read the whole script top to bottom before touching it.
2. Capture a baseline: run a syntax check (bash -n, or the target shell's equivalent) and run the help screen if the script has one. Run shellcheck too when it is available; treat its output as advisory only.
3. Walk every checklist section below, fixing each violation as it is found.
4. Re-run the baseline checks to prove syntax and behavior are intact.
5. Produce the report in Output Format.

When the script is not bash, use the target shell's own syntax checker instead of bash -n.

## Checklist

### 1. Comments Check

**Rule**: Zero comments; a comment is a name you failed to give.

| Pattern | Status |
|---------|--------|
| `# update the models before pulling` inline explanation | FAIL |
| `# ===== Helpers =====` block banner | FAIL |
| `# npx skills add ...` commented-out code | FAIL |
| `# TODO: Remove when pull.sh is fixed` (temporary, with condition) | PASS |

**Fix**: Delete the comment, then rename or extract until it is unnecessary.

### 2. Top-Level Logic Check

**Rule**: Top level holds only the shebang, setup (defaults, print layer, library sourcing), argument parsing, and the final orchestrator call(s).

| Pattern | Status |
|---------|--------|
| `DAYS=30` default declared before the functions | PASS |
| `source "$SCRIPT_DIR/../common/print.sh"` | PASS |
| `parse_arguments "$@"` followed by `run_cleanup` | PASS |
| Any other statement at column 0 executing at script start | FAIL |

**Fix**: Wrap the statement in a verb-named function and add it to a steps array.

### 3. Function Naming Check

**Rule**: Verb-first snake_case that states exactly what the function does.

| Pattern | Status |
|---------|--------|
| `update_homebrew_packages` | PASS |
| `check_ollama_installed` | PASS |
| `pull_each_model` | PASS |
| `print_usage` | PASS |
| `do_stuff`, `helper2`, `process`, `handler` | FAIL |

**Fix**: Rename so the body becomes skippable; the function list is the script's table of contents.

### 4. Single-Job Check

**Rule**: One job per function.

| Pattern | Status |
|---------|--------|
| Description needs "and" ("installs and configures") | FAIL |
| Body spans many unrelated operations | FAIL |
| One verb, one outcome, simple guards | PASS |

**Fix**: Split into one function per job; the steps array expresses the sequence.

### 5. Guard Clause Check

**Rule**: Each function checks its own preconditions at its top, prints a warning, and returns; a named check invoked as `check_x || return` also passes.

```bash
update_ollama() {
    if ! command -v ollama &> /dev/null; then
        print_warning "Ollama not found, skipping..."
        return
    fi
}
```

| Pattern | Status |
|---------|--------|
| `check_ollama_installed || return` at the top of a step | PASS |
| Preconditions checked inside the orchestrator | FAIL |
| Deep if/else pyramid instead of early returns | FAIL |
| Missing warning before return | FAIL |

**Fix**: Invert to an early return at the top of the step that needs the condition.

### 6. Orchestrator Check

**Rule**: A run_* (or main) function holds a local steps array of function names and loops over it; functions first, orchestrator last.

```bash
run_user_updates() {
    local steps=(
        update_homebrew_packages
        update_docker_containers
        update_claude
    )

    print_header "User-level updates"

    for step in "${steps[@]}"; do
        $step
    done
}
```

| Pattern | Status |
|---------|--------|
| Logic listed in a steps array | PASS |
| Multiple phases, one run_* orchestrator each, run in sequence in the main flow | PASS |
| Logic run inline instead of listed in steps | FAIL |
| Steps array missing | FAIL |
| Orchestrator defined before the functions it calls | FAIL |

**Fix**: Move inline logic into functions, list them in the steps array, define the orchestrator after its callees.

### 7. Help Check

**Rule**: Applies only when the script accepts parameters.

| Pattern | Status |
|---------|--------|
| print_usage prints description, usage line, options, one example | PASS |
| `-h|--help) print_usage; exit 0 ;;` | PASS |
| Unknown argument prints usage and exits non-zero | PASS |
| Script with no parameters and no help | PASS |
| Flag accepted but undocumented | FAIL |
| Unknown args silently ignored | FAIL |
| Script with flags, help missing entirely | FAIL |

**Fix**: Add print_usage, document every flag, route -h and --help to it (exit 0) and unknown input to it (exit non-zero).

### 8. Output Vocabulary Check

**Rule**: Every user-visible message goes through the print layer.

| Pattern | Status |
|---------|--------|
| print_info at step start, print_success on completion, print_warning when skipping | PASS |
| Local print_* functions or consistent [INFO]/[SUCCESS]/[WARNING] echo prefixes | PASS |
| Bare echo mixed with print helpers | FAIL |
| Inconsistent prefixes | FAIL |
| Silent steps | FAIL |

**Fix**: Route every message through one vocabulary.

### 9. Variable Scope Check

**Rule**: Function variables are local; script-level flag variables are UPPER_CASE and declared before the functions.

| Pattern | Status |
|---------|--------|
| `local files` inside a function | PASS |
| `DRY_RUN=false` above the functions | PASS |
| Function leaking a variable to global scope | FAIL |
| Flag declared mid-script | FAIL |

**Fix**: Declare local at the top of the function; hoist flags to UPPER_CASE declarations above the functions.

### 10. Argument Parsing Check

**Rule**: A simple parser: for loop over "$@" with case for boolean flags, while plus shift when a flag consumes a value; unrecognized input triggers usage.

| Pattern | Status |
|---------|--------|
| `for arg in "$@"` with `case` setting UPPER_CASE flags | PASS |
| `while [ $# -gt 0 ]` with `shift` for `--days N` | PASS |
| `*)` arm printing usage and exiting non-zero | PASS |
| Parsing function bigger than the script | FAIL |
| Nested if chains on $1 | FAIL |
| Flags handled inconsistently with the case form | FAIL |

**Fix**: Collapse to the case form with UPPER_CASE flag variables; send unknown input to print_usage.

## Output Format

```markdown
# Cleanup Report: [filename]

## Summary
- **Total Issues**: X
- **Fixed**: X

## Issues

| Line | Rule | Issue | Fix applied |
|------|------|-------|-------------|
| 15 | Comments | Inline explanation comment | Deleted; renamed function to update_models |
| 42 | Guard Clauses | Precondition checked in orchestrator | Moved guard into the update_ollama step |

## Verification

- Syntax check re-run: PASS (bash -n)
- Help screen re-run: identical output
- Behavior notes: no behavior change, steps order preserved
```

## Quick Reference Card

```
COMMENTS     → Zero; only # TODO: Remove when [condition]
TOP LEVEL    → Shebang, setup, parsing, orchestrator call; nothing else at column 0
NAMES        → Verb-first snake_case (update_homebrew_packages, check_ollama_installed)
ONE JOB      → Description needs "and" means split; steps array sequences the jobs
GUARDS       → Each function checks its own preconditions; print_warning, then return
ORCHESTRATOR → run_* with a local steps array; functions first, orchestrator last
HELP         → print_usage when flags exist; -h exits 0; unknown args exit non-zero
OUTPUT       → One print vocabulary (print_info, print_success, print_warning, print_header)
SCOPE        → local inside functions; UPPER_CASE flags declared before functions
PARSING      → for+case for booleans, while+shift for values; unknown input triggers usage
```
