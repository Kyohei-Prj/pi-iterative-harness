#!/bin/sh
# Static checks on the mirrored Pi config in agent/, without a model or the network.
#
#   scripts/verify-config.sh
#
# Catches the ways this repo can drift: a missing mirror file, invalid JSON, a floating package
# or MCP version, a dangling skill or subagent reference, an agent whose `name:` disagrees with its
# filename, a read-only role that was handed a write tool, a skill whose directory and `name:`
# disagree, a bundled template that moved, or a secret file that slipped into the mirror.
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
agent_dir=$repo_dir/agent
fail=0

ok() { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

frontmatter() {
	awk 'NR == 1 && $0 == "---" { inb = 1; next } inb && $0 == "---" { exit } inb { print }' "$1"
}

field() { frontmatter "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1; }

json_parses() {
	node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$1" 2>/dev/null
}

json_list() {
	node -e 'for (const v of JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))[process.argv[2]] ?? []) console.log(v)' "$1" "$2" 2>/dev/null
}

json_mcp_args() {
	node -e 'const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).mcpServers ?? {}; for (const s of Object.values(m)) for (const a of s.args ?? []) console.log(a)' "$1" 2>/dev/null
}

# A pin is an exact version or an immutable commit; a range or a tag name can still move.
pinned() { printf '%s' "$1" | grep -Eq '(@|\+)([0-9]+\.[0-9]+\.[0-9]+|[0-9a-f]{7,40})$'; }

# $1 = an http-shaped MCP arg; true when it points at a source archive rather than an endpoint.
http_source_archive() { printf '%s' "$1" | grep -Eq '\.tar\.gz|\.tgz|/archive/|refs/heads/'; }

has_schema_key() {
	node -e 'process.exit(typeof JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).$schema === "string" ? 0 : 1)' "$1" 2>/dev/null
}

writable_tools() { printf '%s' "$1" | tr ',' ' ' | grep -owE 'write|edit|bash' | sort -u | tr '\n' ' ' | sed 's/ $//'; }

writer_tools='bash edit write'

# $1 = a tools allowlist; prints the writer tools the role is missing.
missing_writer_tools() {
	for w in $writer_tools; do printf '%s' "$1" | tr ',' ' ' | grep -qw -- "$w" || printf '%s ' "$w"; done
}

subagent_names() { for a in "$agent_dir"/agents/*.md; do field "$a" name; done; }

# The procedure's own text — the workflow skill and the prompt templates that invoke it — held in the
# script's positional parameters, because POSIX sh has no arrays and this script takes no arguments.
set -- "$agent_dir/skills/aidd-workflow/SKILL.md" "$agent_dir"/prompts/*.md

referenced_roles() { grep -hoE 'aidd-[a-z-]+' "$@" 2>/dev/null | sort -u; }

printf 'mirror files\n'
for f in settings.json mcp.json; do
	[ -f "$agent_dir/$f" ] && ok "$f" || bad "$agent_dir/$f is required"
done
for f in auth.json mcp-auth.json; do
	[ -e "$agent_dir/$f" ] && bad "$agent_dir/$f must never be committed" || ok "no $f in the mirror"
done

printf 'json\n'
for f in "$agent_dir"/*.json; do
	[ -f "$f" ] || continue
	json_parses "$f" && ok "$(basename -- "$f") parses" || bad "$(basename -- "$f") is not valid JSON"
done

printf 'pins\n'
has_schema_key "$agent_dir/settings.json" && ok 'settings.json declares $schema' || bad 'settings.json: add "$schema": "https://pi.dev/schemas/settings.schema.json"'
json_list "$agent_dir/settings.json" packages | grep -q . || bad "settings.json declares no packages"
for p in $(json_list "$agent_dir/settings.json" packages); do
	pinned "$p" && ok "$p" || bad "$p is unpinned; pin an exact version, because every project on the machine loads it"
done
for a in $(json_mcp_args "$agent_dir/mcp.json"); do
	case "$a" in
		git+*) pinned "$a" && ok "$a" || bad "mcp.json: $a has no pinned commit hash" ;;
		http* | *//*) http_source_archive "$a" && bad "mcp.json: $a is a source archive, not an endpoint; a tarball from a branch moves, so point at an endpoint or a pinned commit" || : ;;
		*@*) pinned "$a" && ok "$a" || bad "mcp.json: $a floats; pin an exact version" ;;
	esac
done

printf 'skills\n'
skill_names=$(mktemp)
for s in "$agent_dir"/skills/*/SKILL.md; do
	[ -f "$s" ] || { bad "no skill found under $agent_dir/skills"; break; }
	dir=$(basename -- "$(dirname -- "$s")")
	name=$(field "$s" name)
	[ "$dir" = "$name" ] && ok "$dir" || bad "$s: name '$name' disagrees with directory '$dir'"
	printf '%s\n' "$name" >>"$skill_names"
done
[ -f "$agent_dir/skills/aidd-workflow/templates/WORK.template.md" ] && ok "bundled WORK template" || bad "agent/skills/aidd-workflow/templates/WORK.template.md missing"
[ -f "$agent_dir/skills/aidd-workflow/templates/ADR.template.md" ] && ok "bundled ADR template" || bad "agent/skills/aidd-workflow/templates/ADR.template.md missing"

printf 'agents\n'
for a in "$agent_dir"/agents/*.md; do
	[ -f "$a" ] || { bad "no agent definition under $agent_dir/agents"; break; }
	name=$(field "$a" name)
	[ -n "$name" ] || bad "$a: missing name"
	[ "$(basename -- "$a" .md)" = "$name" ] && ok "agent $name" || bad "$a: name '$name' disagrees with the filename"
	case $(field "$a" tools) in '' | inherit) bad "$a: tools must name an explicit allowlist" ;; *) ok "$name tools: $(field "$a" tools)" ;; esac
	case "$name" in
		aidd-implementer) missing=$(missing_writer_tools "$(field "$a" tools)"); test -z "$missing" && ok "$name holds the writer tools" || bad "$a: only the implementer edits code, so its tools must include $writer_tools but it lacks $missing" ;;
		*) test -z "$(writable_tools "$(field "$a" tools)")" && ok "$name is read-only" || bad "$a: $name must stay read-only but holds $(writable_tools "$(field "$a" tools)")" ;;
	esac
	for s in $(field "$a" skills | tr ',' ' '); do
		grep -qx -- "$s" "$skill_names" && ok "$name -> skill $s" || bad "$name: skill '$s' is not in agent/skills/"
	done
done

printf 'prompts\n'
for p in "$agent_dir"/prompts/*.md; do
	[ -f "$p" ] || { bad "no prompt template under $agent_dir/prompts"; break; }
	[ -n "$(field "$p" description)" ] && ok "/$(basename -- "$p" .md)" || bad "$p: missing description"
done

printf 'delegations\n'
for ref in $(referenced_roles "$@"); do
	if [ -f "$agent_dir/agents/$ref.md" ] || grep -qx -- "$ref" "$skill_names"; then ok "$ref resolves"; else bad "$ref: named by the workflow but no such agent or skill"; fi
done
for n in $(subagent_names); do
	grep -qw -- "$n" "$@" 2>/dev/null && ok "$n is delegated to" || bad "$n is defined but neither the workflow skill nor a prompt template delegates to it"
done

rm -f -- "$skill_names"
[ "$fail" -eq 0 ] && echo "config ok: $agent_dir" || { echo "config check FAILED" >&2; exit 1; }
