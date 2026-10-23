#!/bin/bash
# Claude Code statusLine，单行：
#   目录 | git 分支 状态 | wt worktree | PR #号 状态 | 模型 effort | ctx 42% | $费用 | +增 -删 | cache 91% | limit 5h 24% 7d 81% | 会话名
# 颜色用 ANSI 命名色，与 starship 默认样式一致，由终端主题渲染。
# 只起一个 jq 和一个 git 进程；仓库根目录用纯 bash 向上查找。

IFS= read -r -d '' input || true

fields=$(jq -r '
    def s: if . == null then "" else tostring end;
    def r: if . == null then "" else (round | tostring) end;
    [
        (.model.display_name | s),
        (.effort.level | s),
        ((.workspace.current_dir // .cwd) | s),
        (.context_window.used_percentage | r),
        (.cost.total_cost_usd | s),
        (.cost.total_lines_added | s),
        (.cost.total_lines_removed | s),
        (.prompt_cache.hit_ratio | if . == null then "" else (. * 100 | round | tostring) end),
        (.prompt_cache.warm | s),
        (.rate_limits.five_hour.used_percentage | r),
        (.rate_limits.seven_day.used_percentage | r),
        ((.worktree.name // .workspace.git_worktree) | s),
        (.pr.number | s),
        (.pr.review_state | s),
        (.session_name | s),
        (.fast_mode | s)
    ] | join("\u001f")
' <<<"$input")

IFS=$'\x1f' read -r model effort cwd ctx_pct cost lines_add lines_del cache_pct cache_warm rl_5h rl_7d worktree pr_num pr_state session_name fast_mode <<<"$fields"

c_reset=$'\033[0m'
c_dim=$'\033[2m'
c_red=$'\033[31m'
c_green=$'\033[32m'
c_yellow=$'\033[33m'
c_magenta=$'\033[35m'
c_cyan=$'\033[36m'
c_bold_blue=$'\033[1;34m'
c_bold_magenta=$'\033[1;35m'
c_bold_cyan=$'\033[1;36m'

# 百分比按阈值着色：< 50 绿，< 80 黄，其余红
pct_color() {
    if (( $1 < 50 )); then printf '%s' "$c_green"
    elif (( $1 < 80 )); then printf '%s' "$c_yellow"
    else printf '%s' "$c_red"
    fi
}

parts=()

repo_root=""
if [[ -n "$cwd" ]]; then
    d="$cwd"
    while [[ -n "$d" && "$d" != "/" ]]; do
        if [[ -e "$d/.git" ]]; then repo_root="$d"; break; fi
        d="${d%/*}"
    done
fi

# 与 starship directory 一致：仓库内从仓库根开始显示，最多保留最后 3 级
if [[ -n "$cwd" ]]; then
    if [[ -n "$repo_root" ]]; then
        dir="${repo_root##*/}${cwd#"$repo_root"}"
    else
        tilde='~'
        dir="${cwd/#"$HOME"/$tilde}"
    fi
    IFS='/' read -r -a dir_segs <<<"$dir"
    n=${#dir_segs[@]}
    (( n > 3 )) && dir="${dir_segs[n-3]}/${dir_segs[n-2]}/${dir_segs[n-1]}"
    parts+=("${c_bold_cyan}${dir}${c_reset}")
fi

if [[ -n "$repo_root" ]]; then
    git_status=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        branch="" oid="" ahead=0 behind=0 staged=0 modified=0 untracked=0 conflicted=0
        while IFS= read -r line; do
            case "$line" in
                "# branch.head "*) branch="${line#"# branch.head "}" ;;
                "# branch.oid "*) oid="${line#"# branch.oid "}" ;;
                "# branch.ab "*)
                    ab="${line#"# branch.ab "}"
                    ahead="${ab%% *}"; ahead="${ahead#+}"
                    behind="${ab##* }"; behind="${behind#-}"
                    ;;
                "1 "* | "2 "*)
                    xy="${line:2:2}"
                    [[ "${xy:0:1}" != "." ]] && staged=$((staged + 1))
                    [[ "${xy:1:1}" != "." ]] && modified=$((modified + 1))
                    ;;
                "u "*) conflicted=$((conflicted + 1)) ;;
                "? "*) untracked=$((untracked + 1)) ;;
            esac
        done <<<"$git_status"
        [[ "$branch" == "(detached)" ]] && branch="${oid:0:7}"

        state=""
        (( conflicted > 0 )) && state+=" ${c_red}${conflicted} conflict${c_reset}"
        (( ahead > 0 )) && state+=" ${c_yellow}${ahead} ahead${c_reset}"
        (( behind > 0 )) && state+=" ${c_yellow}${behind} behind${c_reset}"
        (( staged > 0 )) && state+=" ${c_green}${staged} staged${c_reset}"
        (( modified > 0 )) && state+=" ${c_red}${modified} changed${c_reset}"
        (( untracked > 0 )) && state+=" ${c_dim}${untracked} new${c_reset}"

        [[ -n "$branch" ]] && parts+=("${c_dim}git${c_reset} ${c_bold_magenta}${branch}${c_reset}${state}")
    fi
fi

[[ -n "$worktree" ]] && parts+=("${c_dim}wt${c_reset} ${c_magenta}${worktree}${c_reset}")

if [[ -n "$pr_num" ]]; then
    case "$pr_state" in
        approved) pr_color="$c_green" ;;
        changes_requested) pr_color="$c_red" ;;
        *) pr_color="$c_yellow" ;;
    esac
    pr_display="${pr_color}PR #${pr_num}${c_reset}"
    [[ -n "$pr_state" ]] && pr_display+=" ${c_dim}${pr_state}${c_reset}"
    parts+=("$pr_display")
fi

model_display="${c_bold_blue}${model:-unknown}${c_reset}"
[[ -n "$effort" ]] && model_display+=" ${c_magenta}${effort}${c_reset}"
[[ "$fast_mode" == "true" ]] && model_display+=" ${c_yellow}fast${c_reset}"
parts+=("$model_display")

[[ -n "$ctx_pct" ]] && parts+=("${c_dim}ctx${c_reset} $(pct_color "$ctx_pct")${ctx_pct}%${c_reset}")

[[ -n "$cost" ]] && parts+=("${c_yellow}$(printf '$%.2f' "$cost")${c_reset}")

if [[ "${lines_add:-0}" != "0" || "${lines_del:-0}" != "0" ]]; then
    parts+=("${c_green}+${lines_add:-0}${c_reset} ${c_red}-${lines_del:-0}${c_reset}")
fi

if [[ -n "$cache_pct" ]]; then
    if [[ "$cache_warm" == "true" ]]; then
        parts+=("${c_dim}cache${c_reset} ${c_cyan}${cache_pct}%${c_reset}")
    else
        parts+=("${c_dim}cache ${cache_pct}% cold${c_reset}")
    fi
fi

limits=""
[[ -n "$rl_5h" ]] && limits+=" ${c_dim}5h${c_reset} $(pct_color "$rl_5h")${rl_5h}%${c_reset}"
[[ -n "$rl_7d" ]] && limits+=" ${c_dim}7d${c_reset} $(pct_color "$rl_7d")${rl_7d}%${c_reset}"
[[ -n "$limits" ]] && parts+=("${c_dim}limit${c_reset}${limits}")

if [[ -n "$session_name" ]]; then
    (( ${#session_name} > 30 )) && session_name="${session_name:0:29}~"
    parts+=("${c_dim}${session_name}${c_reset}")
fi

sep=" ${c_dim}|${c_reset} "
out=""
for p in "${parts[@]}"; do
    if [[ -z "$out" ]]; then out="$p"; else out="${out}${sep}${p}"; fi
done
printf '%s' "$out"
