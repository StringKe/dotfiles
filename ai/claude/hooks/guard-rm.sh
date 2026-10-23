#!/usr/bin/env bash
# guard-rm.sh - PreToolUse hook: 拦截 AI 真删文件的 rm, 强制改用 trash(进回收站)
#
# 适用运行时(均支持 PreToolUse + matcher Bash + exit 2 阻断, 脚本四家通用):
#   - Claude Code : ~/.claude/settings.json 的 hooks.PreToolUse
#   - Codex       : ~/.codex/config.toml 的 [[hooks.PreToolUse]] (或 ~/.codex/hooks.json)
#   - grok-build  : ~/.grok/hooks/*.json (并兼容读取 ~/.claude/settings.json 的 hooks 键)
#   - kimi-code   : ~/.kimi-code/config.toml 的 [[hooks]] (event=PreToolUse, matcher=Bash)
#
# 背景: 本机交互 zsh 的 rm() 函数把 rm 接管成 trash(进回收站)。Claude Code 的 Bash
#       工具经 shell 快照继承该函数，但 `command rm`、`/bin/rm`、`bash -c`、xargs、
#       find -exec 以及其他运行时的非交互 bash 仍是真删。此 hook 在工具层兜底。
#
# 行为: 读 stdin JSON 的 shell 命令字段，rm / unlink 处在命令位置或出现 find -delete 时 exit 2 阻断。
# 逃生口: 命令以 RM_OK=1 开头时放行(用户明确授权真删后才加, AI 不得自行添加)。
#
# trash 工具: macOS 14+ 自带 /usr/bin/trash, 无需额外安装。
# 命令位置: 行首、; & | ( { ` $( 之后，可隔着变量赋值与 sudo/command/xargs 等包装命令，
# 以及 find -exec 之后；sh/bash/zsh -c、eval、ssh 的字符串参数与命令替换按命令处理。
# 其余引号内的 rm(rg 'a|rm'、git commit -m 'rm x') 与 git rm 等子命令放行。
# 路径全部字面落在 /tmp、/private/tmp、/var/folders、$TMPDIR、$CLAUDE_JOB_DIR/tmp 之下(不含这些目录本身、不含 ..)的 rm 放行。
#
# 已知限制: 运行时没有把 shell 调用送入 PreToolUse 时，本脚本无法拦截。

export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
set -uo pipefail

input=$(cat)

# 提取 .tool_input.command (jq 优先, python3 兜底)
parse_rc=0
if command -v jq >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | jq -r \
        '.tool_input.command // .tool_input.cmd // .command // empty' 2>/dev/null) \
        || parse_rc=$?
elif command -v python3 >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
tool_input = payload.get("tool_input", {})
print(tool_input.get("command") or tool_input.get("cmd") or payload.get("command") or "")
' 2>/dev/null) || parse_rc=$?
else
    # 无 JSON parser 时扫描原始输入，宁可误拦也不放过真删。
    cmd="$input"
fi

if [ "$parse_rc" -ne 0 ]; then
    echo "[guard-rm] 拦截: 无法解析 shell 工具输入。" >&2
    exit 2
fi

# 空命令放行
[ -z "$cmd" ] && exit 0

# 逃生口: 去前导空白后以 RM_OK=1 开头 -> 放行
trimmed="${cmd#"${cmd%%[![:space:]]*}"}"
case "$trimmed" in
    "RM_OK=1 "*|"RM_OK=1") exit 0 ;;
esac

assign='([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
# 包装命令的选项可带一个参数（sudo -u root rm）
wrap='((sudo|doas|command|builtin|exec|env|nohup|time|nice|xargs|parallel|watch|then|do|else|if|while|until|!)([[:space:]]+-[^[:space:]]*([[:space:]]+[^-[:space:];&|][^[:space:];&|]*)?)*[[:space:]]+)*'
path='([^[:space:];&|(){}'"'"'"]*/)?'
prefix="[[:space:]]*${assign}${wrap}${assign}${path}(g?rm|unlink)"
end="([[:space:];&|)}'\"\`]|\$)"
p_cmd="(^|[;&|({\`]|\\\$\\(|-exec[[:space:]])${prefix}${end}"
p_subst="(\\\$\\(|\`)${prefix}${end}"
p_nested="((^|[[:space:]/])(sh|bash|zsh|dash)([[:space:]]+-[A-Za-z]+)*[[:space:]]+-[A-Za-z]*c|eval|ssh[[:space:]][^;&|'\"]*)[[:space:]]+['\"]([^'\"]*([;&|({\`]|\\\$\\())?${prefix}${end}"
p_find_delete="(^|[;&|({\`]|\\\$\\()[[:space:]]*${assign}${wrap}${path}find[[:space:]][^;&|]*[[:space:]]-delete([[:space:];&|)]|\$)"

# 引号内是数据，去掉后再找命令位置；会被当命令执行的字符串（sh -c、eval、ssh、命令替换）在原文上单独检查。
unquoted=$(printf '%s' "$cmd" | sed -E "s/'[^']*'/''/g; s/\"[^\"]*\"/\"\"/g")

tok="('[^']*'|\"[^\"]*\"|[^;&|)\`[:space:]'\"]+)"
tmp_re='^(/tmp/|/private/tmp/|/var/folders/|\$TMPDIR/?|\$\{TMPDIR\}/?|\$CLAUDE_JOB_DIR/tmp/|\$\{CLAUDE_JOB_DIR\}/tmp/)[^/[:space:]]'

# 每个 rm 调用都至少带一个路径，且全部路径静态可见地落在临时目录下时放行。
tmp_only() {
    local calls call arg found=0
    set -f
    calls=$(printf '%s' "$cmd" | grep -Eo "(^|[^[:alnum:]_.-])(g?rm|unlink)([[:space:]]+${tok})*([^[:alnum:]_.-]|$)") || return 1
    while IFS= read -r call; do
        found=0
        for arg in $(printf '%s' "$call" | sed -E 's/^[^[:alnum:]_.-]?(g?rm|unlink)//' | grep -Eo "[[:space:]]${tok}" | tr -d "'\""); do
            case "$arg" in -*) continue ;; esac
            case "$arg" in *..*) return 1 ;; esac
            printf '%s' "$arg" | grep -Eq "$tmp_re" || return 1
            found=1
        done
        [ "$found" -eq 1 ] || return 1
    done <<< "$calls"
}

if printf '%s' "$unquoted" | grep -Eq -e "$p_find_delete"; then
    cat >&2 <<'MSG'
[guard-rm] 拦截: find -delete 会真删文件。
请改用: find ... -exec trash {} +
确需不可恢复真删且用户已明确授权时, 命令前加 RM_OK=1。
MSG
    exit 2
fi

if { printf '%s' "$unquoted" | grep -Eq -e "$p_cmd" \
    || printf '%s' "$cmd" | grep -Eq -e "$p_subst" -e "$p_nested"; } && ! tmp_only; then
    cat >&2 <<'MSG'
[guard-rm] 拦截: 检测到 rm 真删文件命令。
本机 rm 已被有意接管为 trash(进回收站)，不得绕过用 /bin/rm 真删。
请改用: trash <文件或目录>
确需不可恢复真删且用户已明确授权时, 命令前加逃生标记:
RM_OK=1 /bin/rm -rf <path>
MSG
    exit 2
fi

exit 0
