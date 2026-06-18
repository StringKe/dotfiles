# ============================================================
# dotfiles 交互式 shell 配置
# 由 zimfw 作为本地模块加载（zmodule $DOTFILES_ROOT）
#
# [AI 规则] 交互式 shell 的全部配置在此文件，不要修改 ~/.zshrc。
#   环境变量 / PATH -> dotfiles/zsh/zshenv
#   登录 shell     -> dotfiles/zsh/zprofile
#   zim 插件列表   -> dotfiles/zsh/zimrc
# ============================================================

# ============================================================
# OrbStack - 容器 / Linux VM 集成
# ============================================================
if [[ -f ~/.orbstack/shell/init.zsh ]]; then
    source ~/.orbstack/shell/init.zsh 2>/dev/null || true
fi

# ============================================================
# mise - 运行时版本管理器（全局默认）
# ============================================================
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# ============================================================
# fzf - 模糊搜索（键绑定：CTRL-T / CTRL-R / ALT-C）
# 注意：fzf-tab（Tab 补全 UI）由 zimrc 中的 zmodule Aloxaf/fzf-tab 加载，
#   此处 fzf --zsh 提供的是额外的键绑定和 ** glob 展开，两者互补不冲突。
# ============================================================
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# ============================================================
# Atuin - 历史搜索（替换 CTRL-R）
# ============================================================
if command -v atuin &>/dev/null; then
    eval "$(atuin init zsh)"
fi

# ============================================================
# Zoxide - 智能目录跳转（`cd` 替换为 zoxide）
# ============================================================
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# ============================================================
# fzf-tab 样式配置
# （zstyle 在模块加载后设置同样生效，fzf-tab 调用时读取）
# ============================================================
zstyle ':fzf-tab:*' fzf-flags '--height=50%' '--layout=reverse' '--border=rounded' '--info=inline'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview \
    'eza --tree --level=2 --color=always $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:complete:(kubectl|k):*' fzf-flags \
    '--height=60%' '--layout=reverse' '--border=rounded' '--info=inline'

# ============================================================
# kubectl - 补全 + 别名
# ============================================================
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    compdef k=kubectl

    if command -v kubectx &>/dev/null; then alias kctx='kubectx'; fi
    if command -v kubens  &>/dev/null; then alias kns='kubens';   fi

    # --- get ---
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

    # --- describe ---
    alias kd='kubectl describe'
    alias kdp='kubectl describe pod'
    alias kdn='kubectl describe node'

    # --- logs ---
    alias kl='kubectl logs'
    alias klf='kubectl logs -f'
    alias klfa='kubectl logs -f --all-containers=true'

    # --- exec / run ---
    alias ke='kubectl exec -it'

    # --- apply / delete ---
    alias kaf='kubectl apply -f'
    alias kdf='kubectl delete -f'

    # --- context / namespace ---
    alias kgctx='kubectl config get-contexts'
    alias kuse='kubectl config use-context'
    alias kbn='kubectl config set-context --current --namespace'
fi

# ============================================================
# 别名
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

# ============================================================
# rm -> trash 安全包装
# 真正删除: command rm -rf xxx
# ============================================================
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

# ============================================================
# y - yazi 文件管理器（退出时切换到当前目录）
# ============================================================
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    command rm -f -- "$tmp"
}

# ============================================================
# 加载敏感信息（~/.zsh_secrets 不纳入版本控制）
# ============================================================
if [[ -f ~/.zsh_secrets ]]; then
    source ~/.zsh_secrets
fi

# ============================================================
# Bun - 补全脚本
# ============================================================
if [[ -s "$BUN_INSTALL/_bun" ]]; then
    source "$BUN_INSTALL/_bun"
fi

# ============================================================
# Starship - 提示符（最后加载，接管 precmd）
# ============================================================
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
