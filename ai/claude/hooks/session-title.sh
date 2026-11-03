#!/usr/bin/env bash
# session-title.sh - SessionStart / UserPromptSubmit hook：未命名的会话用 Claude Code 自动生成的 ai-title 设为会话名。
# 交互会话不起名时，其他会话的 ListAgents / SendMessage 只能用「目录名-两位hex」称呼它。
# 会话已有 agent-name（/rename、-n 或本 hook 设过）时不再改，避免对方正在用的名字中途变掉。
# 新会话的 ai-title 在第一条消息之后才生成，所以从第二条消息起生效。

export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
set -uo pipefail

input=$(cat)
event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty') || exit 0
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty') || exit 0
[[ -n $event && -f $transcript ]] || exit 0

rg -q -F '"type":"agent-name"' "$transcript" && exit 0

title=$(rg -N -F '"type":"ai-title"' "$transcript" | tail -n 1 | jq -r '.aiTitle // empty')
[[ -n $title ]] || exit 0

jq -n --arg e "$event" --arg t "$title" '{hookSpecificOutput: {hookEventName: $e, sessionTitle: $t}}'
