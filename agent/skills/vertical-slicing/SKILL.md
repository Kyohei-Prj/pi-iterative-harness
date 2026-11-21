---
name: vertical-slicing
description: Plan small, runnable, user-observable vertical slices with explicit scope, a size cap, and concrete verification.
---

# Vertical Slicing

1. Deliver user-visible or externally observable behavior.
2. Include only the layers required for that behavior (for example UI -> API -> domain logic -> persistence).
3. Prefer one primary objective per slice.
4. Keep slices independently runnable or verifiable.
5. Define explicit in-scope and out-of-scope changes.
6. Ground test commands in repository manifests and existing conventions.
7. Sequence prerequisites before dependent behavior.
8. Avoid speculative abstractions, premature generalization, and unrelated refactoring.
9. Plan implementation detail only for the next slice; keep later roadmap items high-level.
10. Feed actual findings, test gaps, and architectural discoveries into the next slice plan.

## Size cap

A slice must be reviewable as one pasted diff, targetting one primary behavior.
If the work exceeds this, split it and plan only the first part.

Aim at the smallest safe root-cause fix, not the smallest diff. Never add a workaround, a duplicate code path, or a special case merely to stay under the cap: when the root cause is larger than the target, say so in the plan and ask for the larger scope.

## Readiness

A slice is not ready for implementation until its acceptance criteria and Micro DoD are observable and testable, and any user-approval trigger it hits (new dependency, migration, public API change, security-sensitive area, behavior removal) is flagged.
