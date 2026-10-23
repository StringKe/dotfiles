# CLAUDE.md

本仓库是 macOS 开发环境配置的**只读模板**。本文档定义 AI 在本仓库内工作时的角色、边界和部署流程。安装与配置统一走 `bin/setup.sh`（按模块，模块清单见 README「模块」）。

## 仓库定位（重要）

**本仓库 ≠ 用户的 home 配置**。

- 仓库内所有 `zsh/*` / `rex/*` / `starship/starship.toml` / `templates/*` 等都是**模板源**。
- 实际生效的是 `~/.zshenv` / `~/.config/...` 等用户 home 内的**部署产物**。
- 部署通过 `bin/deploy.sh` 完成（复制 + sed 替换占位符），仓库内文件不直接被用户 shell 读取（例外见下）。

**例外**:

- `git/config` 通过 `~/.gitconfig` 的 `[include] path` 引用，不复制。修改即对所有引用它的机器生效。
- `ai/` 下的全局提示词、rules、hooks、statusline、个人 skills、个人插件和 opencode 配置由 `bin/setup-ai.sh` 符号链接到 `~`。在 `~/.claude/CLAUDE.md` 等位置的编辑会直接改到仓库，其他会话改了这些文件会在本仓库显示为未提交改动。
- `debug/profile.zsh` 由部署版 `~/.zshenv` 在 `ZSH_PROFILE=1` 时直接从仓库 source，不复制。

## AI 角色边界（HARD RULES）

AI 进入本仓库时，必须先确定属于哪个角色：

### CONSUMER 模式 - 部署 / 升级 / 验证

触发场景：用户要"初始化新机器" / "重新部署 dotfiles" / "切换存储位置" / "拉最新更新到本机"。

允许：
- 读仓库任何文件
- 调用 `bin/setup.sh` / `bin/deploy.sh` / `bin/install-ai-cli.sh` / `bin/setup-ai.sh` / `bin/apply-file-associations.sh` / `bin/apply-rex-defaults.sh`
- 修改 `~` 内的部署产物（`~/.zshenv` / `~/.config/...`）
- 运行 `brew bundle install` / `zimfw install` / `mise install` / `git pull --ff-only` 等外部工具

**禁止（违反立即停止）**：
- `git add` / `git commit` / `git push` 操作仓库
- 在仓库内新建任何文件（含临时脚本 / patch / .env / 备份）
- 修改仓库内任何文件（含"改一下 zsh/zshenv 适配本机"）
- 修改 `~` 下指向 `$DOTFILES_ROOT/ai` 的符号链接（如 `~/.claude/CLAUDE.md`、`~/.config/opencode/opencode.jsonc`），它们是仓库文件
- 把部署版的绝对路径（如 `/Volumes/Storage/...`）回写到 `zsh/zshenv` 模板
- 自己写 sed 做占位符替换（必须调用 `bin/deploy.sh`）
- **`brew bundle cleanup` 含 `--force`**：`brew/*.Brewfile` 是按模块拆分的模板而非本机全集，cleanup 会卸光本机所有未在模板里的软件（包括 MAS、第三方 tap、手动 brew install）。清理孤儿用 `brew autoremove`；单独卸用 `brew uninstall <名>`。AI 提及"清理 brew"任何场景，都要先确认非 cleanup 命令

`bin/setup-ai.sh` 会执行 `pre-commit install`，在仓库 `.git/hooks` 写入 gitleaks hook。这是 CONSUMER 模式下唯一会写入仓库目录的操作。

### MAINTAINER 模式 - 功能开发 / 演进

触发场景：用户明确说"修改仓库" / "添加 X 功能" / "提交" / "演进 dotfiles"。

允许：
- 编辑仓库内任何模板文件、`bin/*` 脚本和文档
- 编辑后 `git add` / `git commit` / `git push`（仅当用户明确说"提交"）

**禁止**：
- 把部署版绝对路径回写到模板（必须保持 `__STORAGE_ROOT__` / `__DOTFILES_ROOT__` 占位符）
- 在模板里嵌入本机特有信息（账号、密钥、机器名、内网信息，见「敏感信息」）
- 把 `~/.zsh_secrets` 等敏感文件内容回写到 `templates/zsh_secrets.template`

### 模式不清时

如果不确定属于哪个角色，**默认 CONSUMER**（只读仓库），并询问用户："这是部署到本机，还是修改仓库功能？"

## 部署场景（CONSUMER）

### 1. 定位 DOTFILES_ROOT

依次检测含 `bin/setup.sh` 的目录：`$HOME/Code/SelfCode/dotfiles`、`/Volumes/Storage/Code/SelfCode/dotfiles`。均无则让用户按 README「快速开始」先 clone。

### 2. 判定场景

读 `~/.zshenv`：

- 不存在，或含未替换的占位符 -> 场景 A 首次部署
- 已部署 -> 询问用户意图：
  - 新机器初始化 -> 场景 A
  - 原样重跑修复 -> 场景 B 重配
  - 换存储位置（如从 `$HOME` 搬到 `/Volumes/Storage`）-> 场景 C 迁移
  - 拉了新版本要应用 -> 场景 D 更新

`CURRENT_ROOT` 取 `~/.zshenv` 中 `CODE_LANGUAGES_HOME` 去掉末尾 `/Languages`（与 `bin/deploy.sh sync` 的取法一致）。场景 A/B/C 需要 `NEW_ROOT`：候选 `/Volumes/Storage` 或 `$HOME` 的绝对值，必须是绝对路径，不接受 `~` 或 `$HOME` 字面。

| 场景 | 条件 | 动作 |
|---|---|---|
| A 首次 | 无 CURRENT_ROOT | 和用户确认模块后 `bin/setup.sh --modules <...> --storage-root NEW_ROOT` |
| B 重配 | CURRENT_ROOT == NEW_ROOT | `bin/setup.sh --storage-root NEW_ROOT`（沿用 `~/.config/dotfiles/modules` 里的模块） |
| C 迁移 | CURRENT_ROOT != NEW_ROOT | 先迁数据（见 3），再同 B |
| D 更新 | 已部署 | 见 4 |

AI 运行时 stdin 不是终端，`bin/setup.sh` 不会进交互选择，必须用 `--modules` 指定或沿用已保存的模块；`git`、`shell` 模块里需要输入的步骤会跳过并提示手动命令。

### 3. 数据迁移（仅场景 C）

先输出迁移分析表（源 / 目标 / 大小 / 是否跨卷），用户确认后：`df -h` 看目标卷剩余 -> `mkdir -p NEW_ROOT` -> 逐目录 `mv`（目标已存在则停下询问）-> 让用户验证新位置可用后再自行清理旧位置。

### 4. 更新（场景 D）

1. `git fetch origin`，`git log --oneline HEAD..origin/main` 为空则已是最新，结束。
2. 工作区有未提交改动时告知用户先处理，不强行覆盖；否则 `git pull --ff-only origin main`。
3. 跑 `bin/setup.sh`（沿用已保存的模块）。它覆盖了下面「部署目标对照」表的全部动作；只想做局部同步时按表的「改动后要跑」列单独执行。
4. 跑 5 的验证。

### 5. 验证

`bin/deploy.sh check` 必须 PASS（它校验 zsh/mise/git 文件、占位符、Rex 主题、infat、`~/.zsh_secrets` 权限；选了 ai 模块时还校验 `~/.claude/CLAUDE.md` 链接和 MCP 注册）。另外确认：

- `~/.zim/modules/` 含 zimrc 里声明的模块
- `claude mcp list` 与 `opencode mcp list` 列出 `ai/claude/mcp.json` 里的全部 MCP 且已连接（paper 需要已装 Paper 应用，rea 的 Hopper 工具需要已装 Hopper）
- `bin/deploy.sh sync` 输出里的 `differs` 行：本机配置与仓库不同，问用户是否用仓库版（`trash` 本机文件后再 sync）

## 部署目标对照

| 仓库文件 | 部署目标 | 覆盖策略 | 改动后要跑 |
|---|---|---|---|
| `zsh/zshenv` | `~/.zshenv` | init / sync 覆盖，sed 替换占位符 | `bin/deploy.sh sync` |
| `zsh/zshrc`、`zsh/zprofile`、`init.zsh` | `~/.zshrc`、`~/.zprofile`、`~/.zsh/init.zsh` | init / sync 覆盖 | `bin/deploy.sh sync` |
| `zsh/zimrc` | `~/.zimrc` | init / sync 覆盖 | `bin/deploy.sh sync` + `zimfw install` |
| `templates/mise_config.toml` | `~/.config/mise/config.toml` | 仅 init 覆盖，sed 替换占位符 | `bin/deploy.sh init <CURRENT_ROOT>` + `mise install` |
| `templates/zsh_secrets.template` | `~/.zsh_secrets` | 仅首次，复制 + chmod 600 | 对比变量名，缺的让用户补，不输出值 |
| `rex/themes/GitHub Light Colorblind` | `~/.config/rex/themes/` 同名文件 | init / sync 覆盖 | `bin/deploy.sh sync` |
| `rex/workspace.defaults` | defaults 域 `com.superlogical.rex` 的 `Workspace.*` | 每次覆盖 | `bin/apply-rex-defaults.sh`，重启 Rex App |
| `btop/themes/*.theme` | `~/.config/btop/themes/` | init / sync 覆盖 | `bin/deploy.sh sync` |
| `infat/config.toml` | `~/.config/infat/config.toml` | init / sync 覆盖 | `bin/deploy.sh sync` + `bin/apply-file-associations.sh` |
| `starship/starship.toml`、`btop/btop.conf`、`yazi/*.toml`、`atuin/config.toml`、`bat/config`、`ripgrep/config`、`git/ignore` | `~/.config/` 对应路径 | 仅不存在时复制；已存在且不同时 sync 输出 `differs` | `bin/deploy.sh sync`，按 `differs` 提示处理 |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` | init 时 jq 深合并（本地字段保留，同名 key 覆盖）；本机文件含注释时列出要手工同步的键 | `bin/deploy.sh init <CURRENT_ROOT>` |
| `git/config` | （不复制）`~/.gitconfig` 的 `[include]` | 自动生效 | 无 |
| `brew/<模块>.Brewfile` | （不复制）`brew bundle` 直接读 | 按选中的模块安装 | `bin/setup.sh`；新增模块要同时加进 `bin/setup.sh` 的 `MODULES` |
| `bin/install-ai-cli.sh` | （不复制） | 重跑即更新 | `bin/install-ai-cli.sh` |
| `ai/AGENTS.md` | `~/.claude/CLAUDE.md`、`~/.config/opencode/AGENTS.md` | setup-ai 符号链接 | 无（已链接即时生效） |
| `ai/claude/rules/*`、`ai/claude/hooks/*`、`ai/claude/statusline-command.sh` | `~/.claude/` 同名路径 | setup-ai 符号链接 | 新增或删除文件时 `bin/setup-ai.sh` |
| `ai/skills/*` | `~/.agents/skills/`、`~/.claude/skills/`、`~/.config/opencode/skills/` | setup-ai 符号链接 | 新增或删除时 `bin/setup-ai.sh` |
| `ai/plugins/*` | 整个插件到 `~/.agents/plugins/`；插件内每个 skill 到 `~/.claude/skills/` 与 `~/.config/opencode/skills/` | setup-ai 符号链接 | 新增或删除时 `bin/setup-ai.sh` |
| `ai/opencode/*` | `~/.config/opencode/` | setup-ai 符号链接 | `opencode service restart` |
| `ai/claude/settings.json` | `~/.claude/settings.json` | jq 深合并 | `bin/setup-ai.sh` |
| `ai/claude/mcp.json` | `~/.claude.json` 的 user 级 `mcpServers` | 每次重建同名条目；`${HOME}` 部署时展开，密钥保留 `${VAR}`；缺密钥的跳过 | `bin/setup-ai.sh` |
| `.pre-commit-config.yaml` | 仓库 `.git/hooks` | setup-ai 执行 `pre-commit install` | 无 |
| `debug/profile.zsh`、文档 | （不部署） | - | 无 |

## Shell 加载顺序

```
~/.zshenv      所有 shell             环境变量 / PATH（含 keg-only 与用户 CLI）/ DOTFILES_ROOT / source ~/.zsh_secrets
~/.zprofile    登录 shell（zshrc 前）  brew shellenv（HOMEBREW_*）后恢复 PATH；非交互 mise shims
~/.zshrc       交互式 shell            zimfw 引导 -> source ~/.zsh/init.zsh
  ~/.zimrc     由 zimfw 读取            zim 模块列表（见 zsh/zimrc）
  ~/.zsh/init.zsh                      交互式配置（部署版 init.zsh）
```

PATH 只在 `zsh/zshenv` 的 `_dotfiles_setup_path` 维护。`~/.zprofile` 在 `path_helper` 和 `brew shellenv` 之后再调一次该函数，否则登录壳会把 `/usr/bin` 抬到 keg-only 前面。brew caveats 和安装器 `echo >> ~/.zshrc` 的片段部署时会被覆盖，不要手动留在 `~/.zshrc` / `~/.zprofile`。

Claude Code 的 Bash 工具从交互 zsh 生成 shell 快照（setopt、alias、函数都会带进去），再 `eval` 命令。`init.zsh` 用 `CLAUDECODE` 区分：该环境下关 `NOMATCH` / `EQUALS`、开 `CLOBBER`，不启用 zoxide 接管 `cd` 和 `ls -> eza` alias。改这些后只对新开的 Claude Code 会话生效。

PATH 分层（先到的赢）：

1. 用户 CLI 与语言目录
2. 必须盖住系统的 keg-only：`ffmpeg-full` / `mysql-client` / `macos-trash` / `libpq` / `curl` / `sqlite` / `icu4c`
3. `$HOMEBREW_PREFIX/bin`
4. `/usr/bin` 等系统路径
5. 系统之后：`llvm` / `ncurses` / `libarchive`，以及 Vite+ `bin`（只为 `vp`；其 `node`/`npm` shim 不能盖 mise）

不要把 coreutils gnubin 放在 `/usr/bin` 之前：GNU `stat`/`date`/`mktemp` 会让 opencode 的 `install.sh` 升级失败。不冲突的 GNU 短名已由 brew 链到 `$HOMEBREW_PREFIX/bin`。`~/.opencode/bin` 在 zshenv 里。`aiupdate` 在 `init.zsh`。

`JAVA_HOME` 由 mise `java` 设置，不把 brew openjdk 放进 PATH。python 走 mise / uv，不把 `python@*/libexec` 放进 PATH。llvm 不写进全局 `LDFLAGS`。

## 占位符规则

`zsh/zshenv` 和 `templates/mise_config.toml` 含两类占位符，**仅在部署时**由 `bin/deploy.sh` 替换：

| 占位符 | 部署时替换为 | 影响变量 |
|---|---|---|
| `__STORAGE_ROOT__` | 用户选的存储根绝对路径 | `CODE_LANGUAGES_HOME` |
| `__DOTFILES_ROOT__` | 仓库克隆的绝对路径 | `DOTFILES_ROOT` |

路径不能含 `&`、`|`、`\`（sed 替换串的特殊字符），`bin/deploy.sh` 会拒绝。部署版 `~/.zshenv` 不反向同步回 `zsh/zshenv`。

## mise 工具版本管理

`mise activate zsh`（在 `init.zsh` 内）管理全局运行时（node / go / rust / python）和 CLI 工具，precmd hook 每次 prompt 重置 PATH。全局工具清单在 `templates/mise_config.toml`，`init` 会覆盖本机 `mise use -g` 的改动；项目工具写在各项目的 `mise.toml`。`sops` 由 brew 管理。

## Git 签名

机制定义在仓库 `git/config`：SSH 签名（`gpg.format = ssh`，`gpg.ssh.program` 指向 1Password），`commit.gpgsign = true`；GitHub credential 走 `gh auth git-credential`；清空 `core.askPass`；`safe.directory = *`（关闭目录属主检查，对所有 include 它的机器生效）。

本机 `~/.gitconfig` 通过 `[include]` 引用它；`[user]` 身份和 `signingkey` 在本机主文件，不进仓库。新机器上由 `bin/setup.sh` 的 git 模块询问并设置。

AI agent 的每条命令都是新的非交互进程，经 1Password 签名或 SSH 会逐次弹授权。机器上若有同一把 key 的本地私钥，可在本机 `~/.gitconfig` 覆盖 `gpg.ssh.program = ssh-keygen`、`user.signingkey = <私钥路径>`，并在 `~/.ssh/config` 的 `Host github.com` 设 `IdentityAgent none` 加 `IdentityFile`；git 仍走 SSH。这些是本机文件，不写进仓库。

## 主题：GitHub Light Colorblind（统一 light 配色 + 色盲友好）

终端工具和 VS Code 用 GitHub Light Colorblind 配色：**橙色 (#b35900) 替代红色，蓝色 (#0969da) / 紫色 (#8250df) 替代绿色**，避免红绿色盲混淆。多数工具不写死颜色，跟随终端 ANSI 配色，所以终端主题决定最终效果。

| 工具 | 配置位置 | 主题来源 |
|---|---|---|
| rex | `rex/workspace.defaults` 的 `lightThemeID` 当前为内置 `merino-light`；`rex/themes/GitHub Light Colorblind`（Ghostty 格式调色板）随部署复制，可在 Rex 设置里选用 | Rex 内置 / 仓库调色板 |
| starship | `starship/starship.toml` | 不指定 palette，跟随终端 ANSI 配色 |
| bat | `bat/config` | `--theme="ansi"` 跟随终端 ANSI 配色 |
| fzf | `init.zsh` 不设 `--color` | 跟随终端 ANSI 配色 |
| btop | `btop/btop.conf` 引用；`bin/deploy.sh` 从 `btop/themes/` 复制主题文件 | 仓库自带主题文件 |
| yazi | `yazi/theme.toml` | 手写，用 ANSI 颜色名 |
| atuin | `atuin/config.toml` | 不指定主题，跟随终端 ANSI |
| vscode | `vscode/settings.json` 的 `workbench.colorTheme: "GitHub Light Colorblind (Beta)"`；扩展 `GitHub.github-vscode-theme` 经 Settings Sync 或手动安装 | 扩展自带 |

## 调试 / Profile

`ZSH_PROFILE=1` 启用 zsh 启动 profile（详见 `debug/profile.zsh` 顶部）。默认关闭，零开销。

```bash
# 临时开启（一次性测试）
ZSH_PROFILE=1 zsh -i -l -c exit

# 长期开启：在 ~/.zshenv 加 export ZSH_PROFILE=1，再开新窗口；用完删掉那行
```

## AI 配置

AI CLI 只装 claude-code 和 opencode v2（`bin/install-ai-cli.sh`），配置由 `bin/setup-ai.sh` 部署。

- 全局提示词只有一份 `ai/AGENTS.md`，Claude Code 读 `~/.claude/CLAUDE.md`，opencode 读 `~/.config/opencode/AGENTS.md`，都链接到它。
- 个人 skill 放 `ai/skills/<名>/SKILL.md`，个人插件放 `ai/plugins/<名>/`，加完重跑 `bin/setup-ai.sh`。仓库里删除或改名后重跑，旧链接会被清掉。
- MCP 两边保持同一组：context7、exa、gh_grep、openseo、sentry、fingerprint、rea（逆向）、paper（前端设计）。一律用 API key / token 认证，不走 OAuth，也不装同名 Claude 插件：OAuth 的 refresh token 在多会话并发时容易失效，导致反复要求登录。sentry 用 `Sentry-Bearer` 个人 token；fingerprint 托管端点只支持 OAuth，改用 mise 安装的本地 `fingerprint-mcp-server`（private 模式，`--region ap`）。Claude Code 的定义在 `ai/claude/mcp.json`，opencode 的在 `ai/opencode/opencode.jsonc` 的 `mcp` 段，改一边要同步另一边。
- paper MCP 用 Paper 桌面应用自带的 `~/.paper/bin/paper`，需先装 Paper；rea 的 Hopper 集成需要 `~/Applications/Hopper Disassembler.app`。
- 密钥只按变量名引用（Claude Code 写 `${VAR}`，opencode 写 `{env:VAR}`），变量清单见 `templates/zsh_secrets.template`，值在 `~/.zsh_secrets`。`zsh/zshenv` 会 source 该文件，非交互进程启动的 agent 也能读到。缺密钥的 MCP 由 setup-ai 跳过。
- `~/.claude/settings.json` 里机器相关的键（`processWrapper`）不进仓库，合并时保留本机值。
- 个人账号相关、不宜公开的配置留在本机、不进仓库：opencode 的模型 provider 放 `~/.config/opencode/opencode.json`（opencode 会与链接进来的 `opencode.jsonc` 合并加载）；只适用本机的 agent 规则放 `~/.claude/rules/` 下的非仓库文件。
- 第三方 skill 不进仓库：Rex 用 `rex skill setup` 安装（setup-ai 会调用），ego-browser 链接到 ego lite 自带目录，lark / impeccable / reverse-engineer-anything 用各自的安装器。

## 敏感信息

本仓库公开。不提交密钥、账号、公司和内网信息、本机绝对路径和私有项目名。

- `~/.zsh_secrets` 在仓库外，不进版本控制；`.gitignore` 里的 `.zsh_secrets` 防止把副本误放进仓库。从 `templates/zsh_secrets.template` 复制创建，权限 600。AI 不得把部署版内容回写模板。
- 提交前由 pre-commit 跑 gitleaks（`.pre-commit-config.yaml`），hook 由 `bin/setup-ai.sh` 安装。
- 已推送的历史不改写；发现历史里有凭据时轮换凭据。
