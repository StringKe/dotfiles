#!/usr/bin/env bash
# guard-ask.sh - PreToolUse(AskUserQuestion) hook：一次抛给用户超过 3 个问题时 exit 2，提示技术参数自己定。

export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
set -uo pipefail

input=$(cat)
count=$(printf '%s' "$input" | jq -r '.tool_input.questions | if type == "array" then length else 0 end' 2>/dev/null) || exit 0
[ "${count:-0}" -gt 3 ] || exit 0

printf '[guard-ask] 一次问了 %s 个问题。技术参数（架构、规格、版本、端口、命名、顺序）自己定并在总结里写假设，确认清单只留业务分歧，最多 3 项。\n' "$count" >&2
exit 2
