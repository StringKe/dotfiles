# macOS 开发环境 Brewfile
# 使用方法: brew bundle install --file=Brewfile

# ============================================================
# Taps
# ============================================================
tap "cloudflare/cloudflare"
tap "hashicorp/tap"

# ============================================================
# CLI 工具
# ============================================================

# Shell
brew "zsh"
brew "starship"        # 跨 shell 提示符
brew "pam-reattach"    # tmux 下 Touch ID sudo

# 效率工具
brew "atuin"           # 智能历史搜索
brew "fzf"             # 模糊搜索
brew "zoxide"          # 智能目录跳转
brew "yazi"            # 终端文件管理器
brew "eza"             # 现代 ls 替代
brew "fd"              # 现代 find 替代
brew "ripgrep"         # 现代 grep 替代
brew "btop"            # 系统监控
brew "tree"            # 目录树
brew "watch"           # 重复执行命令
brew "pv"              # 管道查看器
brew "jq"              # JSON 处理
brew "yq"              # YAML 处理
brew "lazygit"         # Git TUI

# 文件工具
brew "macos-trash"     # 安全删除（Finder 回收站）
brew "coreutils"       # GNU 核心工具
brew "sevenzip"        # 7z 压缩

# Git
brew "git"
brew "gh"              # GitHub CLI
brew "pre-commit"      # Git hooks

# 运行时管理
brew "mise"            # 多语言版本管理

# 网络工具
brew "curl"
brew "wget"
brew "oha"             # HTTP 压测
brew "iperf3"          # 网络带宽测试

# 云和 Kubernetes
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

# 开发工具
brew "direnv"          # 目录环境变量
brew "mkcert"          # 本地 HTTPS 证书
brew "autocorrect"     # 中英文排版
brew "golangci-lint"   # Go linter
brew "gradle"
brew "groovy"
brew "erlang"
brew "php"
brew "composer"

# 多媒体
brew "ffmpeg"
brew "imagemagick"
brew "resvg"           # SVG 渲染
brew "poppler"         # PDF 工具

# 系统信息
brew "fastfetch"       # 系统信息展示

# Kubernetes Operator
brew "operator-sdk"

# 数据库
brew "mariadb"
brew "mariadb-connector-c"
brew "libpq"
brew "postgresql@18"
brew "pgloader"
brew "redis"
brew "rabbitmq"

# 验证工具
brew "yamllint"

# 文件关联
brew "infat"           # 声明式文件类型关联

# App Store
brew "mas"

# ============================================================
# GUI 应用
# ============================================================

# 终端
cask "ghostty"

# 开发
cask "visual-studio-code"
cask "jetbrains-toolbox"
cask "orbstack"
cask "claude-code"     # Claude Code CLI

# 生产力
cask "1password"
cask "1password-cli"
cask "raycast"
cask "claude"          # Claude GUI

# 浏览器
cask "google-chrome"

# 通讯
cask "telegram"
cask "whatsapp"

# 网络工具
cask "cloudflare-warp"
cask "mitmproxy"
cask "ngrok"

# SDK
cask "flutter"
cask "android-platform-tools"

# 云工具
cask "gcloud-cli"
cask "codex"
cask "consul"

# ============================================================
# VSCode 扩展
# ============================================================
vscode "yzhang.markdown-all-in-one"           # Markdown 编辑增强
vscode "shd101wyy.markdown-preview-enhanced"  # Markdown 预览（支持 mermaid/LaTeX/流程图）
vscode "bierner.markdown-mermaid"             # Mermaid 图表预览
vscode "redhat.vscode-yaml"                   # YAML 智能提示 + 预览
vscode "tamasfe.even-better-toml"             # TOML 语法高亮 + 验证
vscode "zainchen.json"                        # JSON 预览 + 格式化
vscode "hediet.vscode-drawio"                 # Draw.io 图表编辑
vscode "jock.svg"                             # SVG 预览
vscode "tomoki1207.pdf"                       # PDF 预览
vscode "janisdd.vscode-edit-csv"              # CSV 编辑器

# 语言支持
vscode "rust-lang.rust-analyzer"              # Rust
vscode "golang.go"                            # Go
vscode "ms-python.python"                     # Python
vscode "ms-python.vscode-pylance"             # Python 类型检查
vscode "redhat.java"                          # Java
vscode "vscjava.vscode-java-pack"             # Java 扩展包
vscode "mathiasfrohlich.Kotlin"               # Kotlin
vscode "scalameta.metals"                     # Scala
vscode "dbaeumer.vscode-eslint"               # ESLint
vscode "esbenp.prettier-vscode"               # Prettier 格式化
vscode "bradlc.vscode-tailwindcss"            # Tailwind CSS
vscode "Vue.volar"                            # Vue
vscode "svelte.svelte-vscode"                 # Svelte
vscode "astro-build.astro-vscode"             # Astro
vscode "denoland.vscode-deno"                 # Deno
vscode "oven.bun-vscode"                      # Bun
vscode "Shopify.ruby-lsp"                     # Ruby
vscode "swiftlang.swift-vscode"               # Swift
vscode "ms-vscode.cpptools"                   # C/C++
vscode "ziglang.vscode-zig"                   # Zig
vscode "Dart-Code.dart-code"                  # Dart
vscode "JakeBecker.elixir-ls"                 # Elixir

# DevOps / IaC
vscode "hashicorp.terraform"                  # Terraform
vscode "ms-kubernetes-tools.vscode-kubernetes-tools" # Kubernetes
vscode "ms-azuretools.vscode-docker"          # Docker
vscode "redhat.vscode-xml"                    # XML

# 工具
vscode "editorconfig.editorconfig"            # EditorConfig
vscode "eamodio.gitlens"                      # Git 增强
vscode "github.copilot-chat"                  # GitHub Copilot
vscode "ms-vscode-remote.remote-ssh"          # SSH 远程开发
vscode "ms-vscode-remote.remote-containers"   # Dev Containers
vscode "streetsidesoftware.code-spell-checker" # 拼写检查
vscode "gruntfuggly.todo-tree"                # TODO 高亮
vscode "usernamehw.errorlens"                 # 行内错误提示
vscode "PKief.material-icon-theme"            # 文件图标主题

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
