#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
DIM='\033[2m'
RESET='\033[0m'

if [ -n "$pct" ]; then
  pct_int=$(printf "%.0f" "$pct")
  if [ "$pct_int" -ge 90 ]; then pct_color="$RED"
  elif [ "$pct_int" -ge 70 ]; then pct_color="$YELLOW"
  else pct_color="$GREEN"
  fi
  ctx_str="$(printf "${pct_color}🧠 %s%%${RESET}" "$pct_int")"
else
  ctx_str="$(printf "${DIM}🧠 --${RESET}")"
fi

if [ -n "$total_cost" ]; then
  cost_display=$(awk "BEGIN { printf \"%.2f\", $total_cost }")
  cost_str="$(printf "💰 \$%s" "$cost_display")"
else
  cost_str="💰 \$0.00"
fi

diff_str=""
[ "$lines_added" -gt 0 ] && diff_str="${diff_str}$(printf "${GREEN}+%s${RESET}" "$lines_added")"
[ "$lines_removed" -gt 0 ] && diff_str="${diff_str}$(printf " ${RED}-%s${RESET}" "$lines_removed")"
[ -z "$diff_str" ] && diff_str="$(printf "${DIM}±0${RESET}")"

branch=""
pr_link=""
pr_icon=""
if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ] && command -v gh >/dev/null 2>&1; then
    pr_json=$(cd "$dir" && gh pr view --json url,state 2>/dev/null)
    pr_link=$(echo "$pr_json" | jq -r '.url // empty')
    pr_state=$(echo "$pr_json" | jq -r '.state // empty')
    case "$pr_state" in
      MERGED) pr_icon="🟣" ;;
      CLOSED) pr_icon="🔴" ;;
      OPEN) pr_icon="🟢" ;;
    esac
  fi
fi

if [ -n "$branch" ]; then
  git_str="$(printf "🌿 %s" "$branch")"
else
  git_str="$(printf "${DIM}no branch${RESET}")"
fi

printf "🤖 %s | %b | %b | %b | %b\n" \
  "$model" "$ctx_str" "$cost_str" "$diff_str" "$git_str"
if [ -n "$pr_link" ]; then
  printf "%s ${CYAN}%s${RESET}\n" "$pr_icon" "$pr_link"
fi
exit 0
