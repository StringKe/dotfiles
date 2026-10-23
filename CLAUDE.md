# CLAUDE.md

本仓库是 macOS 开发环境的配置模板，面向用户的说明在 README.md。本文件给 AI：角色边界、部署流程、每个文件部署到哪、各项设计约束。

## 仓库与部署产物

仓库里的文件是模板。`bin/deploy.sh` 把它们复制到 home，`zsh/zshenv` 和 `templates/mise_config.toml` 复制时替换占位符。用户 shell 读的是 home 里的部署产物，不读仓库。

三处例外直接指向仓库：

- `git/config`：`~/.gitconfig` 用 `[include]` 引用，改了立即对所有机器生效。
- `ai/`：`bin/setup-ai.sh` 把全局提示词、rules、hooks、statusline、skills、插件和 opencode 配置符号链接到 home。编辑 `~/.claude/CLAUDE.md` 等于改仓库，其他会话的改动会出现在本仓库的 `git status` 里。
- `debug/profile.zsh`：`ZSH_PROFILE=1` 时由 `~/.zshenv` 直接从仓库 source。

安装与配置的总入口是 `bin/setup.sh`，按模块调用 `brew bundle`、`deploy.sh`、`setup-ai.sh` 等脚本。

## 角色边界（HARD RULES）

进入本仓库先确定角色。不确定时默认 CONSUMER，并问用户：「这是部署到本机，还是修改仓库？」

### CONSUMER：部署 / 更新 / 验证

用户说「初始化新机器」「重新部署」「换存储位置」「拉最新版本」时。

允许：
- 读仓库任何文件
- 运行 `bin/` 下的脚本，以及 `brew` / `zimfw` / `mise` / `git pull --ff-only`
- 修改 home 里的部署产物

禁止（违反立即停止）：
- `git add` / `commit` / `push`，在仓库里新建或修改任何文件
- 修改 home 里指向 `$DOTFILES_ROOT/ai` 的符号链接（如 `~/.claude/CLAUDE.md`、`~/.config/opencode/opencode.jsonc`），它们是仓库文件
- 把部署版的绝对路径写回模板，或自己写 sed 替换占位符
- `brew bundle cleanup`（含 `--force`）：`brew/*.Brewfile` 不是本机软件全集，cleanup 会卸掉所有不在清单里的软件。清孤儿用 `brew autoremove`，单个卸载用 `brew uninstall`

`bin/setup-ai.sh` 会在仓库 `.git/hooks` 装 pre-commit hook，这是 CONSUMER 唯一会写入仓库目录的操作。

### MAINTAINER：修改仓库

用户明确说「修改仓库」「添加功能」「提交」时。可以改模板、脚本、文档；用户说「提交」后再 commit / push。

禁止：把部署版绝对路径写回模板（保留 `__STORAGE_ROOT__` / `__DOTFILES_ROOT__`）；在模板里写本机信息（见「敏感信息」）；把 `~/.zsh_secrets` 的内容写回 `templates/zsh_secrets.template`。

## 部署流程（CONSUMER）

1. **找仓库**：依次检查 `$HOME/Code/SelfCode/dotfiles`、`/Volumes/Storage/Code/SelfCode/dotfiles` 是否有 `bin/setup.sh`。都没有就让用户按 README「快速开始」clone。
2. **判断场景**：读 `~/.zshenv`。
   - 不存在或含未替换占位符 -> 首次部署。
   - 已部署 -> 问用户：新机器初始化 / 原样重跑 / 换存储位置 / 应用新版本。
   - `CURRENT_ROOT` = `~/.zshenv` 里 `CODE_LANGUAGES_HOME` 去掉末尾 `/Languages`。`NEW_ROOT` 必须是绝对路径，不接受 `~` 或 `$HOME` 字面。
3. **执行**：

| 场景 | 动作 |
|---|---|
| 首次部署 | 和用户确认模块，`bin/setup.sh --modules <...> --storage-root NEW_ROOT` |
| 原样重跑 | `bin/setup.sh --storage-root CURRENT_ROOT`（沿用 `~/.config/dotfiles/modules`） |
| 换存储位置 | 先迁数据：列出源、目标、大小、是否跨卷，用户确认后 `df -h` 看空间，逐目录 `mv`（目标已存在就停下问），用户确认新位置可用后再清旧位置。然后 `bin/setup.sh --storage-root NEW_ROOT` |
| 应用新版本 | `git fetch`；`git log HEAD..origin/main` 为空就结束；工作区不干净先让用户处理；`git pull --ff-only` 后 `bin/setup.sh` |

AI 运行时 stdin 不是终端：`setup.sh` 不进选择界面，要用 `--modules` 或沿用已保存的模块；git 身份、改默认 shell 这类需要输入的步骤会跳过并给出手动命令。

4. **验证**：`bin/deploy.sh check` 必须 PASS。另外确认 `claude mcp list` 与 `opencode mcp list` 列出 `ai/claude/mcp.json` 的全部 MCP 且已连接；`deploy.sh sync` 输出的 `differs` 行逐个问用户是否换回仓库版（`trash` 本机文件后再 sync）。

## 部署目标对照

| 仓库文件 | 部署到 | 覆盖策略 | 改动后要跑 |
|---|---|---|---|
| `zsh/zshenv` | `~/.zshenv` | init / sync 覆盖，替换占位符 | `bin/deploy.sh sync` |
| `zsh/zshrc`、`zsh/zprofile`、`init.zsh` | `~/.zshrc`、`~/.zprofile`、`~/.zsh/init.zsh` | init / sync 覆盖 | `bin/deploy.sh sync` |
| `zsh/zimrc` | `~/.zimrc` | init / sync 覆盖 | `bin/deploy.sh sync` + `zimfw install` |
| `templates/mise_config.toml` | `~/.config/mise/config.toml` | 只有 init 覆盖，替换占位符 | `bin/setup.sh --storage-root <ROOT>` |
| `templates/zsh_secrets.template` | `~/.zsh_secrets` | 只在不存在时复制，权限 600 | 对比变量名，缺的让用户补，不输出值 |
| `rex/themes/*`、`btop/themes/*`、`infat/config.toml` | `~/.config/` 对应路径 | init / sync 覆盖 | `bin/deploy.sh sync`；infat 再跑 `bin/apply-file-associations.sh` |
| `rex/workspace.defaults` | defaults 域 `com.superlogical.rex` 的 `Workspace.*` | 每次覆盖 | `bin/apply-rex-defaults.sh`，重启 Rex |
| `starship/`、`btop/btop.conf`、`yazi/`、`atuin/`、`bat/`、`ripgrep/`、`git/ignore` | `~/.config/` 对应路径 | 只在不存在时复制；不同时 sync 提示 `differs` | `bin/deploy.sh sync` |
| `vscode/settings.json` | VS Code 用户 settings.json | init 时 jq 深合并（本机字段保留，同名键以仓库为准）；本机文件含注释时列出要手工同步的键 | `bin/setup.sh --storage-root <ROOT>` |
| `git/config` | `~/.gitconfig` 的 `[include]` | 不复制 | 无 |
| `brew/<模块>.Brewfile` | `brew bundle` 直接读 | 按选中的模块安装 | `bin/setup.sh`；新模块还要加进 `setup.sh` 的 `MODULES` |
| `ai/AGENTS.md` | `~/.claude/CLAUDE.md`、`~/.config/opencode/AGENTS.md` | 符号链接 | 无 |
| `ai/claude/rules/*`、`hooks/*`、`statusline-command.sh` | `~/.claude/` 同名路径 | 符号链接 | 增删文件时 `bin/setup-ai.sh` |
| `ai/skills/*` | `~/.agents/skills/`、`~/.claude/skills/`、`~/.config/opencode/skills/` | 符号链接 | 增删时 `bin/setup-ai.sh` |
| `ai/plugins/*` | 整个插件到 `~/.agents/plugins/`；插件内每个 skill 到 claude 与 opencode 的 skills 目录 | 符号链接 | 增删时 `bin/setup-ai.sh` |
| `ai/opencode/*` | `~/.config/opencode/` | 符号链接 | `opencode service restart` |
| `ai/claude/settings.json` | `~/.claude/settings.json` | jq 深合并 | `bin/setup-ai.sh` |
| `ai/claude/mcp.json` | `~/.claude.json` 的 user 级 `mcpServers` | 每次重建同名条目；`${HOME}` 展开，密钥保留 `${VAR}`；缺密钥的跳过 | `bin/setup-ai.sh` |
| `.pre-commit-config.yaml` | 仓库 `.git/hooks` | `setup-ai.sh` 执行 `pre-commit install` | 无 |

仓库里删除或改名的 ai 条目，重跑 `setup-ai.sh` 会清掉对应的旧链接。

## zsh 与 PATH

加载顺序：`~/.zshenv`（所有 shell：环境变量、PATH、source `~/.zsh_secrets`）-> `~/.zprofile`（登录 shell：brew shellenv 后恢复 PATH，非交互用 mise shims）-> `~/.zshrc`（交互 shell：zimfw 引导，再 source `~/.zsh/init.zsh`）。

- PATH 只在 `zsh/zshenv` 的 `_dotfiles_setup_path` 维护。`~/.zprofile` 在 `path_helper` 和 `brew shellenv` 之后再调一次，否则登录 shell 会把 `/usr/bin` 排到 keg-only 前面。
- PATH 顺序（先到的赢）：用户 CLI 与语言目录 -> 必须盖住系统的 keg-only（ffmpeg-full、mysql-client、macos-trash、libpq、curl、sqlite、icu4c）-> `$HOMEBREW_PREFIX/bin` -> 系统路径 -> llvm、ncurses、libarchive 和 Vite+ `bin`（只为 `vp`，它的 node / npm shim 不能盖住 mise）。
- coreutils 的 gnubin 不放在 `/usr/bin` 前面：GNU 的 stat / date / mktemp 会让 opencode 的安装脚本失败。
- `JAVA_HOME` 由 mise 的 java 设置；python 走 mise / uv；llvm 不进全局 `LDFLAGS`。
- 安装器往 `~/.zshrc` / `~/.zprofile` 追加的片段会在部署时被覆盖，需要的 PATH 加进 `_dotfiles_setup_path`。
- Claude Code 的 Bash 工具用交互 zsh 的快照执行命令。`init.zsh` 检测到 `CLAUDECODE` 时关掉 `NOMATCH` / `EQUALS`、打开 `CLOBBER`，不让 zoxide 接管 `cd`，不设 `ls -> eza` 别名。改动只对新开的 Claude Code 会话生效。
- mise 全局工具在 `templates/mise_config.toml`，`init` 会覆盖本机 `mise use -g` 的改动；项目专用版本写进项目的 `mise.toml`。

## 占位符

| 占位符 | 替换为 | 用于 |
|---|---|---|
| `__STORAGE_ROOT__` | 存储根绝对路径 | `CODE_LANGUAGES_HOME` 与 mise 的 `[env]` |
| `__DOTFILES_ROOT__` | 仓库绝对路径 | `DOTFILES_ROOT` |

只由 `bin/deploy.sh` 替换。路径不能含 `&`、`|`、`\`，脚本会拒绝。

## Git 签名

`git/config` 定义：SSH 签名（`gpg.format = ssh`，`gpg.ssh.program` 指向 1Password），`commit.gpgsign = true`，GitHub credential 走 `gh auth git-credential`，清空 `core.askPass`，`safe.directory = *`。`[user]` 身份和 `signingkey` 写在本机 `~/.gitconfig`，由 setup.sh 的 git 模块询问。

agent 的每条命令都是新进程，经 1Password 签名会每次弹授权。本机有同一把 key 的私钥时，可在本机 `~/.gitconfig` 改 `gpg.ssh.program = ssh-keygen`、`user.signingkey = <私钥路径>`，并在 `~/.ssh/config` 的 `Host github.com` 设 `IdentityAgent none` 和 `IdentityFile`。这些只写本机文件。

## 配色

统一用 GitHub Light Colorblind：橙色 #b35900 代替红色，蓝色 #0969da / 紫色 #8250df 代替绿色。

| 工具 | 做法 |
|---|---|
| Rex | `rex/workspace.defaults` 选内置 `merino-light`；`rex/themes/GitHub Light Colorblind`（Ghostty 格式调色板）随部署复制，可在 Rex 设置里换用 |
| starship、bat、fzf、atuin | 不写死颜色，跟随终端 ANSI 配色 |
| yazi | `yazi/theme.toml` 用 ANSI 颜色名 |
| btop | `btop/themes/` 自带主题文件 |
| VS Code | `GitHub Light Colorblind (Beta)`，扩展经 Settings Sync 安装 |

## AI 配置

- AI CLI 只装 claude-code 和 opencode v2（`bin/install-ai-cli.sh`，官方安装脚本）。grok-build 本机另装，仓库只负责加载它的 `~/.grok/privacy.env`。
- 全局提示词只有 `ai/AGENTS.md` 一份，claude-code 与 opencode 都链接到它。个人 skill 放 `ai/skills/<名>/`，个人插件放 `ai/plugins/<名>/`。
- MCP 两边保持同一组：context7、exa、gh_grep、openseo、sentry、fingerprint、rea、paper。claude-code 的定义在 `ai/claude/mcp.json`，opencode 的在 `ai/opencode/opencode.jsonc` 的 `mcp` 段，改一边要同步另一边。
- MCP 一律用 API key / token，不走 OAuth，也不装同名插件：多个会话同时刷新 OAuth token 时容易失效，导致反复要求登录。sentry 用 `Authorization: Sentry-Bearer <token>`；fingerprint 的托管端点只支持 OAuth，改用 mise 安装的本地 `fingerprint-mcp-server`（private 模式，`--region ap`）。
- 密钥只按变量名引用：claude-code 写 `${VAR}`，opencode 写 `{env:VAR}`。变量清单在 `templates/zsh_secrets.template`，值在 `~/.zsh_secrets`。缺密钥的 MCP 由 `setup-ai.sh` 跳过。
- paper MCP 用 Paper 应用自带的 `~/.paper/bin/paper`；rea 的 Hopper 集成需要 `~/Applications/Hopper Disassembler.app`。
- `~/.claude/settings.json` 的 `processWrapper` 是本机路径，不进仓库，合并时保留。
- 第三方 skill 不进仓库：Rex 用 `rex skill setup`（setup-ai 会调用），ego-browser 链接到 ego lite 自带目录，lark / impeccable / reverse-engineer-anything 用各自的安装器。

## 敏感信息

仓库公开。不提交密钥、账号、公司和内网信息、本机绝对路径、私有项目名。

- 个人账号相关的配置留在本机：opencode 的模型 provider 放 `~/.config/opencode/opencode.json`（与链接进来的 `opencode.jsonc` 合并加载）；只适用本机的 agent 规则放 `~/.claude/rules/` 下的非仓库文件。
- `~/.zsh_secrets` 在仓库外；`.gitignore` 里的 `.zsh_secrets` 防止把副本误放进仓库。
- 提交前 pre-commit 跑 gitleaks。已推送的历史不改写；历史里发现凭据时轮换凭据。
