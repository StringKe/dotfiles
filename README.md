# dotfiles

我的 macOS 开发环境。运行 `bin/setup.sh`，勾选需要的模块，它会装软件、部署 zsh 和各工具配置、配好 claude-code 与 opencode。重跑即更新。

- 终端：[Rex](https://www.superlogical.com/rex/docs/installation)（需单独安装），字体 Maple Mono NF CN
- Shell：zsh + zimfw + starship，语言运行时用 mise
- 配色：GitHub Light Colorblind（橙代红、蓝代绿），工具大多跟随终端 ANSI 配色
- AI：claude-code 与 opencode 共用一份全局提示词和 skills，MCP 两边保持同一组

## 快速开始

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

git clone https://github.com/StringKe/dotfiles.git ~/Code/SelfCode/dotfiles
cd ~/Code/SelfCode/dotfiles
bin/setup.sh
```

首次运行会问「存储根」：存放 `Code/` 和 `Languages/`（各语言的缓存与全局工具）的目录，比如外置盘 `/Volumes/Storage` 或 home。跑完新开一个终端。

## 模块

| 模块 | 内容 | 默认 |
|---|---|---|
| `core` | zsh 配置、starship / yazi / atuin / bat / btop / ripgrep 等工具与配置、zim 插件、mise 运行时 | 必选 |
| `dev` | gcc、llvm、golangci-lint、yamllint、caddy、mysql-client、duckdb、age、sops | 是 |
| `cloud` | aws、aliyun、gcloud、kubectl、helm、kind、kustomize、opentofu、terragrunt、cloudflared、Freelens、WARP | |
| `mobile` | cocoapods、Flutter、Android SDK 工具 | |
| `jvm` | gradle | |
| `php` | php、composer | |
| `media` | ffmpeg、imagemagick、poppler、tesseract | |
| `reverse` | jadx | |
| `apps` | VS Code、JetBrains Toolbox、OrbStack、1Password、Chrome、Telegram、WhatsApp、SimplySign | 是 |
| `xcode` | 从 App Store 装 Xcode | |
| `ai` | claude-code、opencode、全局提示词、skills、hooks、MCP | 是 |
| `rex` | Rex 外观设置 | 是 |
| `fileassoc` | 代码文件默认用 VS Code 打开 | 是 |
| `git` | 询问 git 身份与签名公钥 | 是 |
| `shell` | 默认 shell 换成 Homebrew zsh | 是 |

选择保存在 `~/.config/dotfiles/modules`，下次作为默认值。

```bash
bin/setup.sh --list                    # 列出模块
bin/setup.sh --modules core,dev,ai     # 直接执行，不进选择界面
bin/setup.sh --dry-run                 # 只看会执行什么
bin/setup.sh --storage-root <路径>      # 换存储根
```

## 需要自己准备的

- **MCP 密钥**：照 `config/zsh/zsh_secrets.template` 把 context7、exa、openseo、truewatch、fingerprint、slack 的 key 填进 `~/.zsh_secrets`，再跑 `bin/setup.sh --modules ai`。没填的 MCP 会跳过。
- **git 签名**：commit 默认用 1Password 里的 SSH key 签名，需在 1Password 设置 -> Developer 打开 SSH agent。
- **Rex**：外观设置要重启 Rex 才生效。
- **paper / rea MCP**：分别要先装 Paper 和 Hopper Disassembler；rea 只在 opencode 里启用。

## 日常

| 做什么 | 命令 |
|---|---|
| 拉新版本后更新 | `git pull --ff-only && bin/setup.sh` |
| 应用 mise 全局工具或 VS Code 设置的改动 | `bin/setup.sh --storage-root <当前存储根>`，会覆盖本机 `mise use -g` 的改动 |
| 只同步 zsh 和工具配置 | `bin/deploy.sh sync` |
| 只更新 AI 配置 | `bin/setup-ai.sh` |
| 检查部署状态 | `bin/deploy.sh check` |
| 升级 claude-code 与 opencode | `aiupdate` |

zsh 入口、`init.zsh`、Rex 与 btop 主题、infat 配置每次 `sync` 都覆盖。starship、yazi、atuin、bat、ripgrep、`btop.conf`、git ignore 在本机改过就不覆盖，`sync` 只提示 `differs`；想换回仓库版，`trash` 掉本机那个文件再 `sync`。

常用别名：`ll` / `lt`（eza）、`hh`（历史搜索）、`lg`（lazygit）、`y`（yazi）、`k*`（kubectl）。`rm` 会把文件放进废纸篓，真删用 `command rm`。

## 让 AI 帮你部署

````
帮我部署或更新 dotfiles（仓库在 ~/Code/SelfCode/dotfiles 或 /Volumes/Storage/Code/SelfCode/dotfiles）。
先完整读仓库根目录的 CLAUDE.md，按其中的 CONSUMER 模式执行，安装和配置都用 bin/setup.sh。
不要修改或提交仓库文件。迁移数据、覆盖本机配置前先列清单给我确认。
最后跑 bin/deploy.sh check，逐项报告 PASS / FAIL。
````

## 目录

```
bin/        脚本：setup.sh 安装向导，deploy.sh 部署 shell 与工具配置（init / sync / check），setup-ai.sh 部署 AI 配置并注册 MCP
brew/       各模块的软件清单
config/     shell 与工具配置，每个工具一个目录：zsh、mise、git、rex、starship、yazi、atuin、bat、btop、ripgrep、infat、vscode
ai/         AI 配置：全局提示词，claude-code 与 opencode 的设置、hooks、agents、skills、插件、MCP，链接到 ~
CLAUDE.md   给 AI 的规则：部署流程、每个文件部署到哪、各项设计说明
```

## 修改

改仓库前告诉 AI「这是 MAINTAINER 模式」。每类改动改哪个文件、怎么生效，见 CLAUDE.md「部署目标对照」。AI 改完会直接 commit，push 等你说。

仓库是公开的：不要提交密钥、账号、公司或内网信息、本机路径。提交前会自动跑 gitleaks。
