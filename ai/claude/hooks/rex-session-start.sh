#!/usr/bin/env bash
# rex-session-start.sh - SessionStart hook：输出 rex 的会话说明；会话已有名字时去掉「给会话起名」那一段，
# 改成提示本 pane 是已命名会话里的一个 tab，只用 rex window rename。

export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
set -uo pipefail

command -v rex >/dev/null 2>&1 || exit 0
out=$(rex __internal session-start --agent claude 2>/dev/null) || exit 0
[ -n "$out" ] || exit 0

label=""
if [ -n "${REX_SESSION:-}" ]; then
    label=$(rex session inspect "$REX_SESSION" --json 2>/dev/null | jq -r '.label // ""' 2>/dev/null) || label=""
fi

if [ -z "$label" ]; then
    printf '%s\n' "$out"
    exit 0
fi

printf '%s\n' "$out" | awk 'BEGIN { skip = 0 } /^Name the session/ { skip = 1 } skip && /^[[:space:]]*$/ { skip = 0; next } !skip'
printf '\n本会话已命名为 %s，当前 pane 是它里面的一个 tab。不要执行 rex session rename；要给本 tab 起名用 rex window rename。\n' "$label"
exit 0
