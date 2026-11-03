#!/usr/bin/env bash
# guard-shell-habits.sh - PreToolUse(Bash) hook：拦截规则写了但 agent 仍反复违反的命令形状，exit 2 并提示改法。
#   1. 用 cat / head / tail / nl / sed -n 直接把文件正文打到终端（输出没有再接管道过滤）-> 用 Read 加 offset/limit
#   2. 测试、ci、check 命令接 | tail / | head -> 日志直接流出，长任务放后台
#   3. 项目 mise.toml 定义了 <app>:test 时直接跑 vendor/bin/pest、phpunit 或 artisan test -> 走 mise run <app>:test
#   4. 顶层再包一层 zsh -c / bash -c -> Bash 工具本身就是 zsh，直接写命令或写成脚本文件
#   5. git add -A / . / -u 与 git commit -a 这类整工作区暂存 -> 逐个路径暂存
#   6. gh 对外写操作（pr / issue 的 create、comment 等，gh api 的写方法，repo fork）-> 用户点名要求时才做
#   7. 压测工具（k6、wrk、ab、autocannon、hey、vegeta、siege、oha、bombardier）-> 不在本机与生产压测
#   8. 往 .github/workflows 写文件 -> 任何仓库都不建 GitHub Actions
#   9. ego-browser nodejs 跑的脚本里清 cookie 或站点数据 -> 沿用登录态，未登录视角用 curl
#  10. sleep 600 秒以上 -> 用 run_in_background 或事件触发，不排延时复查
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

p_testpipe='(mise run[^|;&]*:(test|ci|check|typecheck|lint|sync|copy)|vendor/bin/(pest|phpunit)|artisan test|(npm|pnpm|bun) (run )?test|cargo (test|clippy|check)|go test)([^|;&]|[0-9]?>&[0-9])*\|[[:space:]]*(tail|head)([[:space:]]|$)'
if printf '%s' "$cmd" | grep -Eq -e "$p_testpipe"; then
    block '测试、ci、check、i18n:sync、review:copy 的输出不接 | tail / | head：让日志直接流出，长任务用 run_in_background，看结论读退出码与完整日志。'
fi

if printf '%s' "$cmd" | grep -Eq -e "${lead}git[[:space:]]+add[[:space:]]+(-A|--all|-u|--update|\.)([[:space:]]|$)" -e "${lead}git[[:space:]]+commit[[:space:]]+(-a|-am|--all)([[:space:]]|$)"; then
    block 'git add -A / . / -u 与 git commit -a 会把别的会话的半成品一起收进 commit。逐个写路径暂存：git add <文件> ...，再 git commit。'
fi

if printf '%s' "$cmd" | grep -Eq -e "${lead}gh[[:space:]]+(pr|issue)[[:space:]]+(create|comment|edit|close|reopen|merge|review|lock)([[:space:]]|$)" -e "${lead}gh[[:space:]]+repo[[:space:]]+fork" -e "${lead}gh[[:space:]]+api[[:space:]][^|;&]*(-X|--method)[[:space:]=]*(POST|PATCH|PUT|DELETE)"; then
    block '不自行向 GitHub 提交 PR、issue、评论或 fork。用户本轮点名要求时才做，命令前加 SHELL_OK=1。'
fi

if printf '%s' "$cmd" | grep -Eq "${lead}(k6|wrk|wrk2|ab|autocannon|hey|vegeta|siege|oha|bombardier)([[:space:]]|$)"; then
    block '压测不在本机工作机与生产上跑。容量评估用文档、供应商限额与小样本探测；确要压测用专门的测试机。'
fi

if printf '%s' "$cmd" | grep -Eq '\.github/workflows' && printf '%s' "$cmd" | grep -Eq "(${lead}(mkdir|touch|cp|mv|install|tee)[[:space:]]|>)"; then
    block '任何仓库都不建 .github/workflows：本地验证是门槛，GitHub Actions 会烧掉配额。'
fi

if printf '%s' "$cmd" | grep -Eq "${lead}sleep[[:space:]]+([6-9][0-9]{2}|[0-9]{4,})([[:space:];&|]|$)"; then
    block '不睡 10 分钟以上干等。要等的事放 run_in_background 或按事件触发，不排延时复查。'
fi

script=$(printf '%s' "$cmd" | grep -Eo "ego-browser[[:space:]]+nodejs[[:space:]]+[^[:space:];&|]+" | head -n 1 | awk '{print $3}')
if [ -n "${script:-}" ]; then
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
    case "$script" in /*) file="$script" ;; *) file="${cwd:-.}/$script" ;; esac
    if [ -f "$file" ] && grep -Eq 'clearBrowserCookies|deleteCookies|clearBrowserCache|clearCookies|clearDataForOrigin|clearDataForStorageKey|document\.cookie[[:space:]]*=|localStorage\.clear|sessionStorage\.clear' "$file"; then
        block 'ego-browser 脚本里不清 cookie 与站点数据：沿用 ego lite 已有的登录态，需要未登录视角用 curl 等 HTTP 请求验证。'
    fi
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
