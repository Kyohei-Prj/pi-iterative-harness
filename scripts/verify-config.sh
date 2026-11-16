#!/bin/sh
# Static checks on the mirrored Pi config in agent/, without a model or the network.
#
#   scripts/verify-config.sh
#
# Catches the ways this repo can drift: a missing mirror file, invalid JSON, a dangling
# skill reference in an agent's frontmatter, a skill whose directory and `name:` disagree,
# a bundled template that moved, or a secret file that slipped into the mirror.
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
	case $(field "$a" tools) in '' | inherit) bad "$a: tools must name an explicit allowlist" ;; *) ok "$name tools: $(field "$a" tools)" ;; esac
	for s in $(field "$a" skills | tr ',' ' '); do
		grep -qx -- "$s" "$skill_names" && ok "$name -> skill $s" || bad "$name: skill '$s' is not in agent/skills/"
	done
done

printf 'prompts\n'
for p in "$agent_dir"/prompts/*.md; do
	[ -f "$p" ] || { bad "no prompt template under $agent_dir/prompts"; break; }
	[ -n "$(field "$p" description)" ] && ok "/$(basename -- "$p" .md)" || bad "$p: missing description"
done

rm -f -- "$skill_names"
[ "$fail" -eq 0 ] && echo "config ok: $agent_dir" || { echo "config check FAILED" >&2; exit 1; }
