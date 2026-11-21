---
name: git-safety
description: Safely manage one branch per initiative and one Orchestrator-owned commit per verified slice, using stage-then-review-then-commit with a staged-tree hash.
---

# Git Safety

## Branch

- One branch per initiative: `feature|bugfix|refactor|chore/<short-description>`.
- Full workflow: create after the approved Big Picture and Macro DoD. Thin workflow: after the Micro DoD is agreed.
- Confirm the base branch and inspect `git status --short` and the current branch first.
- Never overwrite an existing branch; if the name exists, ask whether to resume it or choose another.
- Never reset, clean, stash, discard, or switch away from changes that could be affected without explicit user authorization. If unrelated changes could be affected, stop and ask.
- Optional isolation: when the working tree is dirty or parallel work is likely, propose `git worktree add` for the initiative branch (with the user's approval). Keep `.aidd/WORK.md` inside that worktree.

## Commit

Only the Orchestrator runs `git add` and `git commit`. Subagents may run read-only Git commands at most (implementer) or none (reviewer).

Order of operations: **stage, review, commit.**

1. Verify every mandatory Micro DoD item.
2. `git status --short` (shows untracked new files) and the complete unstaged diff.
3. Stage explicit paths only (`git add -- <paths>`). Never `git add -A` or `git add .` by default.
4. `git diff --cached --stat` and `git diff --cached`.
5. Confirm nothing unrelated, no secrets, no local environment files, no generated artifacts, no `.aidd/WORK.md`, no `.aidd/archive/`, no `.serena/` or `.playwright-mcp/` contents.
6. `git write-tree`; record the hash. The reviewer reviews exactly this staged content.
7. After reviewer `APPROVED`, run `git write-tree` again. If it differs from the reviewed hash, the staged content changed: re-review.
8. Commit once for the slice. Never use `--no-verify`. If a hook fails or rewrites files, treat that as a failed check: fix, rerun checks, restage, new hash, re-review the delta.

Unstaging is allowed only for explicit paths: `git restore --staged -- <paths>`. It never touches the working tree.

If unrelated and initiative changes are mixed in one file and cannot be staged safely, stop and ask.

Commit message format:

```text
feat(tasks): add task creation and listing

Creates tasks via POST /tasks and lists them on the home view.

Slice: S-001
Verified: npm test, npm run lint, npm run typecheck pass
Review: aidd-reviewer APPROVED (round 1)
```

A failed or blocked verification is not a completed slice and must not be committed. Do not weaken acceptance criteria to make a slice pass.

## Integrity check

Record `HEAD`, the current branch, and `git write-tree` before each implementer run and confirm all three are unchanged afterwards: a moved index tree means the implementer staged something. To find which paths, run `git diff --cached --name-only <recorded-tree>` against the tree hash recorded before the run — it lists exactly what the implementer moved into the index — then unstage only those explicit paths with `git restore --staged -- <paths>` and report it. Where a path was already staged before the run, restore it from the recorded tree instead (`git restore --source=<recorded-tree> --staged -- <paths>`), or the pre-run entry is lost. Never unstage the whole index or a wildcard: during a review-fix round the index legitimately holds the Orchestrator's own staging from steps 3-4 above.

The tool allowlist and these rules are prompt boundaries, not enforcement; the hash check is what detects a violation. `pi-subagents` can gate a child's `write`/`edit` with `permission:` frontmatter, but bash rules are rejected by design, so no rule there can block a Git command.

## Push, merge, and cleanup

Do not push, merge, open a PR, or delete branches without explicit authorization.
