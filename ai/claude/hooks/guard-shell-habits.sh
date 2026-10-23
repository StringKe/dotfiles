#!/usr/bin/env bash
# guard-shell-habits.sh - PreToolUse(Bash) hook：拦截规则写了但 agent 仍反复违反的命令形状，exit 2 并提示改法。
#   1. 用 cat / head / tail / nl / sed -n 直接把文件正文打到终端（输出没有再接管道过滤）-> 用 Read 加 offset/limit
#   2. 测试、ci、check 命令接 | tail / | head -> 日志直接流出，长任务放后台
#   3. 项目 mise.toml 定义了 <app>:test 时直接跑 vendor/bin/pest、phpunit 或 artisan test -> 走 mise run <app>:test
#   4. 顶层再包一层 zsh -c / bash -c -> Bash 工具本身就是 zsh，直接写命令或写成脚本文件
# 逃生口: 命令以 SHELL_OK=1 开头时放行（用户明确要求这样写时才加）。

export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
set -uo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -z "$cmd" ] && exit 0

trimmed="${cmd#"${cmd%%[![:space:]]*}"}"
case "$trimmed" in "SHELL_OK=1 "*) exit 0 ;; esac

block() {
    printf '[guard-shell-habits] %s\n确需这样写且用户已同意时，命令前加 SHELL_OK=1。\n' "$1" >&2
    exit 2
}

lead='(^|[;&(]|&&|\|\|)[[:space:]]*'
ext='\.(php|md|mdx|ts|tsx|js|mjs|cjs|vue|json|ya?ml|toml|go|rs|py|sh|zsh|css|scss|html|sql|log|txt|neon|xml|ini|conf)'
tail_unpiped='([[:space:]"'"'"'][^|;&]*)?($|[;&])'

p_read="${lead}(cat|nl|bat|less|more|head|tail)([[:space:]]+-[^vfF[:space:]][^[:space:]]*)*[[:space:]]+[^-|;&<>][^|;&<>]*${ext}[\"']?${tail_unpiped}"
p_sed="${lead}sed[[:space:]]+-n[[:space:]]+['\"]?[0-9,\$]+p['\"]?[[:space:]]+[^-|;&<>][^|;&<>]*${ext}[\"']?${tail_unpiped}"
if printf '%s' "$cmd" | grep -Eq -e "$p_read" -e "$p_sed"; then
    block '检测到用 cat/head/tail/sed -n 直接输出文件正文。读文件用 Read（大文件带 offset/limit），定位行号先用 rg -n。'
fi

p_testpipe='(mise run[^|;&]*:(test|ci|check|typecheck|lint)|vendor/bin/(pest|phpunit)|artisan test|(npm|pnpm|bun) (run )?test|cargo (test|clippy|check)|go test)([^|;&]|[0-9]?>&[0-9])*\|[[:space:]]*(tail|head)([[:space:]]|$)'
if printf '%s' "$cmd" | grep -Eq -e "$p_testpipe"; then
    block '测试、ci、check 的输出不接 | tail / | head：让日志直接流出，长任务用 run_in_background，看结论读退出码与完整日志。'
fi

project_dir="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)}"
if [ -n "$project_dir" ] && [ -f "$project_dir/mise.toml" ] && grep -Eq '^\[tasks\."[A-Za-z0-9_-]+:test"\]' "$project_dir/mise.toml"; then
    assign='([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
    php='(([^[:space:];&|]*/)?php([[:space:]]+-d[[:space:]]*[^[:space:]]+)*[[:space:]]+)?'
    if printf '%s' "$cmd" | grep -Eq "(^|[;&(]|&&|\|\||\\\$\()[[:space:]]*${assign}${php}([^[:space:];&|]*/)?(vendor/bin/(pest|phpunit)|artisan[[:space:]]+test)([[:space:]\"')]|$)"; then
        block '本项目的测试走 mise run <应用>:test（任务负责准备测试库与隔离），不直接跑 pest、phpunit 或 artisan test。参数（文件、目录、--filter）照样传给 mise 任务。'
    fi
fi

if printf '%s' "$cmd" | grep -Eq "${lead}(env[[:space:]]+[^;&|]*)?(zsh|bash|sh)[[:space:]]+-[a-z]*c[[:space:]]"; then
    block 'Bash 工具本身就是加载了用户配置的 zsh，不再包一层 zsh -c / bash -c。多步逻辑或复杂引号写成 $CLAUDE_JOB_DIR/tmp 下的脚本文件再执行。'
fi

exit 0
