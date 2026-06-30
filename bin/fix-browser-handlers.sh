#!/usr/bin/env bash
# [TOOL - DEPLOY ONLY] 恢复 http/https 默认浏览器
#
# infat 只应关联代码文件与 vscode:// scheme。若 http/https 被 VS Code 接管，
# 运行本脚本将三者重置为系统浏览器：
#   - http / https URL scheme
#   - com.apple.default-app.web-browser（系统设置里的默认浏览器）
#
# 用法:
#   bin/fix-browser-handlers.sh          # 自动选浏览器
#   bin/fix-browser-handlers.sh Chrome   # 指定应用名（infat 格式，大小写敏感）

set -euo pipefail

log() { printf '  %s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

usage() {
    cat <<EOF
用法:
  bin/fix-browser-handlers.sh [APP_NAME]

  无参数时按优先级自动选择: Google Chrome → Safari
  APP_NAME 传给 infat set，须与 /Applications 内应用显示名一致。

  典型场景: 跑完 infat 后立即执行，防止 http/https 被 VS Code 占用。
EOF
}

pick_browser() {
    local -a candidates=(
        "Google Chrome"
        "Safari"
        "Arc"
        "Firefox"
        "Microsoft Edge"
        "Brave Browser"
    )
    local name
    for name in "${candidates[@]}"; do
        if [[ -d "/Applications/${name}.app" ]]; then
            printf '%s' "$name"
            return 0
        fi
    done
    return 1
}

reset_handlers() {
    local browser=$1
    log "重置默认浏览器 → $browser"
    infat set "$browser" --scheme http
    infat set "$browser" --scheme https
    infat set "$browser" --type com.apple.default-app.web-browser
    log "完成: http / https / 默认浏览器 → $browser"
}

main() {
    local browser="${1:-}"

    if ! command -v infat >/dev/null 2>&1; then
        err "infat 未安装 (brew install infat)"
        exit 1
    fi

    if [[ -z $browser ]]; then
        browser="$(pick_browser)" || {
            err "未找到可用浏览器 (/Applications 下无 Chrome/Safari 等)"
            exit 1
        }
    elif [[ ! -d "/Applications/${browser}.app" ]]; then
        err "未找到 /Applications/${browser}.app"
        exit 1
    fi

    reset_handlers "$browser"
}

case "${1:-}" in
    -h|--help|help) usage ;;
    "") main ;;
    *) main "$1" ;;
esac