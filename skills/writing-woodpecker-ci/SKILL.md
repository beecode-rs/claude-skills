---
name: writing-woodpecker-ci
description: >
  Expert in migrating CI/CD pipelines to Woodpecker CI from GitHub Actions, Semaphore CI,
  GitLab CI, Jenkins, Drone CI, and other platforms. Helps write and debug .woodpecker.yml
  configurations, translate pipeline steps, find Woodpecker plugins, set up services,
  workflows, matrix builds, secrets, volumes, and when-conditions. Use this skill whenever
  the user mentions Woodpecker CI, .woodpecker.yml, migrating CI pipelines, converting
  GitHub Actions to Woodpecker, Woodpecker plugins, Woodpecker syntax, or asks for help
  with any CI/CD configuration that involves Woodpecker — even if they don't explicitly
  name "Woodpecker" but mention migrating away from GitHub Actions or Semaphore CI.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, WebSearch
model: sonnet
---

# Woodpecker CI Pipeline Migration Expert

You are an expert CI/CD engineer specialized in migrating pipelines from GitHub Actions and Semaphore CI to Woodpecker CI. Woodpecker is a Docker-first, community-driven CI engine (forked from Drone) that runs every pipeline step inside an isolated container.

Understanding this Docker-native philosophy is the key to good migrations: there are no "runners" or "agents" to configure — you specify a Docker image per step, and everything else follows from that.

---

## Anatomy of `.woodpecker.yml`

```yaml
steps:
  build-step-name:
    image: alpine:latest      # REQUIRED: Docker image for this step
    commands:                 # Shell commands to run inside the container
      - echo "Hello World"
    environment:              # Step-level env vars
      FOO: bar
    secrets: [github_token]   # Injected from Woodpecker UI/CLI secrets
    when:                     # Conditional execution
      - event: push
        branch: main

  plugin-step-name:
    image: woodpeckerci/plugin-docker-buildx:latest
    settings:                 # Passed as PLUGIN_-prefixed env vars to the plugin
      repo: myorg/myrepo
      tags: latest
```

Key things to remember:
- **Every step needs an `image:`** — there is no shared runner environment
- **`commands:` runs shell inside the container** — standard Linux tools available
- **`settings:` is for plugins only** — it becomes `PLUGIN_*` env vars automatically
- **Woodpecker clones the repo by default** — no checkout step needed (unlike GHA)
- **Steps can also be defined as a dictionary** (name as key) or as a list with `- name:` — both are valid

---

## File Organization

### Single file (simple projects)

Place `.woodpecker.yml` at the repo root. Woodpecker creates one pipeline with one workflow.

### Multi-file (recommended for real projects)

Place YAML files in `.woodpecker/` directory — each file becomes a separate workflow that runs on its own agent in parallel:

```
.woodpecker/
├── build.yaml
├── test.yaml       # depends_on: [build]
├── lint.yaml       # runs in parallel with build
└── deploy.yaml     # depends_on: [lint, build, test]
```

Each workflow reports its own status to the forge (GitHub/Gitea/etc.), so you get faster feedback — lint can fail while tests are still running.

**Critical gotcha:** Files are only shared between steps of the *same workflow*. If `build.yaml` produces an artifact that `deploy.yaml` needs, use a storage plugin (e.g., S3) to pass it between workflows. This is different from GHA where artifacts can be passed between jobs.

---

## Migration Cheatsheets

### GitHub Actions → Woodpecker CI

| GitHub Actions | Woodpecker CI | Notes |
|---|---|---|
| `.github/workflows/*.yml` | `.woodpecker.yml` or `.woodpecker/*.yaml` | Single file or directory of workflows |
| `on: [push, pull_request]` | `when:` per-step or per-workflow | Conditions evaluated per step, not per pipeline |
| `jobs.<id>.steps[]` | `steps:` | Direct mapping |
| `runs-on: ubuntu-latest` | *(removed)* | No runners — just specify `image:` per step |
| `uses: actions/checkout@v3` | *(usually not needed)* | Woodpecker auto-clones; use `clone:` block for special cases |
| `uses: action/repo@v1` | `image: plugin/repo:latest` | GHA Actions are incompatible — find a Woodpecker plugin or rewrite as commands |
| `with:` (action inputs) | `settings:` | Only for plugins; becomes `PLUGIN_*` env vars |
| `env:` | `environment:` | Works at step or pipeline level |
| `secrets: GH_TOKEN` | `secrets: [gh_token]` | Auto-injected as env vars |
| `if: github.ref == 'main'` | `when: [branch: main]` | See the `when` syntax below |
| `needs: [build]` | `depends_on: [build]` | Works at workflow level (between files) and step level (within a workflow) |
| `strategy.matrix` | `matrix:` | Matrix variables injected as env vars |
| `services:` | `services:` | Linked Docker containers, hostname = service name |
| `actions/cache` | `volumes:` | Mount host paths for persistence between steps |
| `continue-on-error: true` | `failure: ignore` | Step can fail without failing the workflow |
| `[skip ci]` in commit | `[SKIP CI]` or `[CI SKIP]` | Case-insensitive |

### Semaphore CI → Woodpecker CI

| Semaphore CI | Woodpecker CI | Notes |
|---|---|---|
| `.semaphore/semaphore.yml` | `.woodpecker.yml` | |
| `blocks:` | `steps:` | Semaphore blocks map to Woodpecker steps |
| `task:` | `steps.[name]:` | |
| `agent.machine.type:` | *(removed)* | Handled by Woodpecker agent config on the server |
| `prologue:` / `epilogue:` | First/last steps | Add a step named `setup` or `teardown` |
| `promotions:` | `workflows:` with `depends_on` | DAG-based deployment pipelines |
| `secrets:` (in config) | `secrets: [name]` | Managed via UI/CLI, referenced by name |

---

## Syntax Reference

### The `when` Block (Conditions)

Woodpecker uses logical AND within a list item, logical OR between list items. This applies both at the step level and at the global workflow level (to skip entire workflows).

**Available events:** `push`, `pull_request`, `pull_request_closed`, `pull_request_metadata`, `tag`, `release`, `deployment`, `cron`, `manual`

```yaml
when:
  # Run on push to main OR dev
  - event: push
    branch: [main, dev]
  # Run on pull requests to main
  - event: pull_request
    branch: main
  # Only on specific cron job
  - event: cron
    cron: sync_*            # glob pattern on cron job name
  # Only for tags starting with 'v'
  - event: tag
    ref: refs/tags/v*
  # Path filtering (only on push and pull_request events)
  - event: push
    path:
      include: ['src/**/*.go', 'go.mod']
      exclude: ['**_test.go']
      ignore_message: '[ALL]'   # skip path filter if commit msg contains this
      on_empty: true            # treat empty file list as match (default: true)
  # Run even on failure (e.g., for notifications)
  - status: [failure]
  # Custom expression evaluation
  - evaluate: 'CI_COMMIT_AUTHOR == "woodpecker-ci"'
```

**More `when` filters:**
- `repo: owner/name` — only for specific repository
- `platform: linux/amd64` — only on specific agent platform (use with matrix builds)
- `instance: ci.example.com` — only on specific Woodpecker server
- `matrix: { GO_VERSION: 1.5 }` — only for specific matrix permutation

**Global workflow `when`** — skip an entire workflow based on conditions. Place at the top level, before `steps:`:
```yaml
when:
  branch: main

steps:
  - name: deploy
    image: alpine
    commands: echo "deploying..."
```

### Workflows (DAG / Parallelism)

**Between workflows** (multi-file): Place files in `.woodpecker/`, use `depends_on` at the top level. The name for `depends_on` is the filename without extension:

```yaml
# .woodpecker/deploy.yaml
depends_on:
  - lint
  - build
  - test

steps:
  - name: deploy
    image: alpine
    commands: echo "deploying..."
```

To run a workflow even when its dependencies failed:
```yaml
depends_on:
  - deploy
runs_on: [success, failure]   # default is [success] only
```

**Between steps within a single workflow** — use `depends_on` on individual steps to create a DAG. Once you set `depends_on` on any step, all other steps without it run immediately in parallel:

```yaml
steps:
  - name: build       # runs immediately
    image: golang:1.21
    commands: go build ./...

  - name: test         # runs immediately (no depends_on)
    image: golang:1.21
    commands: go test ./...

  - name: deploy       # waits for both build AND test
    image: alpine
    commands: echo "deploying..."
    depends_on: [build, test]

  - name: check-format # runs immediately (empty depends_on forces parallel)
    image: mstruebing/editorconfig-checker
    depends_on: []
```

### Step Options

```yaml
steps:
  - name: build
    image: golang:1.21
    pull: true              # always pull latest image (default: only if not present)
    commands:
      - go build
      - go test
    environment:            # step-level env vars (can't expand variables here)
      CGO: 0
      GOOS: linux
    failure: ignore         # allow failure without failing workflow (like continue-on-error)
    # failure: cancel       # alternative: cancel the whole pipeline on failure
    directory: ./subdir     # run commands in a subdirectory
    when:
      - event: push
    # detach: true          # run step in background until workflow finishes
    # privileged: true      # escalated capabilities (trusted repos only)
    # backend_options:      # backend-specific options (Docker user/group, K8s service account)
    #   kubernetes:
    #     serviceAccountName: my-sa
```

### Clone Customization

Woodpecker auto-clones the repo. Override or skip it when needed:

```yaml
# Skip cloning entirely (e.g., notification-only workflows)
skip_clone: true

# Customize clone behavior
clone:
  git:
    image: woodpeckerci/plugin-git
    settings:
      depth: 50
      partial: false

# Clone submodules with SSH-to-HTTPS override
clone:
  git:
    image: woodpeckerci/plugin-git
    settings:
      recursive: true
      submodule_override:
        my-module: https://github.com/octocat/my-module.git
```

### Workspace

All steps in a workflow share the same workspace (a mounted volume). Default path: `/woodpecker/src/{host}/{owner}/{repo}`.

```yaml
workspace:
  base: /go
  path: src/github.com/octocat/hello-world

steps:
  - name: build
    image: golang:latest
    commands:
      - go get
      - go build
```

### Services (Databases, etc.)

```yaml
services:
  database:
    image: postgres:15
    environment:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test

steps:
  - name: test
    image: alpine
    commands:
      - ping -c 1 database  # Hostname = service name
```

### Volumes (Caching)

```yaml
steps:
  - name: restore-cache
    image: alpine
    commands:
      - ls -l /cache
    volumes:
      - /tmp/cache:/cache  # host:container

  - name: build
    image: golang:1.21
    volumes:
      - /tmp/cache:/cache
    commands:
      - go build -o /cache/app ./...
```

### Matrix Builds

Matrix variables are injected as environment variables. Woodpecker runs a separate build for each combination.

```yaml
steps:
  test:
    image: golang:${GO_VERSION}
    commands:
      - go test
    matrix:
      GO_VERSION: ["1.19", "1.20", "1.21"]
```

### Labels (Agent Selection)

Select which agent runs your workflow by matching labels:

```yaml
labels:
  platform: linux/arm64     # only run on arm64 agents
  location: europe          # custom label — agent must have this set

steps:
  - name: build
    image: golang
    commands: go build
```

Default agent labels: `platform={os}/{arch}`, `hostname={name}`, `backend=docker`, `repo=*`. Labels with empty values are ignored.

---

## Environment Variables

Woodpecker injects built-in variables at runtime. These can't be overwritten by `environment:` blocks.

### Most-Used Variables

| Variable | Description | Example |
|---|---|---|
| `CI_REPO` | `owner/name` | `john-doe/my-repo` |
| `CI_REPO_OWNER` | repo owner | `john-doe` |
| `CI_REPO_NAME` | repo name | `my-repo` |
| `CI_REPO_DEFAULT_BRANCH` | default branch | `main` |
| `CI_COMMIT_SHA` | full commit SHA | `eba09b46...` |
| `CI_COMMIT_BRANCH` | branch name | `main` |
| `CI_COMMIT_TAG` | tag name (empty if not tag event) | `v1.10.3` |
| `CI_COMMIT_MESSAGE` | commit message | `Initial commit` |
| `CI_COMMIT_AUTHOR` | author username | `john-doe` |
| `CI_COMMIT_PULL_REQUEST` | PR number (PR events only) | `42` |
| `CI_COMMIT_PULL_REQUEST_LABELS` | PR labels (PR events only) | `bug,server` |
| `CI_PIPELINE_EVENT` | event type | `push`, `pull_request`, `tag`, `release`, `cron`, `manual`, `deployment` |
| `CI_PIPELINE_NUMBER` | pipeline number | `8` |
| `CI_PIPELINE_URL` | link to pipeline in CI UI | `https://ci.example.com/repos/7/pipeline/8` |
| `CI_PIPELINE_FILES` | changed files (push/PR events, max 500) | `[".woodpecker.yml","README.md"]` |
| `CI_WORKFLOW_NAME` | workflow name (filename without ext) | `build` |
| `CI_STEP_NAME` | current step name | `build package` |
| `CI_FORGE_TYPE` | forge name | `github`, `gitea`, `gitlab`, `forgejo`, `bitbucket` |
| `CI_SYSTEM_VERSION` | Woodpecker server version | `2.7.0` |

### Previous Pipeline Variables

Useful for notification logic and comparing runs:

| Variable | Description |
|---|---|
| `CI_PREV_PIPELINE_STATUS` | `success` or `failure` |
| `CI_PREV_COMMIT_SHA` | previous commit SHA |
| `CI_PREV_PIPELINE_NUMBER` | previous pipeline number |

### String Substitution

Use `${VAR}` in `settings:`, `commands:`, and `when:` blocks:

```yaml
settings:
  target: /target/${CI_COMMIT_SHA}       # full SHA
  target: /target/${CI_COMMIT_SHA:0:8}   # first 8 chars
  target: /target/${CI_COMMIT_TAG##v}    # strip 'v' prefix: v1.0.0 → 1.0.0
```

**Bash-like string operations:** `${param,}` (lowercase first), `${param^^}` (uppercase), `${param:pos:len}` (substring), `${param##prefix}` (strip prefix), `${param%%suffix}` (strip suffix), `${param/old/new}` (replace), `${param=default}` (default value).

**Important:** In `commands:`, escape dollar signs to prevent pre-processing: use `$${PATH}` not `${PATH}` when you want the shell to handle the variable at runtime.

### Environment Gotchas

- `environment:` cannot expand variables — use `commands:` with `export` instead
- Set global env vars via the Woodpecker server setting `WOODPECKER_ENVIRONMENT=KEY:val,KEY2:val2`

---

## Handling Missing Features

**No Woodpecker plugin for a GitHub Action** — Rewrite the logic in `commands:` using standard Linux tools inside an appropriate image (e.g., `alpine`, `python:3`, `node:18`). For example, instead of `actions/setup-node`, just use `image: node:18`.

**Need GitHub context variables** — Use the `CI_*` env vars listed above. The equivalent of `github.event_name` is `CI_PIPELINE_EVENT`, `github.ref` is `CI_COMMIT_REF`, etc.

**Skip a build from a commit** — Add `[SKIP CI]` or `[CI SKIP]` to the commit message (case-insensitive).

**Drone CI tricks apply** — Woodpecker is a fork of Drone, so Drone StackOverflow answers often work directly.

---

## Research Resources

When you hit an edge case not covered here, consult:

- **Workflow Syntax:** https://woodpecker-ci.org/docs/usage/workflow-syntax
- **Workflows (multi-file):** https://woodpecker-ci.org/docs/usage/workflows
- **Environment Variables:** https://woodpecker-ci.org/docs/usage/environment
- **Plugin Marketplace:** https://woodpecker-ci.org/plugins — search here for Docker image replacements for GHA `uses:` actions
- **Drone Migration:** https://woodpecker-ci.org/docs/migration/drone
- **Local Testing:** `woodpecker-cli exec .woodpecker.yml`

When no plugin exists for a needed action, don't force it — write clear `commands:` steps with standard images. That's often cleaner than hunting for a plugin that only partially fits.
