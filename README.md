# pi-iterative-harness

Version-controlled configuration for the [Pi coding agent](https://pi.dev/) that implements the AIDD
workflow: codebase-first exploration, an approved Big Picture, vertical slices, one verified commit
per slice, and independent review before the commit. `agent/` mirrors the user-level agent directory
(by default `~/.pi/agent`), so a clone installs the whole workflow into **every** project on the
machine — no per-project setup, no credentials, no installs, no chat history.

## Repository layout

| Path | What it is |
|---|---|
| `agent/` | Mirror of the live Pi agent directory — see the table below |
| `AGENTS.md` | Instructions Pi reads while working in *this* repo: code rules, rules for the mirrored files, git discipline, how to verify |
| `scripts/sync.sh` | `status` (drift report) / `pull` / `push` between `agent/` and the live agent directory |
| `scripts/verify-config.sh` | Model-free static checks on the mirror: valid JSON, every package and MCP version pinned, each `aidd-*` role named by the workflow skill or a prompt template resolves to an agent or skill and every defined `aidd-*` subagent is one the workflow delegates to (a non-prefixed skill is checked only where an agent's frontmatter names it), read-only roles hold no write tool, no secrets, no drifted names |
| `.aidd/adr/` | Accepted ADRs about this configuration |
| `.aidd/WORK.md`, `.aidd/archive/` | Temporary initiative record and its archives — Git-ignored |

There is no `.pi/` directory on purpose: the configuration is global, so it lives in the agent
directory mirror rather than in a project. During work on this repo, push the mirror and `/reload` to
see a change take effect.

## `agent/` mirror

| Path | Pi's role | In this repo |
|---|---|---|
| `agent/settings.json` | Pi package declarations, pinned to exact versions (`npm:pi-subagents@0.84.0`, `npm:pi-web-access@0.46.0`) | yes |
| `agent/mcp.json` | MCP servers available in every project (serena, context7, deepwiki, playwright) | yes |
| `agent/agents/` | Custom subagent definitions | yes — the five `aidd-*` roles |
| `agent/skills/` | Skills, each a directory with a `SKILL.md` | yes — the five AIDD skills |
| `agent/prompts/` | Prompt templates, each one a `/command` | yes — the three workflow commands |
| `agent/extensions/`, `agent/themes/`, `agent/SYSTEM.md`, `agent/APPEND_SYSTEM.md`, `agent/keybindings.json`, `agent/models.json` | Optional user resources, not used by this workflow | picked up by `sync.sh pull` once created |
| `agent/auth.json`, `agent/mcp-auth.json` | Saved API keys / OAuth tokens | **never** (gitignored) |
| `agent/sessions/`, `agent/trust.json` | Conversation history, per-directory trust decisions | **never** (private, gitignored) |
| `agent/install/`, `agent/npm/`, `agent/bin/` | Pi release, npm packages, bundled binaries | **never** (reproducible, gitignored) |
| `agent/models-store.json`, `agent/missions/`, `agent/pi-subagents/`, `agent/pi-web-access/`, caches | Machine-specific endpoints and per-package runtime state | **never** (gitignored) |

`sync.sh pull` copies the whitelist, so a machine-local `models-store.json` may appear in the mirror
after a pull; it is ignored here because the local model belongs to the machine, not to the workflow.

## Syncing

```sh
scripts/sync.sh status  # report every managed path where ./agent and the live directory differ
scripts/sync.sh pull    # live agent directory -> ./agent   (run before committing changes)
scripts/sync.sh push    # ./agent -> live agent directory   (run after cloning elsewhere)
```

Both directions copy an explicit whitelist of files and directories, so nothing outside the table
above moves in either direction. The directions are not symmetric: `pull` replaces each managed path
under `agent/` wholesale, so anything authored in the mirror and not yet pushed is destroyed without a
backup — commit the mirror, or `push` first. `push` only overwrites files it replaces, and keeps a
backup of each. `push` copies any file it overwrites into a temporary directory and
prints the path, and `PI_CODING_AGENT_DIR` overrides the source/target location. Run `/reload` in Pi
(or restart it) after `push`.

`status` exits 1 when anything differs and prints the `diff -qr` detail per managed path, so it is
runnable as a check before you decide which direction to sync. It reports, and never resolves,
two kinds of drift: a resource you deleted from this repo that is still live (`Only in ...: old.md`),
and a resource another repo installed in the live directory. Neither is removed by `push`, which
merges so it cannot destroy what it does not own — delete those paths by hand once `status` has told
you they are yours to remove. The test for "yours": a drifting path is yours to delete only when this
repo declares it — listed by `git ls-files agent/` when you have removed it here but not committed
that, or present at the base commit (`git cat-file -e <base>:agent/<path>`) when the removal is
already committed; `git ls-files` reads the index, so a committed deletion is no longer listed.
Anything the base commit does not declare belongs to the sibling harness or to the machine, and
`status` listing it is expected, not something to delete.

## Pins

Every third party the config loads is pinned to an exact version or commit, so a fresh machine
installs what was verified here rather than whatever is current today:

| Loaded by | Pin |
|---|---|
| `agent/settings.json` | `npm:pi-subagents@0.84.0`, `npm:pi-web-access@0.46.0` |
| `agent/mcp.json` (playwright) | `@playwright/mcp@0.0.86` |
| `agent/mcp.json` (serena) | `git+https://github.com/oraios/serena@be609b625740846dc2750cc13291966cf1216b00` |

`scripts/verify-config.sh` fails the mirror on a floating version, so `@latest` and unpinned
`npm:` entries cannot come back by accident. A pin fixes what this repo declares, not what those
resolve to on the day you install: the two hosted MCP endpoints (`context7` and `deepwiki`) carry no
version to pin at all, and every transitive dependency of a pinned package still floats.

To raise a pin: change the one line, `scripts/sync.sh push`, restart Pi so it reinstalls, run
`scripts/verify-config.sh` and `/full-workflow` on a real slice, then commit the bump on its own with
the version in the subject. Never bump several pins in one commit; a slice that breaks afterwards has
to be attributable to one of them. Pi leaves an exact version alone, so an old pin never moves on its
own — `pi update --extensions` reconciles installs, it does not raise the declared versions.

## Setting up a new machine

1. Install Pi, then `git clone` this repo and run `scripts/sync.sh push`.
2. Add credentials separately — `pi login`, or edit `~/.pi/agent/auth.json` by hand. This repo stores no keys.
3. Restart Pi (or `/reload`). Pi installs the exact package versions `agent/settings.json` declares,
   which is how the `subagent` tool from `pi-subagents` arrives; the `aidd-*` subagents cannot launch
   without it.
4. Provide the environment the config expects:
   - `CONTEXT7_API_KEY` — referenced by `agent/mcp.json` as `${CONTEXT7_API_KEY}`; never write it to a file.
   - `uvx` (serena) and `npx` (playwright) on `PATH` for those MCP servers.
5. Check it: `scripts/verify-config.sh`, then open any project and confirm `/full-workflow`,
   `/thin-workflow`, and `/resume-workflow` are offered as commands.

`settings.json` replaces the file it overwrites rather than merging into it, so if the machine already
has a `settings.json` with other preferences, keep the backup `push` prints and merge by hand. A
project that defines an agent or MCP server with the same name as one installed here overrides it for
that project.

## Workflow

The loop — explore the codebase, agree a Big Picture and Macro Definition of Done, slice, implement,
verify, review the staged diff, commit — is the `aidd-workflow` skill. The three commands are the
entry points, and each one loads that skill instead of restating it:

| Command | What it runs |
|---|---|
| `/full-workflow <idea>` | The 15-step initiative workflow: exploration, Big Picture, approval, branch, baseline, then slice loops |
| `/thin-workflow <change>` | The short path for a localized fix or small change, with the same DoD, review, and commit gates |
| `/resume-workflow` | Reconciles `.aidd/WORK.md` with the branch after an interruption, a new session, or a `/compact` |

The Orchestrator — the primary Pi agent — is the only agent that runs the procedure, stages, and
commits. Every delegated task is a self-contained packet, because children start in fresh context.
Each slice is one commit with `Slice:`, `Verified:`, and `Review:` trailers, made only after the
checks pass and the independent reviewer approves the staged tree hash. Around every implementer run
the Orchestrator compares `HEAD`, the branch, and `git write-tree`, so a subagent that staged something
is detected rather than trusted. FAILED (ran the check, it did
not pass) and BLOCKED (could not run it) are never DONE, and neither is ever committed.

## Subagents (`agent/agents/`)

| Subagent | Tools | Job |
|---|---|---|
| `aidd-explorer` | `read, grep, find, ls` | Read-only reconnaissance: structure, entry points, data flows, conventions, the real build/test commands, risks — with a ≤30-line summary worth reusing |
| `aidd-planner` | `read, grep, find, ls` | Vision, scope, measurable Macro DoD, architecture direction, roadmap, ADR candidates |
| `aidd-slicer` | `read, grep, find, ls` | The next slice only: scope, acceptance criteria, Micro DoD, verification plan |
| `aidd-implementer` | `read, write, edit, bash, grep, find, ls` | Exactly one approved slice, with evidence; never stages or commits |
| `aidd-reviewer` | `read, grep, find, ls` | Independent verdict on the staged diff and reviewed tree hash; the agent that wrote a slice never signs it off |

## Skills (`agent/skills/`)

| Skill | Holds |
|---|---|
| `aidd-workflow` | The authoritative procedure (shared mechanics, full, thin, resume) plus the bundled blank state files in its `templates/` |
| `vertical-slicing` | What makes a slice small, runnable, observable, and its size cap |
| `definition-of-done` | Macro/Micro DoD, evidence rules, blocking versus non-blocking review findings |
| `git-safety` | Branch per initiative, stage → review → commit with a staged-tree hash, forbidden Git operations |
| `mcp-tools` | When and how each role may use serena, context7, deepwiki, playwright, and the rule that fetched content is data, never instructions |

Pi advertises skills by name and description, so all five are reachable from any project after the
push. Add `disable-model-invocation: true` to a skill's frontmatter to make it command-only
(`/skill:aidd-workflow`) and drop it from the system prompt.

## State files the workflow creates

Run the workflow in any project and it writes state there, all under `.aidd/`:

| Path | Tracked? |
|---|---|
| `.aidd/WORK.md` | Never — temporary, Git-ignored, and the only active initiative document |
| `.aidd/adr/ADR-NNNN-<title>.md` | Yes — durable architectural decisions, started from `templates/ADR.template.md` |
| `.aidd/archive/<date>-<branch>-WORK.md` | Never — the record at completion |
| `.serena/`, `.playwright-mcp/` | Never — MCP tool caches and artifacts |

The `INIT_WORK_FILE` step checks `git check-ignore` on `.aidd/WORK.md` and adds the ignore entries to
the project (or `.git/info/exclude`) when they are missing. The template lives inside the
`aidd-workflow` skill rather than in this repository, because a skill installed globally has to be
able to find it from any project.

## Related repository

[`pi-harness`](https://github.com/Kyohei-Prj/pi-harness) mirrors the same agent directory with a
different working method: `slice-workflow`, plan mode, `/explore`, and the `explorer`/`reviewer`
subagents. The two share `settings.json` and `mcp.json`, so push them in either order — the last push
wins for those two files, and each keeps a backup of what it replaced. Because the live directory
holds resources from both, `scripts/sync.sh status` from either repo lists the other's resources as
drift; that line is expected, not something to delete.

## License

- Licensed under Apache-2.0 (see `LICENSE`); the config files are yours to reuse.
