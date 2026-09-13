#!/usr/bin/env bash
# [TOOL] 应用 macOS 文件关联
#
# infat 能设的走 ~/.config/infat/config.toml。
# 被 PhpStorm / Ghostty / Xcode / Cursor 抢注的扩展 infat 会编成 dyn.* UTI，Tahoe 报 error -50，改用 duti。
# .jsx / .scss / .vue 没有系统 UTI，写入 LSHandlerContentTag。
# .ts 的系统 UTI 是 public.mpeg-2-transport-stream（MPEG 传输流），要让 TypeScript 进 VS Code 只能把这个 UTI 也绑过去；真 MPEG .ts 视频也会进 VS Code。
#
# 只写用户 LaunchServices，不改仓库。PhpStorm / Toolbox 更新后再跑一次。
#
# 用法:
#   bin/apply-file-associations.sh

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="com.microsoft.VSCode"
INFAT_CONFIG="$HOME/.config/infat/config.toml"
LS_DOMAIN="com.apple.LaunchServices/com.apple.launchservices.secure"

log() { printf '  %s\n' "$*"; }

if [[ ! -f $INFAT_CONFIG ]]; then
    mkdir -p "$(dirname "$INFAT_CONFIG")"
    cp "$DOTFILES_ROOT/infat/config.toml" "$INFAT_CONFIG"
    log "wrote $INFAT_CONFIG"
fi

if command -v infat >/dev/null; then
    infat --robust --config "$INFAT_CONFIG"
else
    log "skip infat (not in PATH)"
fi

if command -v duti >/dev/null; then
    for ext in sh bash zsh plist php phtml js mjs css py rb toml tsx; do
        if duti -s "$BUNDLE_ID" ".$ext" all 2>/dev/null; then
            log "duti .$ext"
        else
            log "duti .$ext failed"
        fi
    done
    for uti in \
        public.php-script \
        com.netscape.javascript-source \
        public.css \
        public.python-script \
        public.ruby-script \
        public.toml \
        public.zsh-script \
        public.shell-script \
        public.bash-script \
        com.apple.property-list \
        com.microsoft.typescript \
        public.mpeg-2-transport-stream
    do
        if duti -s "$BUNDLE_ID" "$uti" all 2>/dev/null; then
            log "duti $uti"
        else
            log "duti $uti failed"
        fi
    done
else
    log "skip duti (not in PATH)"
fi

ensure_ext_tag() {
    local ext=$1
    if defaults read "$LS_DOMAIN" LSHandlers 2>/dev/null | grep -F "LSHandlerContentTag = ${ext};" >/dev/null; then
        log "skip tag .$ext (exists)"
        return
    fi
    defaults write "$LS_DOMAIN" LSHandlers -array-add "{
        LSHandlerContentTag = ${ext};
        LSHandlerContentTagClass = \"public.filename-extension\";
        LSHandlerRoleAll = \"${BUNDLE_ID}\";
        LSHandlerPreferredVersions = { LSHandlerRoleAll = \"-\"; };
    }"
    log "added tag .$ext"
}

ensure_ext_tag jsx
ensure_ext_tag scss
ensure_ext_tag vue

# ContentTag / duti 写入后 lsd 仍可能用旧缓存
killall lsd 2>/dev/null || true
log "restarted lsd"
