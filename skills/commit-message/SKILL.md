---
name: commit-message
description: Generate git commit messages and squash PR merge messages in conventional commit format, with explicit user confirmation before any commit. Use this skill whenever the user wants to commit changes, write or review a commit message, prepare a squash merge message for a PR, or says things like "commit this", "commit my changes", "write a commit message", "squash message", or "squash my PR", even when they do not name a format.
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# Commit Message

Generate conventional-commit messages in two situations: an ordinary commit of staged changes (Flow A) and a squash merge message for a PR (Flow B). The defining property of this skill is that nothing enters git history unreviewed: every message is shown in chat first, every commit needs an explicit yes, and pushing is never part of the flow.

## Hard rules

1. **Never commit without an explicit yes.** Show the full proposed message in chat, then ask the confirmation question. A yes from an earlier message or an earlier session does not count; when in doubt, ask again.
2. **Never push.** The skill completes at the local commit (Flow A) or the printed message (Flow B). When the work is done, say so and stop; the user pushes themselves.
3. **Commit as the local user.** Never pass `--author`, never override `user.name` or `user.email`, and never append `Co-Authored-By:` or "generated with" trailers of any kind. The commit must be authored by the identity already configured in the local environment.
4. **Gate the protected branches.** `main` and `master` (and the remote's default branch when it is neither) get an extra are-you-sure question before the flow proceeds.
5. **No em dashes or en dashes in any generated message.** Use a hyphen, comma, colon, or parentheses instead; they render inconsistently across terminals and git tooling.
6. **Use AskUserQuestion for every question**, so the user gets clickable options. The "Make changes" option loops: apply the requested change, show the message again, ask again, until the user picks yes or no.

## Message generation (both flows)

Read [references/commit-message-rules.md](references/commit-message-rules.md) and apply every rule in it before writing any message. The short version: `{type}: {subject}` under 50 characters, lowercase, imperative mood; secondary changes go in an optional body; only the types listed in that file are allowed.

Base the message on what the code actually shows, not on what the user casually called the change.

## Flow A: commit message

If the user asks to fix the last commit's message, run this same loop but commit with `--amend`, and only after the same explicit yes.

1. **Gather context.** Get the current branch, the staged diff, and repo status:
   ```bash
   git branch --show-current
   git --no-pager diff --cached --stat
   git --no-pager diff --cached
   git status --porcelain
   ```
   Read the full staged diff. For new files, open them when the diff alone does not explain the change.
2. **Check staging.** If nothing is staged but the working tree has changes, say so and ask what to stage. Only `git add` what the user names (or everything, if they say so). If there is nothing to commit, stop.
3. **Protected branch gate.** If the current branch is `main` or `master` (or the remote default), ask before going further: "This is `<branch>`. Are you sure you want to commit directly to it?" Options: Yes, continue / No, stop. On no, stop; nothing gets committed.
4. **Generate and show.** Produce the message per the rules file and display it in a fenced code block, exactly as it will be committed.
5. **Confirm.** Ask "Commit with this message?" with options:
   - Yes, commit
   - No, cancel
   - Make changes (the user describes the change; revise, then repeat steps 4 and 5)
6. **Commit on yes.** Use the local identity, nothing else:
   ```bash
   git commit -m "$(cat <<'MESSAGE
   <subject>

   <body>
   MESSAGE
   )"
   ```
   Omit the body block for subject-only messages. Then show the result so the user can verify the author:
   ```bash
   git --no-pager log -1 --pretty=fuller | head -n 12
   ```
   On no: stop and state clearly that nothing was committed.

## Flow B: squash PR message

One clean message for a PR that will be squash-merged, summarized from the branch's commits.

1. **Protected branch gate.** Get the current branch. If it is `main` or `master`, ask: "You are on `<branch>`. Continue with the squash message?" Options: Yes, continue / No, stop.
2. **Check that a PR exists** (read-only):
   ```bash
   gh pr view --json number,title,url,state,baseRefName
   ```
   If gh errors, finds no PR, or the PR is not OPEN: report exactly what you found and stop. There is nothing to write a squash message for.
3. **Fetch the branch's commit messages:**
   ```bash
   git --no-pager log main..HEAD --pretty=format:"%s%n%b%n---"
   ```
   Replace `main` with the PR's base branch when it differs, so the range matches what the PR actually merges; if there is no local ref for the base, use `origin/<base>`.
4. **Generate and show.** Apply the same rules file. The subject describes the PR's primary change (the PR title and the commit log help here); the body summarizes the notable secondary changes. Squashing collapses many commits into one, so this message becomes the only record of the branch: make it cover what the branch as a whole did.
5. **Confirm.** Ask "Use this squash message?" with options: Yes / No, cancel / Make changes (same revision loop as Flow A).
6. **Deliver on yes.** Print the final message as a plain fenced code block (subject, blank line, body), ready to paste into GitHub's "Squash and merge" dialog, and stop. No gh write commands, no commit, no push.

## Picking a flow

- Committing current or staged changes, or fixing one commit's message: Flow A.
- Anything about a PR merge message, squash merge, or summarizing a branch for review: Flow B.
- Ambiguous ("commit my PR branch"): ask which one they mean.
