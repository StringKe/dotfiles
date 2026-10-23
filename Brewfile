# [TEMPLATE] Brewfile - macOS 软件清单
# 用法: brew bundle install --file=$DOTFILES_ROOT/Brewfile
#
# !!! 严禁 !!!  brew bundle cleanup --file=<本文件>（含 --force）
#   本文件是模板, 不是本机软件全集。cleanup 会卸载所有"不在 Brewfile 里"的软件,
#   包括用户手动 brew install / MAS / 第三方 tap 装的全部工具。等同于灾难性误删。
#   清理孤儿包用 brew autoremove; 单独卸载用 brew uninstall <名>。
#
# 不部署到 ~，直接被 brew bundle 读取。条目按类别分组；语言专用工具只放日常用的。
# 不在这里的：AI CLI 由 bin/install-ai-cli.sh 安装（官方 curl 脚本，自带更新）；
# 终端 Rex Beta 无 cask（https://www.superlogical.com/rex/docs/installation）；
# VS Code 扩展用 Settings Sync，仓库只管 vscode/settings.json。

tap "hashicorp/tap"

# ============================================================
# CLI - Shell 与提示符
# ============================================================
brew "zsh"
brew "starship"        # 跨 shell 提示符
brew "tmux"            # 终端复用
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
brew "coreutils"       # GNU 核心工具（g 前缀；不冲突短名如 timeout 已链到 prefix）
brew "dust"            # 目录占用分析
brew "sevenzip"        # 7z 压缩
brew "sqlcipher"       # 加密 SQLite
brew "age"             # 文件加密
brew "sops"            # 密钥文件加解密

# ============================================================
# CLI - 代码分析 / 反编译
# ============================================================
brew "cloc"            # 代码行统计
brew "jadx"            # Android dex/apk 反编译
brew "cfr-decompiler"  # Java .class 反编译

# ============================================================
# CLI - Git
# ============================================================
brew "git"
brew "gh"              # GitHub CLI
brew "pre-commit"      # Git hooks（本仓库用它跑 gitleaks）

# ============================================================
# CLI - 运行时管理 + 开发辅助
# ============================================================
brew "mise"            # 多语言版本管理
brew "direnv"          # 目录环境变量
brew "mkcert"          # 本地 HTTPS 证书
brew "autocorrect"     # 中英文排版
brew "golangci-lint"   # Go linter
brew "yamllint"        # YAML linter

# ============================================================
# CLI - 网络
# ============================================================
brew "curl"
brew "wget"
brew "aria2"           # 多连接下载
brew "caddy"           # 本地反向代理 / HTTPS
brew "oha"             # HTTP 压测
brew "wrk"             # HTTP 压测 (C 实现, 高并发)
brew "iperf3"          # 网络带宽测试
brew "socat"           # 多用途 socket 中继

# ============================================================
# CLI - 云 / Kubernetes / IaC
# ============================================================
brew "awscli"
brew "azure-cli"
brew "kubernetes-cli"
brew "helm"
brew "kind"
brew "kustomize"
brew "hashicorp/tap/terraform"
brew "opentofu"
brew "terragrunt"
brew "cloudflared"
brew "flarectl"
brew "aliyun-cli"      # 阿里云

# ============================================================
# CLI - 编译器 / 原生工具链
# ============================================================
brew "gcc"             # GNU 编译器套件
brew "llvm"            # LLVM/Clang
brew "cocoapods"       # iOS/macOS 原生依赖管理

# ============================================================
# CLI - JVM 生态（Gradle 项目 + ClickHouse 等用得到）
# ============================================================
brew "gradle"
brew "groovy"

# ============================================================
# CLI - PHP（保留：composer 偶尔用）
# ============================================================
brew "php"
brew "composer"

# ============================================================
# CLI - 多媒体
# ============================================================
brew "ffmpeg-full"     # keg-only，PATH / 编译 flags 在 zshenv
brew "imagemagick"
brew "resvg"           # SVG 渲染
brew "poppler"         # PDF 工具
brew "tesseract"       # OCR 引擎

# ============================================================
# CLI - 数据: server 走 OrbStack docker，本机只留 client
# libpq 由 php 自动拉；zshenv 把它和 mysql-client 的 keg-only bin 放进 PATH
# ============================================================
brew "mysql-client"    # keg-only，与 mysql server 公式冲突
brew "duckdb"          # 本地分析 JSON / CSV / Parquet

# ============================================================
# CLI - 系统集成
# ============================================================
brew "infat"           # 声明式文件类型关联
brew "duti"            # 命令式文件关联 (补 infat 之外的细粒度)
brew "mas"             # App Store CLI
brew "displayplacer"   # 多显示器布局 CLI
brew "qrencode"        # 二维码生成

# ============================================================
# SDK / 云 CLI（cask 安装）
# ============================================================
cask "flutter"
cask "android-platform-tools"
cask "android-commandlinetools"
cask "gcloud-cli"
cask "consul"

# ============================================================
# GUI - 编辑器 / 开发环境
# ============================================================
cask "visual-studio-code"
cask "jetbrains-toolbox"
cask "orbstack"
cask "freelens"        # Kubernetes 集群 GUI
cask "simplysign"      # Certum 云端代码签名证书

# ============================================================
# GUI - 生产力 / 浏览器 / 通讯
# ============================================================
cask "1password"
cask "1password-cli"
cask "google-chrome"
cask "telegram"
cask "whatsapp"

# ============================================================
# GUI - 网络工具
# ============================================================
cask "cloudflare-warp"
cask "ngrok"

# ============================================================
# 字体: 全部 Maple Mono 系列 (终端 + VS Code 统一 Maple Mono NF CN)
# ============================================================
cask "font-maple-mono"
cask "font-maple-mono-cn"
cask "font-maple-mono-nf"
cask "font-maple-mono-nf-cn"
cask "font-maple-mono-normal"
cask "font-maple-mono-normal-cn"
cask "font-maple-mono-normal-nf"
cask "font-maple-mono-normal-nf-cn"

# ============================================================
# Mac App Store
# ============================================================
mas "Xcode", id: 497799835
