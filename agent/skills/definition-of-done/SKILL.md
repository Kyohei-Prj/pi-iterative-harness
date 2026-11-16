---
name: definition-of-done
description: Define and enforce measurable Macro and Micro Definitions of Done with execution evidence, and classify review findings as blocking or non-blocking.
---

# Definition of Done

## Macro DoD

Express project-level outcomes as observable acceptance criteria. Each criterion has a verification method or an explicit human acceptance method.

## Micro DoD

For each slice specify:
- behavior/acceptance criteria;
- relevant unit, integration, and end-to-end scenarios (Playwright scenarios for browser-observable behavior);
- required build, lint, type-check, and regression checks, with exact commands;
- any security, data migration, compatibility, or documentation checks that apply;
- the evidence expected for each criterion.

## Gate rules

- PASS requires actual execution or direct inspection evidence.
- FAIL means the criterion was tested and did not pass.
- BLOCKED means it could not be verified.
- NOT_APPLICABLE requires a stated reason.
- Never infer PASS from code edits or an agent's assertion.
- Never weaken acceptance criteria merely to pass.
- The implementer cannot approve its own work.
- Only the Orchestrator runs the mandatory checks of record and records final status.
- A slice is DONE only when every mandatory criterion passes and the reviewer approves.

## Blocking vs non-blocking findings

A review finding is **BLOCKING** if it is any of:
- an acceptance criterion or Micro DoD item that fails or is unverified;
- a correctness defect or regression;
- a security, privacy, data-loss, or data-integrity risk;
- missing or misleading tests for the changed behavior;
- a violation of an accepted ADR;
- a break in build, lint, or type-check.

Everything else (style, naming, optional refactors, minor simplifications, extra test ideas) is **NON-BLOCKING** and goes to WORK.md Findings only if it affects a later slice. A project may tighten this list in `AGENTS.md`; it must not loosen it silently.
