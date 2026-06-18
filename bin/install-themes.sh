#!/usr/bin/env bash
# [TOOL] 主题文件安装脚本
#
# 下载并安装 Catppuccin Latte 主题文件到对应工具目录。
# 大多数工具的配置文件已写死引用主题名，但实际主题文件需单独下载。
#
# 此脚本只写用户 home / 第三方主题目录，绝不修改仓库。
#
# 用法:
#   bin/install-themes.sh         安装所有主题文件
#   bin/install-themes.sh btop    仅安装 btop 主题
#   bin/install-themes.sh yazi    yazi 主题已在仓库 yazi/theme.toml 内
#   bin/install-themes.sh atuin   仅安装 atuin 主题
#
# 工具自带 Catppuccin Latte 内置（无需下载）:
#   - ghostty (theme=catppuccin-latte)
#   - bat (theme="Catppuccin Latte")
#   - starship (palette 在 starship.toml 内定义)
#   - fzf (FZF_DEFAULT_OPTS 在 init.zsh 内)
#   - vscode (Catppuccin.catppuccin-vsc 扩展)

set -euo pipefail

log() { printf '  %s\n' "$*"; }

install_btop() {
    local target="$HOME/.config/btop/themes/catppuccin_latte.theme"
    if [[ -f $target ]]; then
        log "skip btop (exists: $target)"
        return
    fi
    mkdir -p "$(dirname "$target")"
    curl -fsSL https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_latte.theme -o "$target"
    log "installed btop -> $target"
}

install_atuin() {
    # atuin 18.x 自定义主题文件在 ~/.config/atuin/themes/
    local target="$HOME/.config/atuin/themes/catppuccin-latte.toml"
    if [[ -f $target ]]; then
        log "skip atuin (exists: $target)"
        return
    fi
    mkdir -p "$(dirname "$target")"
    if curl -fsSL -o "$target" \
        "https://raw.githubusercontent.com/catppuccin/atuin/main/themes/catppuccin-latte.toml" 2>/dev/null; then
        log "installed atuin -> $target"
    else
        log "warn: catppuccin/atuin 仓库主题文件不可达；atuin 会 fallback 到默认配色"
        rm -f "$target"
    fi
}

install_yazi() {
    log "yazi theme 已写死在仓库 yazi/theme.toml，bin/deploy.sh init 部署时一并复制"
}

case "${1:-all}" in
    btop)  install_btop ;;
    atuin) install_atuin ;;
    yazi)  install_yazi ;;
    all|"")
        install_btop
        install_atuin
        install_yazi
        ;;
    -h|--help|help)
        sed -n '3,21p' "$0"
        ;;
    *)
        printf 'ERROR: 未知子命令 %s\n' "$1" >&2
        exit 1
        ;;
esac
