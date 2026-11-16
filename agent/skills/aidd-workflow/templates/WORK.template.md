# Initiative: <short name>

> Temporary working record. Git-ignored. Never stage or commit this file.
> Must contain everything needed to resume after context loss. Keep concise.
> At completion, move it to `.aidd/archive/YYYY-MM-DD-<branch-with-dashes>-WORK.md`.

## Objective

<What user-visible outcome are we delivering?>

## Macro DoD

- [ ] <Observable project-level criterion> — verified by: <method>
- [ ] <Observable project-level criterion> — verified by: <method>

## Big Picture

<Short architecture direction and important flow. Link to ADRs where relevant.>

## Exploration Summary

<<= 30 lines from the explorer: entry points, key modules, conventions, major risks. Facts only.>

## Verification Commands

| Purpose | Command | Source |
|---|---|---|
| Build | `<cmd>` | <file where found> |
| Lint | `<cmd>` | |
| Type-check | `<cmd>` | |
| Unit tests | `<cmd>` | |
| Integration / e2e | `<cmd>` | |

## Initiative

- Branch: `<branch-name>`
- Base branch: `<base-branch>`
- Status: `IN_PROGRESS`

## Baseline (before any change)

| Check | Result | Notes (pre-existing failures) |
|---|---|---|
| <command> | PASS / FAIL / NOT_RUN | <...> |

## Slice Progress

| Slice | Outcome | Status | Commit |
|---|---|---|---|
| S-001 | <user-visible outcome> | PLANNED | — |

Allowed statuses: `PLANNED`, `APPROVED`, `IN_PROGRESS`, `VERIFYING`, `DONE`, `FAILED`, `BLOCKED`.

## Current Slice

### S-001 — <title>

**Objective:** <one sentence>

**In scope**
- <item>

**Out of scope**
- <item>

**Approval triggers hit:** <none | list, and whether approved>

**Acceptance criteria**
- [ ] <observable behavior>

**Micro DoD**
- [ ] <verification command/scenario and expected result>
- [ ] Independent review approved (round: <n>, reviewed tree: <hash>)

**Verification evidence**
| Check | Result | Evidence |
|---|---|---|
| <command/scenario> | NOT_RUN | <output or reference> |

## Findings / Open Issues

- <Only concise findings that affect the next slice.>

## Architectural Decisions

- <Link/reference to ADR files, if any. Do not duplicate ADR content.>
