#!/usr/bin/env bash
# [TOOL] 安装与配置向导：选择模块，按顺序安装软件、部署配置。
#
# 只写用户 home（以及 setup-ai 安装的仓库 pre-commit hook），不改仓库文件。
# 选择保存在 ~/.config/dotfiles/modules，重跑时作为默认值；重跑即更新。
#
# 用法:
#   bin/setup.sh                         交互选择模块
#   bin/setup.sh --modules core,dev,ai   指定模块（core 总会包含）
#   bin/setup.sh --all                   全部模块
#   bin/setup.sh --storage-root PATH     首次部署或重配存储根（否则沿用已部署值，首次默认 $HOME）
#   bin/setup.sh --dry-run               只打印要执行的步骤
#   bin/setup.sh --list                  列出模块

set -euo pipefail
trap 'printf "ERROR: 第 %s 行的步骤失败，修复后重跑 bin/setup.sh（已完成的步骤会跳过或幂等执行）\n" "$LINENO" >&2' ERR

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="$HOME/.config/dotfiles/modules"

# key|说明|默认选中
MODULES=(
    "core|zsh 配置与日常 CLI（必选）：zsh 入口、工具配置、brew/core、zim 模块、mise 运行时|1"
    "dev|开发辅助：gcc / llvm / linter / caddy / mysql-client / duckdb / sops|1"
    "cloud|云与 Kubernetes：aws / aliyun / gcloud / kubectl / helm / opentofu / cloudflared|0"
    "mobile|移动端构建：cocoapods / flutter / Android SDK 工具|0"
    "jvm|JVM：gradle（JDK 由 mise 提供）|0"
    "php|PHP 与 composer|0"
    "media|多媒体：ffmpeg / imagemagick / poppler / tesseract|0"
    "reverse|逆向：jadx|0"
    "apps|桌面应用：VS Code / JetBrains Toolbox / OrbStack / 1Password / Chrome / Telegram 等|1"
    "xcode|从 App Store 安装 Xcode|0"
    "ai|AI：claude-code / opencode 与提示词、skills、hooks、插件、MCP|1"
    "rex|Rex 终端外观设置|1"
    "fileassoc|文件关联：代码文件默认用 VS Code 打开|1"
    "git|git 身份与签名（未设置时询问）|1"
    "shell|把默认 shell 换成 Homebrew zsh|1"
)

DRY_RUN=false
STORAGE_ROOT=""
SELECTED=""

log()  { printf '  %s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
err()  { printf 'ERROR: %s\n' "$*" >&2; }

run() {
    if $DRY_RUN; then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# 在部署后的登录 zsh 里执行：拿到 ~/.zshenv 的 PATH、mise 目录和 ~/.zsh_secrets
run_zsh() {
    if $DRY_RUN; then
        printf '  [dry-run] zsh -l -c "%s"\n' "$1"
    else
        zsh -l -c "$1"
    fi
}

mod_key()  { printf '%s' "${1%%|*}"; }
mod_desc() { local r=${1#*|}; printf '%s' "${r%|*}"; }
mod_def()  { printf '%s' "${1##*|}"; }

is_selected() { [[ ",$SELECTED," == *",$1,"* ]]; }

valid_key() {
    local m
    for m in "${MODULES[@]}"; do [[ $(mod_key "$m") == "$1" ]] && return 0; done
    return 1
}

usage() { sed -n '3,14p' "$0"; }

list_modules() {
    local m
    for m in "${MODULES[@]}"; do printf '  %-10s %s\n' "$(mod_key "$m")" "$(mod_desc "$m")"; done
}

default_selection() {
    if [[ -f $STATE_FILE ]]; then
        paste -sd, - < "$STATE_FILE"
        return
    fi
    local m out=""
    for m in "${MODULES[@]}"; do [[ $(mod_def "$m") == 1 ]] && out+="${out:+,}$(mod_key "$m")"; done
    printf '%s' "$out"
}

toggle() {
    local key=$1 out="" k
    [[ $key == core ]] && return
    if is_selected "$key"; then
        for k in ${SELECTED//,/ }; do [[ $k == "$key" ]] || out+="${out:+,}$k"; done
        SELECTED=$out
    else
        SELECTED+="${SELECTED:+,}$key"
    fi
}

choose_interactive() {
    local i m key mark input n
    while true; do
        printf '\n选择要安装和配置的模块（输入编号切换，多个用空格分隔；直接回车开始）：\n\n'
        i=1
        for m in "${MODULES[@]}"; do
            key=$(mod_key "$m")
            mark=' '; is_selected "$key" && mark='x'
            printf '  %2d. [%s] %-10s %s\n' "$i" "$mark" "$key" "$(mod_desc "$m")"
            i=$((i + 1))
        done
        printf '\n> '
        read -r input || input=""
        [[ -z $input ]] && break
        for n in $input; do
            if [[ $n =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#MODULES[@]} )); then
                toggle "$(mod_key "${MODULES[$((n - 1))]}")"
            else
                log "忽略无效输入：$n"
            fi
        done
    done
}

ask() {
    local prompt=$1 default=${2:-} answer
    if [[ ! -t 0 ]]; then printf '%s' "$default"; return; fi
    read -r -p "$prompt${default:+ [$default]}: " answer || answer=""
    printf '%s' "${answer:-$default}"
}

# ---------- 参数 ----------

while (( $# )); do
    case $1 in
        --modules)      SELECTED=$2; shift ;;
        --modules=*)    SELECTED=${1#*=} ;;
        --all)          SELECTED=$(for m in "${MODULES[@]}"; do printf '%s,' "$(mod_key "$m")"; done); SELECTED=${SELECTED%,} ;;
        --storage-root) STORAGE_ROOT=$2; shift ;;
        --storage-root=*) STORAGE_ROOT=${1#*=} ;;
        --dry-run)      DRY_RUN=true ;;
        --list)         list_modules; exit 0 ;;
        -h|--help)      usage; exit 0 ;;
        *) err "未知参数: $1"; usage; exit 1 ;;
    esac
    shift
done

if ! command -v brew >/dev/null 2>&1; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        err "未安装 Homebrew，先按 README「快速开始」安装"
        exit 1
    fi
fi

if [[ -z $SELECTED ]]; then
    SELECTED=$(default_selection)
    if [[ -t 0 ]]; then
        choose_interactive
    fi
fi
is_selected core || SELECTED="core${SELECTED:+,$SELECTED}"
for k in ${SELECTED//,/ }; do
    valid_key "$k" || { err "未知模块: ${k}（bin/setup.sh --list 查看）"; exit 1; }
done

deployed=false
[[ -f $HOME/.zshenv ]] && grep -q '^export DOTFILES_ROOT=' "$HOME/.zshenv" && ! grep -q '__STORAGE_ROOT__' "$HOME/.zshenv" && deployed=true
if [[ -z $STORAGE_ROOT ]] && ! $deployed; then
    STORAGE_ROOT=$(ask "存储根（存放 Code/ 与 Languages/ 的绝对路径）" "$HOME")
fi

step "模块：${SELECTED//,/ }"
$DRY_RUN || { mkdir -p "$(dirname "$STATE_FILE")"; printf '%s\n' ${SELECTED//,/ } > "$STATE_FILE"; }

# ---------- core ----------

step "core：部署 zsh 与工具配置"
if [[ -n $STORAGE_ROOT ]]; then
    run "$DOTFILES_ROOT/bin/deploy.sh" init "$STORAGE_ROOT"
else
    run "$DOTFILES_ROOT/bin/deploy.sh" sync
fi

# ---------- Homebrew 模块 ----------

for k in ${SELECTED//,/ }; do
    f="$DOTFILES_ROOT/brew/$k.Brewfile"
    [[ -f $f ]] || continue
    step "${k}：brew bundle"
    run brew bundle install --file="$f"
done

step "core：zim 模块与 mise 运行时"
run_zsh 'zsh -i -c "zimfw install -q" && mise install'

# ---------- 其他模块 ----------

if is_selected git; then
    step "git：身份与签名"
    for kv in user.name user.email user.signingkey; do
        if [[ -z $(git config --global "$kv" || true) ]]; then
            v=$(ask "git ${kv}（signingkey 填 SSH 公钥全文，空则跳过）" "")
            [[ -n $v ]] && run git config --global "$kv" "$v"
        else
            log "ok      $kv 已设置"
        fi
    done
fi

if is_selected ai; then
    step "ai：安装 claude-code / opencode 并部署配置"
    run_zsh "'$DOTFILES_ROOT/bin/install-ai-cli.sh'"
    # 新的登录 zsh 才能找到刚装进 ~/.local/bin 的 claude，并读到 ~/.zsh_secrets
    run_zsh "'$DOTFILES_ROOT/bin/setup-ai.sh'"
fi

if is_selected rex; then
    step "rex：外观设置（重启 Rex App 生效）"
    run "$DOTFILES_ROOT/bin/apply-rex-defaults.sh"
fi

if is_selected fileassoc; then
    step "fileassoc：文件关联"
    run "$DOTFILES_ROOT/bin/apply-file-associations.sh"
fi

if is_selected shell; then
    step "shell：默认 shell"
    zsh_bin="$(brew --prefix)/bin/zsh"
    if [[ $SHELL == "$zsh_bin" ]]; then
        log "ok      默认 shell 已是 $zsh_bin"
    elif [[ -t 0 ]] || $DRY_RUN; then
        grep -qxF "$zsh_bin" /etc/shells || run sudo sh -c "echo '$zsh_bin' >> /etc/shells"
        run chsh -s "$zsh_bin"
    else
        log "skip    非交互运行，手动执行：chsh -s $zsh_bin"
    fi
fi

# ---------- 验证 ----------

step "验证"
if $DRY_RUN; then
    run "$DOTFILES_ROOT/bin/deploy.sh" check
else
    run_zsh "'$DOTFILES_ROOT/bin/deploy.sh' check" || log "check 有 FAIL 项，按提示处理后重跑 bin/setup.sh"
fi

step "完成。新开终端加载新环境；MCP 的 key / token 按 templates/zsh_secrets.template 填进 ~/.zsh_secrets 后重跑 bin/setup.sh --modules ai"
