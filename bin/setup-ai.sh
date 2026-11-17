#!/usr/bin/env bash
# [TOOL] AI 的 agents、hooks、插件与 opencode 配置部署（claude-code / opencode）
#
# agents、hooks、statusline、worktree 插件与 opencode 配置用符号链接指回仓库 ai/：
# 在 ~ 里编辑等于改仓库，git status 可见。仓库里删除或改名的条目，对应的旧链接会被清掉。
# 全局提示词、个人 skills 与 MCP 由 magpie 的 Library 写进两个 agent，本脚本不碰。
# ~/.claude/settings.json 由 Claude Code 运行时改写，用 jq 深合并（本地字段保留，仓库同名 key 覆盖）。
# 被替换的旧文件 / 目录放进废纸篓。
#
# 用法:
#   bin/setup-ai.sh

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI="$DOTFILES_ROOT/ai"

log() { printf '  %s\n' "$*"; }

linked=()

link() {
    local src=$1 dst=$2
    linked+=("$dst")
    mkdir -p "$(dirname "$dst")"
    if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then
        log "ok      $dst"
        return
    fi
    if [[ -e $dst || -L $dst ]]; then
        trash "$dst"
        log "trashed $dst"
    fi
    ln -s "$src" "$dst"
    log "linked  $dst -> $src"
}

merge_claude_settings() {
    local src="$AI/claude/settings.json" dst="$HOME/.claude/settings.json"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -f $dst ]]; then
        cp "$src" "$dst"
        log "wrote   $dst"
        return
    fi
    local tmp="$dst.tmp.$$"
    # hooks 的数组按条目合并：rtk、rex 等工具自己加的 hook 留着，`*` 会整组替换掉它们
    if ! jq -s '(.[0] // {}) as $l | (.[1] // {}) as $r | ($l * $r) | .hooks = (($l.hooks // {}) as $lh | ($r.hooks // {}) as $rh | reduce (($lh + $rh) | keys[]) as $k ({}; .[$k] = (($rh[$k] // []) + (($lh[$k] // []) - ($rh[$k] // []))))) | if .hooks == {} then del(.hooks) else . end' "$dst" "$src" > "$tmp"; then
        rm -f "$tmp"
        log "error   $dst 不是合法 JSON，修正后重跑"
        return 1
    fi
    mv "$tmp" "$dst"
    log "merged  $dst"
}

# rex skill setup 追加的 SessionStart hook 与 rex-session-start.sh 跑同一条命令，留着会把 Rex 说明注入两遍。
drop_rex_session_hook() {
    local dst="$HOME/.claude/settings.json" tmp
    [[ -f $dst ]] || return 0
    tmp="$dst.tmp.$$"
    if jq 'if .hooks.SessionStart then .hooks.SessionStart |= map(select(any(.hooks[]?; (.command // "") | contains("rex __internal session-start")) | not)) else . end' "$dst" > "$tmp"; then
        mv "$tmp" "$dst"
    else
        rm -f "$tmp"
    fi
}

# 仓库里删除或改名的条目：清掉本脚本以前建的、本次不再建的指回 ai/ 的链接
prune_links() {
    local dir entry keep
    for dir in "$HOME/.claude/rules" "$HOME/.claude/hooks" "$HOME/.claude/agents" "$HOME/.claude/skills" \
        "$HOME/.agents/skills" "$HOME/.agents/plugins" "$HOME/.config/opencode/skills"; do
        [[ -d $dir ]] || continue
        for entry in "$dir"/*; do
            [[ -L $entry && $(readlink "$entry") == "$AI/"* ]] || continue
            keep=false
            for l in "${linked[@]}"; do [[ $l == "$entry" ]] && { keep=true; break; }; done
            if ! $keep; then
                trash "$entry"
                log "pruned  $entry"
            fi
        done
    done
}

# Claude Code agents / hooks / statusline
for f in "$AI"/claude/agents/*.md; do
    link "$f" "$HOME/.claude/agents/${f##*/}"
done
for f in "$AI"/claude/hooks/*.sh; do
    link "$f" "$HOME/.claude/hooks/${f##*/}"
done
link "$AI/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

# 个人插件：~/.agents/plugins 放整个插件；插件里的 skill 与 ai/skills/* 一样由 magpie Library 分发
for p in "$AI"/plugins/*/; do
    p=${p%/}
    link "$p" "$HOME/.agents/plugins/${p##*/}"
done

# opencode 配置
link "$AI/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
link "$AI/opencode/tui.json" "$HOME/.config/opencode/tui.json"

prune_links

# Claude Code 设置
merge_claude_settings

# 第三方 skill：Rex 自带安装器
if command -v rex >/dev/null 2>&1; then
    rex skill setup --agent claude --agent opencode >/dev/null
    drop_rex_session_hook
    log "rex     skill setup"
fi

# 公开仓库：链接文件在 ~ 里编辑后提交，先过 gitleaks
if command -v pre-commit >/dev/null 2>&1; then
    (cd "$DOTFILES_ROOT" && pre-commit install >/dev/null)
    log "hook    pre-commit (gitleaks)"
fi

log ""
log "MCP 的 key / token 按 config/zsh/zsh_secrets.template 在 ~/.zsh_secrets 填写"
log "全局提示词、个人 skills 与 MCP 在 magpie 的 Library 里管理（magpie library）"
