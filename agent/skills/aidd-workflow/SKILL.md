---
name: aidd-workflow
description: Orchestrator procedure for the project's full, thin, and resume AIDD workflows. Covers codebase-first planning, WORK.md lifecycle, delegation, stage-then-review-then-commit, review loop, ADRs, and completion.
---

# AIDD Workflow (Orchestrator procedure)

This is the authoritative procedure. The other skills hold the details for Git (`git-safety`), DoD gates and blocking definition (`definition-of-done`), slicing (`vertical-slicing`), and MCP tools (`mcp-tools`). Only the Orchestrator (the primary Pi agent) follows this file. Where the project you are working in has its own `AGENTS.md`, its rules apply on top of this procedure.

This skill bundles its blank state files in `templates/` (paths below are relative to this skill directory; Pi reports it when the skill loads):

- `templates/WORK.template.md` — the initiative working record, copied to `<project>/.aidd/WORK.md`.
- `templates/ADR.template.md` — an architectural decision record, copied to `<project>/.aidd/adr/ADR-NNNN-<kebab-title>.md`.

## Shared mechanics

### Status vocabulary
- Work/checks: `DONE`, `FAILED` (tested, did not pass), `BLOCKED` (could not be verified). Neither FAILED nor BLOCKED is DONE.
- Slice statuses in WORK.md: `PLANNED`, `APPROVED`, `IN_PROGRESS`, `VERIFYING`, `DONE`, `FAILED`, `BLOCKED`.

### Task packets
Subagents start in fresh context and have not seen this conversation. Every delegation must be self-contained: goal, scope and non-goals, relevant files/ADRs, the exact output contract, and any evidence they need pasted inline. Never tell a subagent to "continue from before".

### User-approval triggers
Ask the user before proceeding when a slice or change involves any of:
- adding, removing, or upgrading a dependency;
- a schema or data migration;
- a public API/contract or configuration-format change;
- authentication, authorization, secrets, payments, or other security/privacy-sensitive code;
- removing or changing existing user-visible behavior;
- exceeding the slice size cap (see `vertical-slicing`);
- ambiguity in product behavior that the approved DoD does not settle.

Otherwise proceed without asking. Do not ask approval for trivial implementation details.

### Post-implementer integrity check
Record `git rev-parse HEAD`, `git branch --show-current`, and the index tree from `git write-tree` before every implementer run. Afterwards confirm all three are unchanged: a moved index tree means the implementer staged something, so list what it staged with `git diff --cached --name-only <recorded-tree>` (the tree hash recorded before the run) and unstage only those explicit paths with `git restore --staged -- <paths>`, then report it; where a path was already staged before the run, restore it from the recorded tree with `git restore --source=<recorded-tree> --staged -- <paths>` so the pre-run entry survives. Never unstage the whole index: steps 11.3 and 11.7 mean the Orchestrator stages and restages legitimately, and in a fix round the index already holds that staging. Then confirm that `git status --short` shows only paths consistent with the slice (and nothing in `.aidd/WORK.md`, `.aidd/archive/`, or `.aidd/adr/` unless an ADR draft was requested). If anything differs, stop, report, and ask. Prompt rules are not an enforcement boundary; this check is.

### Review-fix loop
Maximum 3 review rounds per slice. A round is: implementer fix, rerun checks, restage, new `git write-tree`, reviewer re-review. If blocking findings remain after round 3, mark the slice `BLOCKED`, report the findings and options to the user, and stop. Do not commit.

### Failed or blocked slice
Never commit. Leave working-tree changes in place (never reset, clean, stash, or discard). If anything is staged and must not be, unstage only explicit paths with `git restore --staged -- <paths>`. Record FAILED/BLOCKED with evidence in WORK.md, report to the user, and ask how to proceed.

### ADR rules
- Create an ADR only for a significant, durable architectural decision, never for routine implementation choices. Read existing ADRs first.
- Location and name: `.aidd/adr/ADR-NNNN-<kebab-title>.md`, from `templates/ADR.template.md` in this skill directory. NNNN is the highest existing number plus one (0001 if none).
- The Orchestrator writes the ADR (or asks `aidd-implementer` to draft it at a given path). Write it BEFORE staging so it is reviewed and committed with the slice that embodies the decision. An ADR decided before the first slice (for example at Big Picture time) may go in the S-001 commit or its own `docs(adr): ...` commit.
- Accepted ADRs are historical records: supersede, never rewrite.

### WORK.md
`.aidd/WORK.md` is temporary, Git-ignored, never staged, and the only active initiative document. It must contain everything needed to resume after context loss, including the Exploration Summary and the Verification Commands, because conversation history is not a reliable store. Update it at every phase boundary.

## Full workflow

1. **IDEA_INTAKE.** Establish intent, expected behavior, constraints, non-goals, and success conditions. Ask only necessary questions. If `.aidd/WORK.md` already exists, stop and ask: resume it (use the Resume procedure) or archive it first.
2. **CODEBASE_EXPLORATION.** Must precede planning. Delegate a read-only task to `aidd-explorer` covering: structure and entry points; relevant modules, user flows, data flows; architecture and integration boundaries; dependencies and conventions; tests and the real build/lint/type-check/test commands; reusable components; risks and unknowns. For greenfield repos the report must say so and cover manifests/tooling instead. Require file paths and symbols, with facts separated from hypotheses.
3. **MACRO_DOD_AND_BIG_PICTURE.** Delegate to `aidd-planner` with the clarified idea, the explorer report, relevant ADRs, and conventions. Expect vision, scope/non-goals, measurable Macro DoD (each criterion with a verification method), architecture direction, risks, open questions, high-level roadmap, ADR candidates.
4. **USER_APPROVAL.** Present the Big Picture and Macro DoD for approval. No branch before approval.
5. **INIT_WORK_FILE.** Create `.aidd/WORK.md` from `templates/WORK.template.md` in this skill directory. Fill Objective, Macro DoD, Big Picture, Exploration Summary, and Verification Commands (exact commands from the explorer report, confirmed against manifests). Before writing it, confirm the project ignores it: `git check-ignore -q .aidd/WORK.md` must exit 0. If it does not, add `.aidd/WORK.md` and `.aidd/archive/` to the project's `.gitignore` (or `.git/info/exclude` when the user does not want the ignore committed) and report that you did.
6. **CREATE_INITIATIVE_BRANCH.** Confirm the base branch; check `git status --short` and the current branch; protect pre-existing user changes; create exactly one branch (`feature|bugfix|refactor|chore/<short-description>`). Never overwrite an existing branch. If a switch could affect uncommitted work, stop and ask. Fill the Initiative section of WORK.md.
7. **BASELINE_CHECK.** Before any change, run the full verification commands once on the new branch and record results in WORK.md (Baseline). Pre-existing failures are documented and are not attributed to slices. If the baseline cannot run or fails broadly, ask the user how to proceed.
8. **PLAN_NEXT_SLICE.** Delegate to `aidd-slicer` with WORK.md content (inline), relevant ADRs, and the latest evidence. Plan only the next slice in implementation detail. Record it under Current Slice, set `PLANNED`. Obtain user approval if any approval trigger applies; then set `APPROVED`.
9. **IMPLEMENT_SLICE.** Record `HEAD`, the branch, and `git write-tree` (integrity check), set `IN_PROGRESS`, and delegate exactly one approved slice to `aidd-implementer` with scope, Micro DoD, relevant files, ADR constraints, verification plan, and the Direction block (the Macro DoD, and the Big Picture). The Direction block orients judgment about placement and shape; it is not scope. Then run the post-implementer integrity check.
10. **VERIFY_SLICE.** Set `VERIFYING`. The Orchestrator itself runs the required checks (build, lint, type-check, tests, and Playwright scenarios for browser-observable criteria) and records command, result, and evidence in WORK.md. Do not infer success from an agent's claim. A failed mandatory check means `FAILED`; an unavailable one means `BLOCKED`.
11. **STAGE_AND_REVIEW.** In this order:
    1. `git status --short` (this reveals untracked new files) and the complete unstaged diff.
    2. Write the ADR now if the slice embodies an architectural decision.
    3. Stage explicit paths belonging to the slice (`git add -- <paths>`).
    4. `git diff --cached --stat` and `git diff --cached`; confirm nothing unrelated, no secrets or local config, no generated artifacts, no `.aidd/WORK.md`, no `.aidd/archive/`.
    5. Record the staged tree hash: `git write-tree` (call it T).
    6. Delegate to `aidd-reviewer` with the review packet inline: slice definition, acceptance criteria, Micro DoD, stat, full staged diff, T, raw check output, relevant ADRs, round number, and for browser-observable criteria the Playwright output plus screenshots of the states that matter and any browser console errors. If the diff is too large to paste whole, the slice is too large: split it.
    7. On `CHANGES_REQUIRED`: send only the blocking findings to `aidd-implementer`, run the integrity check, rerun checks, restage, record the new T, and re-review (loop cap above). Non-blocking observations go to WORK.md Findings.
    8. On `BLOCKED`: supply the missing evidence if possible; otherwise follow Failed or blocked slice.
12. **COMMIT_SLICE.** Only when all mandatory Micro DoD items pass and the reviewer verdict is `APPROVED`:
    1. Run `git write-tree` again; it must equal the reviewed T. If not, the staged content changed after review: re-review.
    2. Last look at `git diff --cached`.
    3. Commit once, never with `--no-verify`. Message: conventional subject; 2-4 line body with what and why; trailers `Slice: S-NNN`, `Verified: <commands> pass`, `Review: aidd-reviewer APPROVED (round N)`.
    4. If a hook fails or modifies files, treat it as a failed check: fix, rerun checks, restage, new T, and have the reviewer re-review the delta.
    5. Confirm with `git status --short` and `git log -1 --stat`.
13. **UPDATE_WORK.** Set the slice `DONE`, record the commit hash and concise findings, and the next open question. Never stage WORK.md.
14. **ITERATE.** Feed actual implementation, test, review, and runtime findings to `aidd-slicer` and repeat steps 8-13 against the current codebase, not stale assumptions.
15. **COMPLETE_INITIATIVE.** Verify every Macro DoD criterion with evidence; run final regression/build/lint/type-check; inspect the branch commits and `git diff <base>...HEAD`; confirm no uncommitted initiative changes remain (ADRs included); move `.aidd/WORK.md` to `.aidd/archive/YYYY-MM-DD-<branch-with-slashes-replaced-by-dashes>-WORK.md`; keep ADRs tracked. Report the branch, slice commits, verification evidence, remaining risks, and what is unverified. Do not push, merge, open a PR, or delete the branch without explicit authorization.

## Thin workflow

For a localized bug fix, small improvement, minor refactor, or small configuration change.

1. Intake and clarify the request.
2. Focused read-only investigation by `aidd-explorer` only if the code path or test strategy is unclear.
3. Define the Micro DoD and verification commands.
4. Ask the user when an approval trigger applies or scope is ambiguous.
5. Check base branch and working tree, then create one initiative branch. Run the relevant existing checks first to establish a baseline.
6. Delegate exactly the approved change to `aidd-implementer`; run the integrity check.
7. Verify (Orchestrator runs checks).
8. Stage and review exactly as full-workflow step 11. Independent review is always required unless the change is documentation-, comment-, or formatting-only; any waiver must be stated in the final report.
9. Commit exactly as full-workflow step 12.
10. Record an ADR only for a durable architectural decision. WORK.md is optional; if used, the same ignore and no-staging rules apply.
11. Report commit, verification evidence, and residual risks. Do not push or merge without authorization.

### Escalate thin to full
Switch to the full workflow (reusing the exploration done so far, resuming at step 3) when: the change needs more than one slice, spans multiple modules or layers, hits an architectural decision, or exploration reveals scope beyond the original request. Tell the user why.

## Resume procedure
Use after interruption, a new session, or context compaction (`/resume-workflow`):
1. Read `.aidd/WORK.md` fully.
2. Run `git branch --show-current`, `git status --short`, and `git log --oneline <base>..HEAD`.
3. Reconcile: every slice marked DONE must have a commit on the branch; any slice marked IN_PROGRESS/VERIFYING needs its uncommitted changes inspected (`git diff`, `git diff --cached`) before anything else.
4. Report the reconciled state, discrepancies, and the proposed next step. Ask the user to confirm before continuing. Never assume prior agent results still hold; rerun checks when in doubt.
