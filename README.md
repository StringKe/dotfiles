# dotfiles

macOS 开发环境配置的**只读模板仓库**。

仓库内文件是模板源，通过 `bin/deploy.sh` 复制（+ 占位符替换）到用户 home。例外：`git/config` 由 `~/.gitconfig` 的 `[include]` 引用；`ai/` 下的 AI 配置由 `bin/setup-ai.sh` 符号链接到 home；`debug/profile.zsh` 只在调试时从仓库直接 source。

终端用 Rex Beta（无 brew cask，安装见 https://www.superlogical.com/rex/docs/installation）。终端工具和 VS Code 用 **GitHub Light Colorblind** 配色（橙色替代红，蓝色替代绿，避免红绿色盲混淆）；多数工具跟随终端 ANSI 配色，Rex 当前选的是内置 `merino-light`，仓库附带的 `rex/themes/GitHub Light Colorblind` 可在 Rex 设置里切换。

AI 协作规则、部署目标对照和各配置的设计说明见 [CLAUDE.md](CLAUDE.md)。

## 前置准备

```bash
# 1. Xcode CLT
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. 克隆仓库
mkdir -p /Volumes/Storage/Code/SelfCode
git clone https://github.com/StringKe/dotfiles.git /Volumes/Storage/Code/SelfCode/dotfiles
```

## 部署

按顺序执行。STORAGE_ROOT 是存放 `Code/` 与 `Languages/` 的绝对路径（如 `/Volumes/Storage` 或 `$HOME` 的字面展开）。

```bash
cd /Volumes/Storage/Code/SelfCode/dotfiles

# 1. zsh 入口、mise 与工具配置、VS Code 设置、~/.gitconfig include、~/.zsh_secrets 模板
bin/deploy.sh init /Volumes/Storage

# 2. 软件
brew bundle install --file=$PWD/Brewfile

# 3. git 身份与签名（git/config 要求 commit 签名）
#    signingkey 填 1Password 里那把 SSH key 的公钥全文，并在 1Password Settings -> Developer 开启 SSH agent；
#    不用 1Password 时按 CLAUDE.md「Git 签名」在本机 ~/.gitconfig 覆盖为本地私钥
git config --global user.name  "<name>"
git config --global user.email "<email>"
git config --global user.signingkey "<ssh 公钥>"

# 4. 新 shell 加载环境变量与 PATH，再装 zsh 模块和语言运行时
exec zsh
zimfw install
mise install

# 5. 按 templates/zsh_secrets.template 在 ~/.zsh_secrets 填 MCP 的 key / token

# 6. AI CLI（claude-code / opencode v2），新 shell 让 ~/.local/bin 进 PATH，再部署提示词 / skills / hooks / 插件 / MCP
bin/install-ai-cli.sh
exec zsh
bin/setup-ai.sh

# 7. 文件关联、Rex 外观（重启 Rex App 生效）
bin/apply-file-associations.sh
bin/apply-rex-defaults.sh

# 8. 默认 shell
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh

# 9. 验证
bin/deploy.sh check
```

部署后改了模板或拉了新版本：`bin/deploy.sh sync` 同步 zsh 入口和工具配置；其他文件改动后要跑什么，见 CLAUDE.md「部署目标对照」的「改动后要跑」列。

## 通过 AI 部署 / 更新

把下面的提示词发给 AI 助手（Claude Code / opencode 等）：

````
帮我部署或更新 dotfiles。仓库已克隆到本机（依次找 $HOME/Code/SelfCode/dotfiles、/Volumes/Storage/Code/SelfCode/dotfiles，记为 DOTFILES_ROOT）。
先完整读 DOTFILES_ROOT/CLAUDE.md，按其中的 CONSUMER 模式和「部署场景」执行：判定首次部署 / 重配 / 迁移 / 更新，命令清单以 DOTFILES_ROOT/README.md「部署」为准。
不修改、不提交仓库文件。迁移数据、覆盖本机已有配置前先给我看清单再执行。
最后跑 bin/deploy.sh check，报告每项 PASS / FAIL。
````

## 仓库结构

```
dotfiles/
├── bin/
│   ├── deploy.sh                      部署主脚本（init / sync / check）
│   ├── apply-file-associations.sh     infat + duti 文件关联
│   ├── apply-rex-defaults.sh          Rex Workspace.* 外观设置
│   ├── install-ai-cli.sh              claude-code / opencode v2 官方 curl 安装
│   └── setup-ai.sh                    AI 提示词 / skills / hooks / 插件 / MCP 部署
├── ai/                     [LINKED] AI 配置，符号链接到 ~（settings.json 走 jq 合并，MCP 走 claude mcp add-json）
│   ├── AGENTS.md           全局提示词（Claude Code 与 opencode 共用）
│   ├── claude/             rules / hooks / statusline / settings.json / mcp.json
│   ├── opencode/           opencode.jsonc（MCP、权限）/ tui.json
│   ├── skills/             个人 skills
│   └── plugins/            个人插件（worktree）
├── debug/profile.zsh       ZSH_PROFILE=1 启用的启动 timing 调试
├── zsh/                    [TEMPLATE] zsh 入口（zshenv / zprofile / zshrc / zimrc）
├── init.zsh                [TEMPLATE] 交互式配置 -> ~/.zsh/init.zsh
├── templates/              [TEMPLATE] mise 全局配置、~/.zsh_secrets 空白模板
├── rex/                    [TEMPLATE] 终端调色板 + Workspace.* 外观设置
├── starship/               [TEMPLATE] 提示符
├── btop/                   [TEMPLATE] 系统监控配置与主题
├── yazi/                   [TEMPLATE] 文件管理器
├── atuin/                  [TEMPLATE] 历史搜索
├── bat/                    [TEMPLATE] cat 替代
├── ripgrep/                [TEMPLATE] grep 替代
├── infat/                  [TEMPLATE] 文件关联
├── vscode/settings.json    [TEMPLATE] 主题 + 字体 + 基础项（jq 合并到本机）
├── git/                    [TEMPLATE] git 通用配置（include 引用）与全局 ignore
├── Brewfile                软件清单
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
| `aiupdate` | 更新 claude-code 与 opencode |

## 修改仓库（MAINTAINER）

修改仓库内容前明确告知 AI："这是 MAINTAINER 模式，修改仓库 X。"边界见 CLAUDE.md「AI 角色边界」与「敏感信息」。

| 想改什么 | 编辑哪 | 同步方式 |
|---|---|---|
| 别名 / 函数 / 工具激活 / prompt | `init.zsh` | `bin/deploy.sh sync` |
| zim 插件列表 | `zsh/zimrc` | `bin/deploy.sh sync` + `zimfw install` |
| 环境变量 / PATH | `zsh/zshenv`（**保留占位符**） | `bin/deploy.sh sync` |
| 全局 mise 工具 | `templates/mise_config.toml` | `bin/deploy.sh init <ROOT>` + `mise install` |
| 软件清单 | `Brewfile` | `brew bundle install` |
| 终端外观 | `rex/workspace.defaults`、`rex/themes/` | `bin/apply-rex-defaults.sh` / `bin/deploy.sh sync` |
| 提示符等工具配置 | `starship/`、`yazi/`、`atuin/` 等 | `bin/deploy.sh sync`（本机已有文件时按 `differs` 提示处理） |
| 全局提示词 / skills / hooks | `ai/AGENTS.md`、`ai/skills/`、`ai/claude/hooks/` | 已链接的文件即时生效；新增或删除文件跑 `bin/setup-ai.sh` |
| MCP | `ai/claude/mcp.json` + `ai/opencode/opencode.jsonc` 的 `mcp` 段（两边同步），新密钥变量加进 `templates/zsh_secrets.template` | `bin/setup-ai.sh` + `opencode service restart` |
| Git 通用配置 | `git/config` | 自动生效（`[include]` 引用） |

## 调试

```bash
# 测启动 timing
ZSH_PROFILE=1 zsh -i -l -c exit
```

长期开启时在 `~/.zshenv` 加一行 `export ZSH_PROFILE=1` 再开新窗口，输出 `[prof*]` 行；用完删掉那行。详见 `debug/profile.zsh` 顶部说明。
