#!/usr/bin/env bash
# Claude Code status line: model | dir | git branch | context usage | cost | rate limits | elapsed time
# Reads the session JSON from stdin. Prints nothing if jq is missing.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

# One jq call; missing values fall back to defaults ("-" marks an absent
# value, since consecutive tabs would collapse when read with IFS=$'\t').
IFS=$'\t' read -r model dir pct cost ms rl5 rl7 < <(
  jq -r '[
    (.model.display_name // "?"),
    (.workspace.current_dir // .cwd // "-"),
    ((.context_window.used_percentage // 0) | floor),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    (.rate_limits.five_hour.used_percentage // "-" | if type == "number" then floor else . end),
    (.rate_limits.seven_day.used_percentage // "-" | if type == "number" then floor else . end)
  ] | @tsv' <<<"$input" 2>/dev/null
)
[ -n "$model" ] || exit 0

RESET=$'\033[0m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'

# Usage percentage color: yellow from 70%, red from 90%.
usage_color() {
  if [ "$1" -ge 90 ]; then
    printf '%s' "$RED"
  elif [ "$1" -ge 70 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

pct_color=$(usage_color "$pct")

secs=$((ms / 1000))
if [ "$secs" -ge 3600 ]; then
  elapsed=$(printf '%dh%02dm' $((secs / 3600)) $((secs % 3600 / 60)))
else
  elapsed=$(printf '%dm%02ds' $((secs / 60)) $((secs % 60)))
fi

sep="${DIM} | ${RESET}"
out="${CYAN}${model}${RESET}"

# Working directory (basename only).
if [ "$dir" != "-" ]; then
  out+="${sep}${BLUE}${dir##*/}${RESET}"
fi

# Git branch, or short hash on a detached HEAD. Omitted outside a repository.
if [ "$dir" != "-" ] && git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -n "$branch" ] || branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && out+="${sep}${MAGENTA}${branch}${RESET}"
fi

out+="${sep}${pct_color}${pct}%${RESET}"
out+="${sep}${YELLOW}$(printf '$%.2f' "$cost")${RESET}"
# Rate limits: each window is shown only when present (subscription accounts).
rl=""
if [ "$rl5" != "-" ]; then
  rl+="5h:$(usage_color "$rl5")${rl5}%${RESET}"
fi
if [ "$rl7" != "-" ]; then
  [ -n "$rl" ] && rl+=" "
  rl+="7d:$(usage_color "$rl7")${rl7}%${RESET}"
fi
[ -n "$rl" ] && out+="${sep}${rl}"

out+="${sep}${MAGENTA}${elapsed}${RESET}"

printf '%s\n' "$out"
