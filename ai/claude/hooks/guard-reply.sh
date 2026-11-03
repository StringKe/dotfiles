#!/usr/bin/env bash
# guard-reply.sh - Stop hook：最后一条回复中文占比过低时 exit 2 要求用中文重写。
# 去掉代码块、反引号、URL、路径与标识符后，按汉字与拉丁字母的比例判定；用 stop_hook_active 只拦一次。

export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
set -uo pipefail

input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

text=$(tail -c 4000000 "$transcript" \
    | jq -R 'fromjson? | select(.type == "assistant") | .message.content | if type == "array" then [.[] | select(.type == "text") | .text] | join("\n") else tostring end' 2>/dev/null \
    | jq -rs 'map(select(. != "")) | last // ""' 2>/dev/null)
[ -n "$text" ] || exit 0

verdict=$(printf '%s' "$text" | jq -Rrs '
    gsub("```[\\s\\S]*?```"; " ")
    | gsub("`[^`\n]*`"; " ")
    | gsub("https?://[^\\s)）]+"; " ")
    | gsub("[^\\s]*[/._][^\\s]*"; " ")
    | . as $t
    | ([$t | match("\\p{Han}"; "g")] | length) as $han
    | ([$t | match("[A-Za-z]"; "g")] | length) as $latin
    | if ($han + $latin) < 150 then "ok"
      elif ($han / ($han + $latin)) < 0.3 then "block \($han) \($latin)"
      else "ok" end' 2>/dev/null)

case "$verdict" in
    block*)
        printf '[guard-reply] 给用户看的回复要用简体中文（汉字 %s 个，拉丁字母 %s 个）。技术术语、命令、代码与路径保留原文，其余说明改写成中文后再结束。\n' "$(printf '%s' "$verdict" | cut -d' ' -f2)" "$(printf '%s' "$verdict" | cut -d' ' -f3)" >&2
        exit 2
        ;;
esac
exit 0
