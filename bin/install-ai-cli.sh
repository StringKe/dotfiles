#!/usr/bin/env bash
# [TOOL] AI CLI 安装脚本
#
# claude-code / grok-build / opencode / magpie 走各自官方 curl 脚本安装
# （自带后台自更新，不走 brew，无需 brew upgrade）。
# magpie 是本机模型网关（127.0.0.1:3425），用 magpie <agent> <provider/model> 写入各 agent 配置。
# PATH 由 zshenv 管理；安装器禁止改 ~/.zshrc。
# 此脚本只写用户 home，绝不修改仓库。
#
# 用法:
#   bin/install-ai-cli.sh              安装/更新全部
#   bin/install-ai-cli.sh claude-code  仅 claude-code
#   bin/install-ai-cli.sh grok-build   仅 grok-build
#   bin/install-ai-cli.sh opencode     仅 opencode
#   bin/install-ai-cli.sh magpie       仅 magpie（/Applications/magpie.app + ~/.local/bin/magpie）
#
# 重复运行 = 更新到最新版（官方脚本本身是幂等的）。

set -euo pipefail

log() { printf '  %s\n' "$*"; }

install_claude_code() {
    log "installing/updating claude-code ..."
    curl -fsSL https://claude.ai/install.sh | bash
}

install_grok_build() {
    log "installing/updating grok-build ..."
    curl -fsSL https://x.ai/cli/install.sh | bash
}

install_opencode() {
    log "installing/updating opencode ..."
    curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
}

install_magpie() {
    log "installing/updating magpie ..."
    curl -fsSL https://usemagpie.ai/install.sh | sh
}

case "${1:-all}" in
    claude-code) install_claude_code ;;
    grok-build)  install_grok_build ;;
    opencode)    install_opencode ;;
    magpie)      install_magpie ;;
    all|"")
        install_magpie
        install_claude_code
        install_grok_build
        install_opencode
        ;;
    -h|--help|help) sed -n '3,17p' "$0" ;;
    *) printf 'ERROR: 未知子命令 %s\n' "$1" >&2; exit 1 ;;
esac
