#!/usr/bin/env bash
# guard-file-writes.sh - PreToolUse(Edit|Write|NotebookEdit) hook：拦下往 .github/workflows/ 写文件，任何仓库都不建 GitHub Actions。

export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
set -uo pipefail

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null) || exit 0
case "$file" in
    */.github/workflows/*)
        printf '[guard-file-writes] 任何仓库都不建 .github/workflows：本地验证是门槛，GitHub Actions 会烧掉配额。用户本轮点名要求时，用 Bash 写入并在命令前加 SHELL_OK=1。\n' >&2
        exit 2
        ;;
esac
exit 0
