# ============================================================
# zsh profile 调试模块
#
# 用法（临时，用完关闭）：
#   1. 开新终端前 export ZSH_PROFILE=1
#      - ghostty: 临时在 .zshenv 加一行 `export ZSH_PROFILE=1`
#      - 或命令行：`ZSH_PROFILE=1 zsh -l`
#   2. 操作终端（cd / clear / 跑命令），观察 stderr 的 [prof*] 行
#   3. 关闭：unset ZSH_PROFILE，或删 .zshenv 那行
#
# 输出前缀含义：
#   [prof]      启动各段累计耗时（init.zsh 起算）
#   [prof-cd]   每次 cd 总耗时 + 每个 chpwd hook 单独耗时
#   [prof-pre]  每次命令完成后 precmd 链路总耗时 + 每个 precmd hook 单独耗时
#   [prof-exec] 每次命令执行前 preexec 链路总耗时（一般很快，除非有特殊 hook）
#
# 此文件仅在 ZSH_PROFILE=1 时被 init.zsh source；无 perf 副作用。
# ============================================================

zmodload zsh/datetime

# 启动时间锚点（init.zsh 加载时第一次定义）
typeset -gF _PROF_T0=${_PROF_T0:-$EPOCHREALTIME}
typeset -gF _PROF_LAST=$_PROF_T0

# _prof "label"
#   累计 + 区间耗时（区间 = 距上次 _prof 调用）
_prof() {
    local now=$EPOCHREALTIME
    local total_ms=$(( (now - _PROF_T0) * 1000 ))
    local delta_ms=$(( (now - _PROF_LAST) * 1000 ))
    printf '[prof] +%7.1fms (Δ%6.1fms)  %s\n' $total_ms $delta_ms "$1" >&2
    _PROF_LAST=$now
}

# ============================================================
# Hook timing：wrap chpwd / precmd / preexec 链上每个函数，
# 输出单独耗时，便于定位"哪个 hook 慢"
# ============================================================

# _prof_wrap_hooks <hook-array-name> <prefix>
#   把 chpwd_functions / precmd_functions / preexec_functions 数组中的每个
#   函数包装成 timing 版本，超过 1ms 就打印。
_prof_wrap_hooks() {
    local arr=$1 prefix=$2
    local -a orig wrapped
    orig=(${(P)arr})
    for fn in $orig; do
        # 跳过已包装的（防止重复 source 时叠加）
        [[ $fn == _prof_wrapped_* ]] && { wrapped+=($fn); continue }
        local wrapper="_prof_wrapped_${prefix}_${fn}"
        # 动态定义 wrapper 函数：调原函数 + 计时
        functions[$wrapper]="
            local _t0=\$EPOCHREALTIME
            $fn \"\$@\"
            local _rc=\$?
            local _el=\$(( (\$EPOCHREALTIME - \$_t0) * 1000 ))
            (( \$_el >= 1 )) && printf '[prof-%s] %7.1fms  %s\\n' '$prefix' \$_el '$fn' >&2
            return \$_rc
        "
        wrapped+=($wrapper)
    done
    : ${(AP)arr::=$wrapped}
}

# 链路总耗时（区分 cd 引发的 precmd 和 normal 命令后的 precmd）
_prof_chpwd_total_start() { typeset -gF _PROF_CD_T0=$EPOCHREALTIME; }
_prof_chpwd_total_end() {
    [[ -z $_PROF_CD_T0 ]] && return
    local el=$(( (EPOCHREALTIME - _PROF_CD_T0) * 1000 ))
    printf '[prof-cd] TOTAL %7.1fms  -> %s\n' $el "$PWD" >&2
    unset _PROF_CD_T0
}

_prof_precmd_total_start() { typeset -gF _PROF_PRECMD_T0=$EPOCHREALTIME; }
_prof_precmd_total_end() {
    [[ -z $_PROF_PRECMD_T0 ]] && return
    local el=$(( (EPOCHREALTIME - _PROF_PRECMD_T0) * 1000 ))
    printf '[prof-pre] TOTAL %7.1fms\n' $el >&2
    unset _PROF_PRECMD_T0
}

_prof_preexec_total() {
    local el=$(( (EPOCHREALTIME - _PROF_PREEXEC_T0) * 1000 ))
    (( $el >= 1 )) && printf '[prof-exec] TOTAL %7.1fms  cmd: %s\n' $el "$1" >&2
}
_prof_preexec_start() { typeset -gF _PROF_PREEXEC_T0=$EPOCHREALTIME; }

# 在 prompt-ready 后一次性安装 wrapper（确保所有插件已注册完毕）
_prof_install_wrappers() {
    # 只装一次，装完把自己从 precmd 摘掉
    autoload -Uz add-zsh-hook

    # 包装现有 hook 函数
    _prof_wrap_hooks chpwd_functions cd
    _prof_wrap_hooks precmd_functions pre
    _prof_wrap_hooks preexec_functions exec

    # 在链路头/尾插入 total timer
    # chpwd: head=start, precmd 的最后跑 total_end（因为 chpwd 跑完才进 precmd）
    chpwd_functions=(_prof_chpwd_total_start $chpwd_functions)
    precmd_functions=($precmd_functions _prof_chpwd_total_end)

    # precmd: head=start, tail=end
    precmd_functions=(_prof_precmd_total_start $precmd_functions _prof_precmd_total_end)

    # preexec: head=start, tail=total
    preexec_functions=(_prof_preexec_start $preexec_functions _prof_preexec_total)

    add-zsh-hook -d precmd _prof_install_wrappers
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _prof_install_wrappers

_prof "profile.zsh loaded (wrappers will install on first precmd)"
