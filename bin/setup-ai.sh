#!/usr/bin/env bash
# [TOOL] AI 提示词、skills、hooks、插件与 MCP 部署（claude-code / opencode）
#
# 提示词、rules、hooks、statusline、个人 skills、worktree 插件、opencode 配置
# 用符号链接指回仓库 ai/：在 ~ 里编辑等于改仓库，git status 可见。
# ~/.claude/settings.json 由 Claude Code 运行时改写，用 jq 深合并（本地字段保留，仓库同名 key 覆盖）。
# MCP 用 claude mcp add-json -s user 写进 ~/.claude.json；密钥按变量名引用 ~/.zsh_secrets。
# 被替换的旧文件 / 目录放进废纸篓。
#
# 用法:
#   bin/setup-ai.sh

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI="$DOTFILES_ROOT/ai"

log() { printf '  %s\n' "$*"; }

link() {
    local src=$1 dst=$2
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
    jq -s '(.[0] // {}) * (.[1] // {})' "$dst" "$src" > "$tmp"
    mv "$tmp" "$dst"
    log "merged  $dst"
}

add_claude_mcp() {
    local name json
    for name in $(jq -r 'keys[]' "$AI/claude/mcp.json"); do
        json=$(jq -c --arg home "$HOME" --arg n "$name" '.[$n] | walk(if type == "string" then gsub("\\$\\{HOME\\}"; $home) else . end)' "$AI/claude/mcp.json")
        claude mcp remove -s user "$name" >/dev/null 2>&1 || true
        claude mcp add-json -s user "$name" "$json" >/dev/null
        log "mcp     $name"
    done
}

# 全局提示词：Claude Code 与 opencode 共用一份
link "$AI/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link "$AI/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

# Claude Code rules / hooks / statusline
for f in "$AI"/claude/rules/*.md; do
    link "$f" "$HOME/.claude/rules/${f##*/}"
done
for f in "$AI"/claude/hooks/*.sh; do
    link "$f" "$HOME/.claude/hooks/${f##*/}"
done
link "$AI/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

# 个人 skills：~/.agents/skills 为共享目录，Claude Code 与 opencode 各自目录也直接指回仓库
for d in "$AI"/skills/*/; do
    d=${d%/}
    link "$d" "$HOME/.agents/skills/${d##*/}"
    link "$d" "$HOME/.claude/skills/${d##*/}"
    link "$d" "$HOME/.config/opencode/skills/${d##*/}"
done

# 个人插件：Claude Code 按 skills 目录里的插件加载；opencode 只认 skill，逐个链接
for p in "$AI"/plugins/*/; do
    p=${p%/}
    link "$p" "$HOME/.agents/plugins/${p##*/}"
    link "$p" "$HOME/.claude/skills/${p##*/}"
    for s in "$p"/skills/*/; do
        s=${s%/}
        link "$s" "$HOME/.config/opencode/skills/${s##*/}"
    done
done

# opencode 配置
link "$AI/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
link "$AI/opencode/tui.json" "$HOME/.config/opencode/tui.json"

# Claude Code 设置与 MCP
merge_claude_settings
if command -v claude >/dev/null 2>&1; then
    add_claude_mcp
else
    log "skip    MCP（claude 未安装，先跑 bin/install-ai-cli.sh）"
fi

# 第三方 skill：Rex 自带安装器；ego-browser 随 ego lite 安装
if command -v rex >/dev/null 2>&1; then
    rex skill setup --agent claude --agent opencode >/dev/null
    log "rex     skill setup"
fi
ego_skill="$HOME/.local/share/ego/ego-skills"
if [[ -d $ego_skill ]]; then
    link "$ego_skill" "$HOME/.agents/skills/ego-browser"
    link "$ego_skill" "$HOME/.claude/skills/ego-browser"
    link "$ego_skill" "$HOME/.config/opencode/skills/ego-browser"
fi

# 公开仓库：链接文件在 ~ 里编辑后提交，先过 gitleaks
if command -v pre-commit >/dev/null 2>&1; then
    (cd "$DOTFILES_ROOT" && pre-commit install >/dev/null)
    log "hook    pre-commit (gitleaks)"
fi

log ""
log "MCP 的 key / token 按 templates/zsh_secrets.template 在 ~/.zsh_secrets 填写"
