#!/usr/bin/env bash
# [TOOL] AI CLI 安装脚本
#
# claude-code / codex / grok-build / opencode 走各自官方 curl 脚本安装
# （自带后台自更新，不走 brew，无需 brew upgrade）。
# PATH 由 zshenv 管理；安装器禁止改 ~/.zshrc。
# 此脚本只写用户 home，绝不修改仓库。
#
# 用法:
#   bin/install-ai-cli.sh              安装/更新全部
#   bin/install-ai-cli.sh claude-code  仅 claude-code
#   bin/install-ai-cli.sh codex        仅 codex
#   bin/install-ai-cli.sh grok-build   仅 grok-build
#   bin/install-ai-cli.sh opencode     仅 opencode
#
# 重复运行 = 更新到最新版（官方脚本本身是幂等的）。

set -euo pipefail

log() { printf '  %s\n' "$*"; }

install_claude_code() {
    log "installing/updating claude-code ..."
    curl -fsSL https://claude.ai/install.sh | bash
}

install_codex() {
    log "installing/updating codex ..."
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
}

install_grok_build() {
    log "installing/updating grok-build ..."
    curl -fsSL https://x.ai/cli/install.sh | bash
}

install_opencode() {
    log "installing/updating opencode ..."
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
}

case "${1:-all}" in
    claude-code) install_claude_code ;;
    codex)       install_codex ;;
    grok-build)  install_grok_build ;;
    opencode)    install_opencode ;;
    all|"")
        install_claude_code
        install_codex
        install_grok_build
        install_opencode
        ;;
    -h|--help|help) sed -n '3,16p' "$0" ;;
    *) printf 'ERROR: 未知子命令 %s\n' "$1" >&2; exit 1 ;;
esac
