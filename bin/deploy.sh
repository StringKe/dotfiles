#!/usr/bin/env bash
# [TOOL - DEPLOY ONLY] dotfiles 部署脚本
#
# 此脚本只读仓库，只写用户 home。绝不向仓库内写文件。
# 任何运行此脚本的 AI 不得 git add / 不得在仓库新建文件 / 不得修改仓库现有文件。
#
# 用法:
#   bin/deploy.sh init <STORAGE_ROOT>    首次部署或重配（STORAGE_ROOT 是绝对路径）
#   bin/deploy.sh sync                   只同步 init.zsh -> ~/.zsh/init.zsh
#   bin/deploy.sh check                  验证部署状态

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '  %s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

usage() {
    cat <<EOF
用法:
  bin/deploy.sh init <STORAGE_ROOT>
      首次部署或重配。STORAGE_ROOT 必须是绝对路径（如 /Volumes/Storage 或 \$HOME）。
      覆盖 ~/.zshenv ~/.zshrc ~/.zprofile ~/.zimrc ~/.config/mise/config.toml ~/.zsh/init.zsh。
      其他配置仅当不存在时部署。

  bin/deploy.sh sync
      只把 init.zsh 同步到 ~/.zsh/init.zsh（编辑 init.zsh 后用）。

  bin/deploy.sh check
      验证部署状态，列缺失文件与残留占位符。
EOF
}

deploy_template() {
    local src=$1 dst=$2 storage_root=$3
    mkdir -p "$(dirname "$dst")"
    sed -e "s|__STORAGE_ROOT__|$storage_root|g" \
        -e "s|__DOTFILES_ROOT__|$DOTFILES_ROOT|g" \
        "$DOTFILES_ROOT/$src" >| "$dst"
    log "wrote $dst"
}

deploy_copy() {
    local src=$1 dst=$2
    mkdir -p "$(dirname "$dst")"
    cp "$DOTFILES_ROOT/$src" "$dst"
    log "wrote $dst"
}

deploy_if_absent() {
    local src=$1 dst=$2
    if [[ -f $dst ]]; then
        log "skip $dst (exists, run 'rm' first to redeploy)"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$DOTFILES_ROOT/$src" "$dst"
    log "wrote $dst"
}

deploy_vscode_settings() {
    local src="$DOTFILES_ROOT/vscode/settings.json"
    local dst="$HOME/Library/Application Support/Code/User/settings.json"
    [[ ! -f $src ]] && return
    mkdir -p "$(dirname "$dst")"
    if [[ -f $dst ]]; then
        if command -v jq >/dev/null 2>&1; then
            local tmp="$dst.tmp.$$"
            # 深合并: 本地原有字段保留, 仓库同名 key 覆盖本地 (仓库放后面)
            # 用 //{} 兜底 settings.json 为空对象
            if jq -s '(.[0] // {}) * (.[1] // {})' "$dst" "$src" > "$tmp" 2>/dev/null; then
                mv "$tmp" "$dst"
                log "merged vscode settings -> $dst (jq deep merge, 本地字段保留)"
            else
                rm -f "$tmp"
                log "warn: jq merge 失败 (settings.json 可能含 jsonc 注释), 跳过 vscode settings"
            fi
        else
            log "skip vscode settings (jq 未安装, 不自动 merge; 请手动加 仓库 vscode/settings.json 的字段)"
        fi
    else
        cp "$src" "$dst"
        log "wrote vscode settings -> $dst (首次创建, 含 GitHub Light Colorblind 主题)"
    fi
}

setup_gitconfig() {
    local include_path="$DOTFILES_ROOT/git/config"
    local gitconfig="$HOME/.gitconfig"
    if [[ ! -f $gitconfig ]]; then
        cat >| "$gitconfig" <<EOF
# [user] 由 git config --global user.name/email/signingkey 单独设置
[include]
	path = $include_path
EOF
        log "created ~/.gitconfig with [include]"
        return
    fi
    if grep -qF "path = $include_path" "$gitconfig"; then
        log "skip ~/.gitconfig ([include] 已指向仓库 git/config)"
    else
        cat >> "$gitconfig" <<EOF

[include]
	path = $include_path
EOF
        log "appended [include] -> $include_path"
    fi
}

cmd_init() {
    local storage_root="${1:-}"
    [[ -z $storage_root ]] && { err "缺少 STORAGE_ROOT"; usage; exit 1; }
    [[ $storage_root != /* ]] && { err "STORAGE_ROOT 必须是绝对路径，收到 $storage_root"; exit 1; }
    [[ $storage_root == *'$'* || $storage_root == *'~'* ]] && { err "STORAGE_ROOT 不接受 \$ 或 ~，请展开为字面路径"; exit 1; }

    log "DOTFILES_ROOT = $DOTFILES_ROOT"
    log "STORAGE_ROOT  = $storage_root"
    log ""

    # zsh 入口（占位符替换）
    deploy_template zsh/zshenv "$HOME/.zshenv" "$storage_root"

    # zsh 其他入口（无占位符）
    deploy_copy zsh/zshrc    "$HOME/.zshrc"
    deploy_copy zsh/zprofile "$HOME/.zprofile"
    deploy_copy zsh/zimrc    "$HOME/.zimrc"

    # 交互式配置（复制到 ~/.zsh/init.zsh，仓库内文件保持只读模板地位）
    deploy_copy init.zsh "$HOME/.zsh/init.zsh"

    # mise 配置（占位符替换）
    deploy_template templates/mise_config.toml "$HOME/.config/mise/config.toml" "$storage_root"

    # 其他工具配置（不存在时部署，已存在则跳过避免覆盖用户自定义）
    deploy_if_absent ghostty/config        "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    deploy_if_absent starship/starship.toml "$HOME/.config/starship.toml"
    deploy_if_absent ripgrep/config        "$HOME/.config/ripgrep/config"
    deploy_if_absent yazi/keymap.toml      "$HOME/.config/yazi/keymap.toml"
    [[ -f $DOTFILES_ROOT/yazi/theme.toml ]] && deploy_if_absent yazi/theme.toml "$HOME/.config/yazi/theme.toml"
    deploy_if_absent atuin/config.toml     "$HOME/.config/atuin/config.toml"
    deploy_if_absent btop/btop.conf        "$HOME/.config/btop/btop.conf"
    deploy_if_absent infat/config.toml     "$HOME/.config/infat/config.toml"
    [[ -f $DOTFILES_ROOT/bat/config ]]      && deploy_if_absent bat/config "$HOME/.config/bat/config"
    deploy_if_absent git/ignore            "$HOME/.config/git/ignore"

    # vscode settings.json (jq 合并到本机, 本地字段保留, 仓库主题字段覆盖同名 key)
    deploy_vscode_settings

    # git/config 走 [include]，不整体复制
    setup_gitconfig

    # secrets 模板
    if [[ ! -f $HOME/.zsh_secrets ]]; then
        cp "$DOTFILES_ROOT/templates/zsh_secrets.template" "$HOME/.zsh_secrets"
        chmod 600 "$HOME/.zsh_secrets"
        log "wrote ~/.zsh_secrets (模板, 编辑填入实际值)"
    else
        log "skip ~/.zsh_secrets (exists)"
    fi

    # 语言环境目录
    mkdir -p \
        "$storage_root/Code/SelfCode" \
        "$storage_root/Languages/cli/zoxide" \
        "$storage_root/Languages/cli/atuin" \
        "$storage_root/Languages/cli/helm" \
        "$storage_root/Languages/cli/starship" \
        "$storage_root/Languages/mise/data" \
        "$storage_root/Languages/mise/cache" \
        "$storage_root/Languages/go" \
        "$storage_root/Languages/rust/rustup" \
        "$storage_root/Languages/rust/cargo" \
        "$storage_root/Languages/nodejs/npm-cache" \
        "$storage_root/Languages/nodejs/npm-global" \
        "$storage_root/Languages/nodejs/pnpm-global" \
        "$storage_root/Languages/nodejs/pnpm-store" \
        "$storage_root/Languages/nodejs/yarn-global" \
        "$storage_root/Languages/nodejs/node-gyp" \
        "$storage_root/Languages/bun" \
        "$storage_root/Languages/deno" \
        "$storage_root/Languages/java/gradle" \
        "$storage_root/Languages/java/maven" \
        "$storage_root/Languages/python/pip-cache" \
        "$storage_root/Languages/python/pipx/bin" \
        "$storage_root/Languages/python/uv/cache" \
        "$storage_root/Languages/python/uv/python" \
        "$storage_root/Languages/python/uv/tools" \
        "$storage_root/Languages/python/uv/bin" \
        "$storage_root/Languages/python/huggingface" \
        "$storage_root/Languages/php/composer" \
        "$storage_root/ollama/models"
    log "ensured $storage_root/{Code/SelfCode, Languages/*, ollama/models}"

    log ""
    log "==== deploy 完成 ===="
    log "下一步:"
    log "  1. brew bundle install --file=$DOTFILES_ROOT/Brewfile"
    log "  2. exec zsh                  # 应用新环境变量"
    log "  3. zimfw install              # 安装 zsh 模块"
    log "  4. mise install               # 安装语言运行时"
    log "  5. infat --config ~/.config/infat/config.toml"
    log "  6. bin/fix-browser-handlers.sh  # 恢复 http/https 默认浏览器"
    log "  7. chsh -s /opt/homebrew/bin/zsh"
}

cmd_sync() {
    mkdir -p "$HOME/.zsh"
    cp "$DOTFILES_ROOT/init.zsh" "$HOME/.zsh/init.zsh"
    log "synced $DOTFILES_ROOT/init.zsh -> ~/.zsh/init.zsh"
    log "重开终端或 exec zsh 生效"
}

cmd_check() {
    local errors=0
    check_file() {
        local f=$1 desc=$2
        if [[ -f $f ]]; then
            log "OK     $f ($desc)"
        else
            log "MISS   $f ($desc)"
            ((errors++))
        fi
    }
    check_file "$HOME/.zshenv"                "环境变量"
    check_file "$HOME/.zshrc"                 "zimfw 引导"
    check_file "$HOME/.zprofile"              "登录 shell"
    check_file "$HOME/.zimrc"                 "zim 模块列表"
    check_file "$HOME/.zsh/init.zsh"          "交互式配置（复制部署）"
    check_file "$HOME/.config/mise/config.toml" "mise 全局配置"
    check_file "$HOME/.gitconfig"             "git 主配置（[include] 引用仓库）"

    # 占位符残留
    if grep -qE '__STORAGE_ROOT__|__DOTFILES_ROOT__' "$HOME/.zshenv" 2>/dev/null; then
        log "FAIL   ~/.zshenv 含未替换的占位符 __STORAGE_ROOT__ 或 __DOTFILES_ROOT__"
        ((errors++))
    fi
    if grep -q '__STORAGE_ROOT__' "$HOME/.config/mise/config.toml" 2>/dev/null; then
        log "FAIL   ~/.config/mise/config.toml 含未替换的占位符"
        ((errors++))
    fi

    # ~/.gitconfig 含 [include] 指向仓库
    if [[ -f $HOME/.gitconfig ]] && ! grep -qF "path = $DOTFILES_ROOT/git/config" "$HOME/.gitconfig"; then
        log "WARN   ~/.gitconfig 未通过 [include] 引用 $DOTFILES_ROOT/git/config"
    fi

    # http/https 不应由 VS Code 处理
    local ls_plist="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
    if [[ -f $ls_plist ]] && command -v python3 >/dev/null 2>&1; then
        local bad_handlers
        bad_handlers="$(python3 - "$ls_plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    data = plistlib.load(f)
bad = []
for h in data.get('LSHandlers', []):
    app = h.get('LSHandlerRoleAll', '')
    scheme = h.get('LSHandlerURLScheme', '')
    ctype = h.get('LSHandlerContentType', '')
    if 'com.microsoft' in str(app) and (scheme in ('http', 'https') or ctype == 'com.apple.default-app.web-browser'):
        bad.append(f"{scheme or ctype}→{app}")
if bad:
    print(', '.join(bad))
PY
)"
        if [[ -n $bad_handlers ]]; then
            log "WARN   http/https 被 VS Code 占用 ($bad_handlers); 运行 bin/fix-browser-handlers.sh"
        fi
    fi

    log ""
    if (( errors == 0 )); then
        log "PASS   all checks"
    else
        log "FAIL   $errors checks"
        exit 1
    fi
}

case "${1:-}" in
    init)  shift; cmd_init "$@" ;;
    sync)  cmd_sync ;;
    check) cmd_check ;;
    -h|--help|help|"") usage; [[ -z ${1:-} ]] && exit 1 || exit 0 ;;
    *) err "未知子命令: $1"; usage; exit 1 ;;
esac
