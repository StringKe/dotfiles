#!/usr/bin/env bash
# [TOOL] 主题文件安装脚本
#
# 把仓库 btop/themes/ 下的主题复制到用户 ~/.config/btop/themes/。
# 主题文件存仓库内，不再走网络下载（避免源不可达）。
#
# 此脚本只写用户 home，绝不修改仓库。
#
# 用法:
#   bin/install-themes.sh          安装所有主题文件
#   bin/install-themes.sh btop     仅安装 btop 主题
#
# 工具内置 GitHub Light Colorblind / 跟终端配色（无需下载）:
#   - ghostty   (theme = GitHub Light Colorblind, 内置)
#   - starship  (palette 在 starship.toml 内手写)
#   - fzf       (FZF_DEFAULT_OPTS 在 init.zsh 内手写)
#   - bat       (--theme="ansi"，跟随终端 ANSI 配色)
#   - yazi      (yazi/theme.toml 手写，由 deploy.sh 复制)
#   - atuin     (fallback 默认配色，跟随终端 ANSI)
#   - vscode    (GitHub.github-vscode-theme 扩展)

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log() { printf '  %s\n' "$*"; }

install_btop() {
    local src_dir="$DOTFILES_ROOT/btop/themes"
    local dst_dir="$HOME/.config/btop/themes"
    if [[ ! -d $src_dir ]]; then
        log "skip btop (no $src_dir)"
        return
    fi
    mkdir -p "$dst_dir"
    local count=0
    for f in "$src_dir"/*.theme; do
        [[ -e $f ]] || continue
        cp "$f" "$dst_dir/$(basename "$f")"
        log "installed btop -> $dst_dir/$(basename "$f")"
        count=$((count + 1))
    done
    if (( count == 0 )); then
        log "no .theme files in $src_dir"
    fi
}

case "${1:-all}" in
    btop)      install_btop ;;
    all|"")    install_btop ;;
    -h|--help|help) sed -n '3,21p' "$0" ;;
    *) printf 'ERROR: 未知子命令 %s\n' "$1" >&2; exit 1 ;;
esac
