# [TEMPLATE] Brewfile - macOS 软件清单
# 用法: brew bundle install --file=$DOTFILES_ROOT/Brewfile
#
# AI 规则:
#   - 此文件是仓库模板，不部署到 ~/。AI 直接调用此文件。
#   - 添加/删除条目时按类别分组。语言专用工具仅放日常使用的（Go / Web 全栈）。

# ============================================================
# Taps
# ============================================================
tap "cloudflare/cloudflare"
tap "hashicorp/tap"

# ============================================================
# CLI - Shell 与提示符
# ============================================================
brew "zsh"
brew "starship"        # 跨 shell 提示符
brew "pam-reattach"    # tmux 下 Touch ID sudo

# ============================================================
# CLI - 效率工具
# ============================================================
brew "atuin"           # 智能历史搜索
brew "fzf"             # 模糊搜索
brew "zoxide"          # 智能目录跳转
brew "yazi"            # 终端文件管理器
brew "eza"             # 现代 ls 替代
brew "fd"              # 现代 find 替代
brew "ripgrep"         # 现代 grep 替代
brew "bat"             # 现代 cat 替代（语法高亮）
brew "btop"            # 系统监控
brew "tree"            # 目录树
brew "watch"           # 重复执行命令
brew "pv"              # 管道查看器
brew "jq"              # JSON 处理
brew "yq"              # YAML 处理
brew "lazygit"         # Git TUI
brew "fastfetch"       # 系统信息展示

# ============================================================
# CLI - 文件工具
# ============================================================
brew "macos-trash"     # 安全删除（Finder 回收站）
brew "coreutils"       # GNU 核心工具
brew "sevenzip"        # 7z 压缩

# ============================================================
# CLI - Git
# ============================================================
brew "git"
brew "gh"              # GitHub CLI
brew "pre-commit"      # Git hooks

# ============================================================
# CLI - 运行时管理 + 开发辅助
# ============================================================
brew "mise"            # 多语言版本管理
brew "direnv"          # 目录环境变量
brew "mkcert"          # 本地 HTTPS 证书
brew "autocorrect"     # 中英文排版

# ============================================================
# CLI - 网络
# ============================================================
brew "curl"
brew "wget"
brew "oha"             # HTTP 压测
brew "iperf3"          # 网络带宽测试

# ============================================================
# CLI - 云 / Kubernetes / IaC
# ============================================================
brew "awscli"
brew "azure-cli"
brew "kubernetes-cli"
brew "helm"
brew "kind"
brew "kustomize"
brew "k8sgpt"
brew "argo"
brew "argocd"
brew "hashicorp/tap/terraform"
brew "opentofu"
brew "terragrunt"
brew "cloudflared"
brew "flarectl"
brew "operator-sdk"

# ============================================================
# CLI - 语言工具链（Go 生态）
# ============================================================
brew "golangci-lint"   # Go linter

# ============================================================
# CLI - JVM 生态（Gradle 项目 + ClickHouse 等用得到）
# ============================================================
brew "gradle"
brew "groovy"
brew "erlang"          # RabbitMQ 依赖

# ============================================================
# CLI - PHP（保留：composer 偶尔用）
# ============================================================
brew "php"
brew "composer"

# ============================================================
# CLI - 多媒体
# ============================================================
brew "ffmpeg"
brew "imagemagick"
brew "resvg"           # SVG 渲染
brew "poppler"         # PDF 工具

# ============================================================
# CLI - 数据库
# ============================================================
brew "mariadb"
brew "mariadb-connector-c"
brew "libpq"
brew "postgresql@18"
brew "pgloader"
brew "redis"
brew "rabbitmq"

# ============================================================
# CLI - Linter
# ============================================================
brew "yamllint"

# ============================================================
# CLI - 系统集成
# ============================================================
brew "infat"           # 声明式文件类型关联
brew "mas"             # App Store CLI

# ============================================================
# GUI - 终端 / 编辑器
# ============================================================
cask "ghostty"
cask "visual-studio-code"
cask "jetbrains-toolbox"

# ============================================================
# GUI - 开发环境
# ============================================================
cask "orbstack"
cask "claude-code"     # Claude Code CLI

# ============================================================
# GUI - 生产力
# ============================================================
cask "1password"
cask "1password-cli"
cask "raycast"
cask "claude"          # Claude GUI

# ============================================================
# GUI - 浏览器
# ============================================================
cask "google-chrome"

# ============================================================
# GUI - 通讯
# ============================================================
cask "telegram"
cask "whatsapp"

# ============================================================
# GUI - 网络工具
# ============================================================
cask "cloudflare-warp"
cask "mitmproxy"
cask "ngrok"

# ============================================================
# GUI - SDK
# ============================================================
cask "flutter"
cask "android-platform-tools"

# ============================================================
# GUI - 云工具
# ============================================================
cask "gcloud-cli"
cask "codex"
cask "consul"

# ============================================================
# VS Code 扩展 - 通用工具
# ============================================================
vscode "editorconfig.editorconfig"            # EditorConfig
vscode "eamodio.gitlens"                      # Git 增强
vscode "github.copilot-chat"                  # GitHub Copilot
vscode "dbaeumer.vscode-eslint"               # ESLint
vscode "esbenp.prettier-vscode"               # Prettier 格式化
vscode "streetsidesoftware.code-spell-checker" # 拼写检查
vscode "gruntfuggly.todo-tree"                # TODO 高亮
vscode "usernamehw.errorlens"                 # 行内错误提示
vscode "tamasfe.even-better-toml"             # TOML 语法高亮

# ============================================================
# VS Code 扩展 - 文档 / 文件预览
# ============================================================
vscode "yzhang.markdown-all-in-one"           # Markdown 编辑增强
vscode "shd101wyy.markdown-preview-enhanced"  # Markdown 预览（mermaid/LaTeX/流程图）
vscode "bierner.markdown-mermaid"             # Mermaid 内联预览
vscode "redhat.vscode-yaml"                   # YAML 智能提示
vscode "redhat.vscode-xml"                    # XML
vscode "zainchen.json"                        # JSON 预览 + 格式化
vscode "tomoki1207.pdf"                       # PDF 预览
vscode "janisdd.vscode-edit-csv"              # CSV 编辑器
vscode "hediet.vscode-drawio"                 # Draw.io 图表编辑
vscode "jock.svg"                             # SVG 预览

# ============================================================
# VS Code 扩展 - 容器 / 远程
# ============================================================
vscode "ms-azuretools.vscode-docker"          # Docker
vscode "ms-kubernetes-tools.vscode-kubernetes-tools" # Kubernetes
vscode "ms-vscode-remote.remote-ssh"          # SSH 远程开发
vscode "ms-vscode-remote.remote-containers"   # Dev Containers
vscode "hashicorp.terraform"                  # Terraform

# ============================================================
# VS Code 扩展 - Go
# ============================================================
vscode "golang.go"                            # Go

# ============================================================
# VS Code 扩展 - Web 前端 (TS / Vue / Svelte / Astro / Tailwind / Bun / Deno)
# ============================================================
vscode "bradlc.vscode-tailwindcss"            # Tailwind CSS
vscode "Vue.volar"                            # Vue
vscode "svelte.svelte-vscode"                 # Svelte
vscode "astro-build.astro-vscode"             # Astro
vscode "denoland.vscode-deno"                 # Deno
vscode "oven.bun-vscode"                      # Bun

# ============================================================
# VS Code 扩展 - 主题（Catppuccin Latte，与终端工具对齐）
# ============================================================
vscode "Catppuccin.catppuccin-vsc"            # Catppuccin 颜色主题
vscode "Catppuccin.catppuccin-vsc-icons"      # Catppuccin 图标主题

# ============================================================
# 字体
# ============================================================
cask "font-maple-mono"
cask "font-maple-mono-cn"
cask "font-maple-mono-nf"
cask "font-maple-mono-nf-cn"
cask "font-maple-mono-normal"
cask "font-maple-mono-normal-cn"
cask "font-maple-mono-normal-nf"
cask "font-maple-mono-normal-nf-cn"
cask "font-jetbrains-mono-nerd-font"

# ============================================================
# Mac App Store
# ============================================================
mas "Xcode", id: 497799835
