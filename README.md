# dotfiles

macOS 开发环境的配置模板。`bin/setup.sh` 按你选的模块安装软件、部署 zsh 与工具配置、配置 AI CLI；重跑即更新。

- 仓库是只读模板：配置由 `bin/deploy.sh` 复制（并替换占位符）到 home。例外是 `git/config`（`~/.gitconfig` 用 `[include]` 引用）和 `ai/`（由 `bin/setup-ai.sh` 符号链接到 home）。
- 终端用 Rex Beta（无 brew cask，安装见 https://www.superlogical.com/rex/docs/installation），字体 Maple Mono NF CN。
- 配色以 GitHub Light Colorblind 为准：橙色替代红，蓝色替代绿，避免红绿色盲混淆。多数工具跟随终端 ANSI 配色；Rex 当前用内置 `merino-light`，`rex/themes/` 附带同名调色板可在 Rex 设置里切换。
- AI 协作规则、部署目标对照和各配置的设计说明见 [CLAUDE.md](CLAUDE.md)。

## 快速开始

```bash
# 1. Xcode CLT 与 Homebrew
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. 克隆仓库（位置任意，下面以 /Volumes/Storage 为例）
mkdir -p /Volumes/Storage/Code/SelfCode
git clone https://github.com/StringKe/dotfiles.git /Volumes/Storage/Code/SelfCode/dotfiles
cd /Volumes/Storage/Code/SelfCode/dotfiles

# 3. 向导：选择模块后自动执行
bin/setup.sh
```

首次运行会问存储根：存放 `Code/` 与 `Languages/`（各语言的包缓存、全局工具）的绝对路径，例如 `/Volumes/Storage` 或你的 home。完成后新开终端。

## 模块

| 模块 | 内容 | 默认 |
|---|---|---|
| `core` | zsh 入口与 `init.zsh`、starship / yazi / atuin / bat / btop / ripgrep 等配置、`brew/core.Brewfile`、zim 模块、mise 运行时 | 必选 |
| `dev` | gcc / llvm / golangci-lint / yamllint / caddy / mysql-client / duckdb / age / sops | 选中 |
| `cloud` | awscli / aliyun-cli / gcloud / kubectl / helm / kind / kustomize / opentofu / terragrunt / cloudflared / Freelens / WARP | |
| `mobile` | cocoapods / Flutter / Android platform-tools 与 commandlinetools | |
| `jvm` | gradle（JDK 由 mise 提供） | |
| `php` | php / composer | |
| `media` | ffmpeg-full / imagemagick / poppler / tesseract | |
| `reverse` | jadx | |
| `apps` | VS Code / JetBrains Toolbox / OrbStack / 1Password / Chrome / Telegram / WhatsApp / SimplySign | 选中 |
| `xcode` | App Store 安装 Xcode（需已登录 App Store） | |
| `ai` | claude-code 与 opencode v2、全局提示词、skills、hooks、worktree 插件、MCP | 选中 |
| `rex` | Rex 外观设置（重启 Rex App 生效） | 选中 |
| `fileassoc` | 代码文件默认用 VS Code 打开 | 选中 |
| `git` | 未设置时询问 git 身份与签名公钥 | 选中 |
| `shell` | 默认 shell 换成 Homebrew zsh | 选中 |

选择会保存在 `~/.config/dotfiles/modules`，下次运行作为默认值。常用参数：

```bash
bin/setup.sh --list                        # 列出模块
bin/setup.sh --modules core,dev,ai         # 不进交互，直接执行指定模块
bin/setup.sh --dry-run                     # 只打印步骤
bin/setup.sh --storage-root /Volumes/Storage   # 换存储根或重新生成 mise 全局配置
```

### 部署前后要手动做的事

- **MCP 密钥**：按 `templates/zsh_secrets.template` 在 `~/.zsh_secrets` 填 context7、exa、openseo、sentry、fingerprint 的 key / token，然后 `bin/setup.sh --modules ai`。缺 key 的 MCP 会被跳过，不会注册一个连不上的条目。
- **git 签名**：`git/config` 要求 commit 签名，默认经 1Password SSH agent（在 1Password Settings -> Developer 开启）。不用 1Password 时按 CLAUDE.md「Git 签名」在本机 `~/.gitconfig` 改用本地私钥。
- **Rex**：外观设置写入后要重启 Rex App。
- **paper / rea MCP**：分别需要先装 Paper 桌面应用和 Hopper Disassembler。

## 日常

| 场景 | 命令 |
|---|---|
| 拉了新版本仓库 | `git pull --ff-only` 后 `bin/setup.sh`（沿用上次的模块） |
| 只同步 zsh 与工具配置 | `bin/deploy.sh sync` |
| 只更新 AI 配置 / MCP | `bin/setup-ai.sh` |
| 检查部署状态 | `bin/deploy.sh check` |
| 更新 claude-code 与 opencode | `aiupdate` |

`bin/deploy.sh sync` 遇到本机已存在、内容与仓库不同的工具配置时只提示 `differs`，不覆盖；要用仓库版先 `trash` 本机文件再 sync。

## 通过 AI 部署 / 更新

把下面的提示词发给 AI 助手（Claude Code / opencode 等）：

````
帮我部署或更新 dotfiles。仓库已克隆到本机（依次找 $HOME/Code/SelfCode/dotfiles、/Volumes/Storage/Code/SelfCode/dotfiles，记为 DOTFILES_ROOT）。
先完整读 DOTFILES_ROOT/CLAUDE.md，按其中的 CONSUMER 模式和「部署场景」执行，安装与配置统一用 DOTFILES_ROOT/bin/setup.sh。
不修改、不提交仓库文件。迁移数据、覆盖本机已有配置前先给我看清单再执行。
最后跑 bin/deploy.sh check，报告每项 PASS / FAIL。
````

## 仓库结构

```
dotfiles/
├── bin/
│   ├── setup.sh                       安装与配置向导（按模块）
│   ├── deploy.sh                      部署 zsh 与工具配置（init / sync / check）
│   ├── setup-ai.sh                    AI 提示词 / skills / hooks / 插件 / MCP 部署
│   ├── install-ai-cli.sh              claude-code / opencode v2 官方 curl 安装
│   ├── apply-rex-defaults.sh          Rex Workspace.* 外观设置
│   └── apply-file-associations.sh     infat + duti 文件关联
├── brew/<模块>.Brewfile    软件清单，按模块拆分
├── ai/                     [LINKED] AI 配置，符号链接到 ~
│   ├── AGENTS.md           全局提示词（Claude Code 与 opencode 共用）
│   ├── claude/             rules / hooks / statusline / settings.json / mcp.json
│   ├── opencode/           opencode.jsonc（MCP、权限）/ tui.json
│   ├── skills/             个人 skills
│   └── plugins/            个人插件（worktree）
├── zsh/                    [TEMPLATE] zsh 入口（zshenv / zprofile / zshrc / zimrc）
├── init.zsh                [TEMPLATE] 交互式配置 -> ~/.zsh/init.zsh
├── templates/              [TEMPLATE] mise 全局配置、~/.zsh_secrets 空白模板
├── rex/                    [TEMPLATE] 终端调色板 + Workspace.* 外观设置
├── starship/ yazi/ atuin/ bat/ btop/ ripgrep/ infat/   [TEMPLATE] 工具配置
├── vscode/settings.json    [TEMPLATE] 主题 + 字体 + 基础项（合并到本机）
├── git/                    [TEMPLATE] git 通用配置（include 引用）与全局 ignore
├── debug/profile.zsh       ZSH_PROFILE=1 启用的启动 timing 调试
├── .pre-commit-config.yaml 提交前 gitleaks 扫描
├── CLAUDE.md               AI 协作规则与部署说明
└── README.md               本文件
```

## 常用别名

| 别名 | 说明 |
|---|---|
| `ls` / `ll` / `lt` | eza（现代 ls） |
| `hh` | atuin 历史搜索 |
| `lg` | lazygit |
| `y` | yazi（退出时切到 cwd） |
| `k` 系列 | kubectl 快捷（kgp / kl / kaf 等，详见 init.zsh） |
| `rm` | 放进废纸篓（真删用 `command rm`） |

## 修改仓库

修改前明确告知 AI："这是 MAINTAINER 模式，修改仓库 X。"边界见 CLAUDE.md「AI 角色边界」与「敏感信息」：仓库公开，不提交密钥、账号、公司和内网信息、本机路径。

| 想改什么 | 编辑哪 | 生效方式 |
|---|---|---|
| 别名 / 函数 / 工具激活 / prompt | `init.zsh` | `bin/deploy.sh sync` |
| zim 插件 | `zsh/zimrc` | `bin/deploy.sh sync` + `zimfw install` |
| 环境变量 / PATH | `zsh/zshenv`（保留占位符） | `bin/deploy.sh sync` |
| 软件 | `brew/<模块>.Brewfile`；新模块还要加进 `bin/setup.sh` 的 `MODULES` | `bin/setup.sh` |
| 全局 mise 工具 | `templates/mise_config.toml` | `bin/setup.sh --storage-root <ROOT>` |
| 工具配置 | `starship/`、`yazi/`、`atuin/` 等 | `bin/deploy.sh sync`（本机已有文件时按 `differs` 提示处理） |
| 终端外观 | `rex/workspace.defaults`、`rex/themes/` | `bin/apply-rex-defaults.sh` / `bin/deploy.sh sync` |
| 全局提示词 / skills / hooks | `ai/AGENTS.md`、`ai/skills/`、`ai/claude/hooks/` | 已链接的文件即时生效；增删文件跑 `bin/setup-ai.sh` |
| MCP | `ai/claude/mcp.json` + `ai/opencode/opencode.jsonc` 的 `mcp` 段（两边同步），新密钥变量加进 `templates/zsh_secrets.template` | `bin/setup-ai.sh` + `opencode service restart` |
| Git 通用配置 | `git/config` | 自动生效 |

## 调试

```bash
# 测 zsh 启动 timing
ZSH_PROFILE=1 zsh -i -l -c exit
```

长期开启时在 `~/.zshenv` 加一行 `export ZSH_PROFILE=1` 再开新窗口，输出 `[prof*]` 行；用完删掉那行。详见 `debug/profile.zsh` 顶部说明。
