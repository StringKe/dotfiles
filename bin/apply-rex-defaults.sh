#!/usr/bin/env bash
# [TOOL] Rex 外观与终端设置
#
# 把 rex/workspace.defaults 写进 defaults 域 com.superlogical.rex 的 Workspace.* 键。
# 只写用户 home，绝不修改仓库。Rex 运行时不读这些改动，重启 App 才生效；
# Rex Server 是独立进程，重启 App 不中断会话。
#
# 用法:
#   bin/apply-rex-defaults.sh

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOMAIN=com.superlogical.rex

while IFS=$'\t' read -r key type value; do
    [[ -z $key || $key == \#* ]] && continue
    defaults write "$DOMAIN" "Workspace.$key" "-$type" "$value"
    printf '  Workspace.%s = %s\n' "$key" "$value"
done < "$DOTFILES_ROOT/rex/workspace.defaults"

printf '  重启 Rex App 生效\n'
