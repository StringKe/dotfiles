# ============================================================
# dotfiles 交互式 shell 配置（zimfw 本地模块）
#
# 性能策略：所有"启动重型 init"全部走 zsh-defer 异步加载，prompt 第一次
# 绘制不被阻塞。轻量定义（alias / function / zstyle）同步加载。
#
# 同步：alias / function / zstyle / kubectl 补全 alias
# 异步：mise / fzf / atuin / zoxide / starship / OrbStack / Bun 补全
#
# 首屏可见 prompt 时间从 ~5s 降到 < 0.5s；异步项在 prompt 出来后 1-2s 内陆续
# 就位，期间 CTRL-R / cd / 智能跳转等高级功能短暂不可用，命令补全 / 别名 /
# 高亮 / 自动建议立即可用。
# ============================================================

# ============================================================
# 路径变量准备（异步 init 用得到）
# ============================================================
typeset -gA _DOTFILES_TOOLS=(
    starship "starship"
    mise     "mise"
    atuin    "atuin"
    zoxide   "zoxide"
    fzf      "fzf"
)

# ============================================================
# fzf-tab 样式（同步，zstyle 是字符串赋值，无 fork 开销）
# ============================================================
zstyle ':fzf-tab:*' fzf-flags '--height=50%' '--layout=reverse' '--border=rounded' '--info=inline'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview \
    'eza --tree --level=2 --color=always $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:complete:(kubectl|k):*' fzf-flags \
    '--height=60%' '--layout=reverse' '--border=rounded' '--info=inline'

# ============================================================
# 别名（同步，alias 是文本替换，无 fork 开销）
# ============================================================

# eza - 现代 ls（--hyperlink 启用 OSC 8）
if command -v eza &>/dev/null; then
    alias ls='eza --hyperlink --icons --group-directories-first'
    alias ll='eza -la --hyperlink --icons --group-directories-first'
    alias lt='eza --tree --hyperlink --icons --group-directories-first'
fi

# fd - 文件搜索
if command -v fd &>/dev/null; then
    alias fd='fd --hyperlink auto'
fi

alias hh='atuin search -i'
alias lg='lazygit'

# kubectl 别名（同步；compdef k=kubectl 见下方异步段，需要 compinit 后才能跑）
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    command -v kubectx &>/dev/null && alias kctx='kubectx'
    command -v kubens  &>/dev/null && alias kns='kubens'

    alias kg='kubectl get'
    alias kgp='kubectl get pods -o wide'
    alias kgn='kubectl get nodes -o wide'
    alias kgs='kubectl get svc'
    alias kgd='kubectl get deploy'
    alias kging='kubectl get ingress'
    alias kgcm='kubectl get cm'
    alias kgsec='kubectl get secret'
    alias kgns='kubectl get ns'
    alias kgall='kubectl get all'
    alias kgpw='kubectl get pods -o wide -w'
    alias kgdw='kubectl get deploy -w'

    alias kd='kubectl describe'
    alias kdp='kubectl describe pod'
    alias kdn='kubectl describe node'

    alias kl='kubectl logs'
    alias klf='kubectl logs -f'
    alias klfa='kubectl logs -f --all-containers=true'

    alias ke='kubectl exec -it'

    alias kaf='kubectl apply -f'
    alias kdf='kubectl delete -f'

    alias kgctx='kubectl config get-contexts'
    alias kuse='kubectl config use-context'
    alias kbn='kubectl config set-context --current --namespace'
fi

# ============================================================
# 函数（同步，function 定义是文本，无 fork 开销）
# ============================================================

# rm -> trash 安全包装。真删除走 `command rm -rf xxx`
if command -v trash &>/dev/null; then
    function rm() {
        local paths=()
        local dashdash=false
        for arg in "$@"; do
            if $dashdash; then
                paths+=("$arg")
            elif [[ "$arg" == "--" ]]; then
                dashdash=true
            elif [[ "$arg" != -* ]]; then
                paths+=("$arg")
            fi
        done
        (( ${#paths[@]} )) && command trash "${paths[@]}"
    }
fi

# y - yazi 文件管理器（退出时切换到当前目录）
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    command rm -f -- "$tmp"
}

# ============================================================
# 敏感信息（gitignore 外的本地 secrets，同步加载，文件小）
# ============================================================
[[ -f ~/.zsh_secrets ]] && source ~/.zsh_secrets

# ============================================================
# 异步加载（zsh-defer）
# 顺序：在 prompt 第一次绘制之后按入队顺序执行。
# 顺序约束：mise 在前（其他工具可能是 mise 装的，PATH 要先就位），其余按用户使用频度排。
# ============================================================
if ! (( ${+functions[zsh-defer]} )); then
    # zsh-defer 未加载（zimfw 未跑 install / 临时降级）的兜底：全部同步加载
    function zsh-defer() { eval "$@"; }
fi

# OrbStack - 容器 / Linux VM 集成（docker 命令包装）
[[ -f ~/.orbstack/shell/init.zsh ]] && \
    zsh-defer source ~/.orbstack/shell/init.zsh

# mise - 运行时版本管理器（注册 chpwd hook + PATH 重写；首位异步）
command -v mise &>/dev/null && \
    zsh-defer eval "$(mise activate zsh)"

# fzf - 模糊搜索键绑定（CTRL-T / CTRL-R / ALT-C / ** glob 展开）
# CTRL-R 后由 atuin 接管，fzf 仍保留 CTRL-T / ALT-C
command -v fzf &>/dev/null && \
    zsh-defer source <(fzf --zsh)

# Atuin - shell 历史搜索（接管 CTRL-R，覆盖 fzf 的 CTRL-R 绑定）
command -v atuin &>/dev/null && \
    zsh-defer eval "$(atuin init zsh)"

# Zoxide - 智能目录跳转（接管 cd 命令）
command -v zoxide &>/dev/null && \
    zsh-defer eval "$(zoxide init zsh --cmd cd)"

# kubectl 补全 alias（compdef 需 compinit 完成；compinit 同步在 completion 模块跑过，这里安全）
command -v kubectl &>/dev/null && \
    zsh-defer compdef k=kubectl

# Bun 补全（依赖 $BUN_INSTALL，zshenv 已 export）
[[ -s "$BUN_INSTALL/_bun" ]] && \
    zsh-defer source "$BUN_INSTALL/_bun"

# Starship - prompt（必须最后异步，PROMPT 接管 precmd hook）
# 首次 prompt 用 zsh 默认 `%` 一闪而过，第二次起切到 starship；可接受。
command -v starship &>/dev/null && \
    zsh-defer eval "$(starship init zsh)"
