# CLAUDE.md

本仓库是 macOS 开发环境配置的**只读模板**。本文档定义 AI 在本仓库内工作时的角色与边界。

## 仓库定位（重要）

**本仓库 ≠ 用户的 home 配置**。

- 仓库内所有 `zsh/*` / `ghostty/config` / `starship/starship.toml` / `templates/*` 等都是**模板源**。
- 实际生效的是 `~/.zshenv` / `~/.config/...` 等用户 home 内的**部署产物**。
- 部署通过 `bin/deploy.sh` 完成（复制 + sed 替换占位符），仓库内文件不直接被用户 shell 读取（唯一例外见下）。

**唯一例外**: `git/config` 通过 `~/.gitconfig` 的 `[include] path` 引用，不复制。修改即对所有引用它的机器生效。

## AI 角色边界（HARD RULES）

AI 进入本仓库时，必须先确定属于哪个角色：

### CONSUMER 模式 - 部署 / 升级 / 验证

触发场景：用户要"初始化新机器" / "重新部署 dotfiles" / "切换存储位置" / "拉最新更新到本机"。

允许：
- 读仓库任何文件
- 调用 `bin/deploy.sh` / `bin/install-themes.sh` / `bin/install-ai-cli.sh`
- 修改 `~` 内的部署产物（`~/.zshenv` / `~/.config/...`）
- 运行 `brew bundle install` / `zimfw install` / `mise install` 等外部工具

**禁止（违反立即停止）**：
- `git add` / `git commit` / `git push` 操作仓库
- 在仓库内新建任何文件（含临时脚本 / patch / .env / 备份）
- 修改仓库内任何文件（含"改一下 zsh/zshenv 适配本机"）
- 把部署版的绝对路径（如 `/Volumes/Storage/...`）回写到 `zsh/zshenv` 模板
- 用 `sed -i` / `Edit` 工具碰仓库目录下任何路径
- **`brew bundle cleanup` 含 `--force`**：本仓库 Brewfile 是模板而非本机全集，cleanup 会卸光本机所有未在模板里的软件（包括 MAS、第三方 tap、手动 brew install）。清理孤儿用 `brew autoremove`；单独卸用 `brew uninstall <名>`。AI 提及"清理 brew"任何场景，都要先确认非 cleanup 命令

### MAINTAINER 模式 - 功能开发 / 演进

触发场景：用户明确说"修改仓库" / "添加 X 功能" / "提交" / "演进 dotfiles"。

允许：
- 编辑仓库内任何模板文件
- 编辑 `bin/*` 部署脚本
- 编辑文档（README / CLAUDE.md）
- 编辑后 `git add` / `git commit` / `git push`（仅当用户明确说"提交"）

**禁止**：
- 把部署版绝对路径回写到模板（必须保持 `__STORAGE_ROOT__` / `__DOTFILES_ROOT__` 占位符）
- 在模板里嵌入本机特有信息（账号、密钥、机器名）
- 把 `~/.zsh_secrets` 等敏感文件内容回写到 `templates/zsh_secrets.template`

### 模式不清时

如果不确定属于哪个角色，**默认 CONSUMER**（只读仓库），并询问用户："这是部署到本机，还是修改仓库功能？"

## 部署流程（CONSUMER 用）

```bash
# 首次部署或重配（STORAGE_ROOT 是绝对路径，如 /Volumes/Storage 或 $HOME）
bin/deploy.sh init /Volumes/Storage

# 编辑 init.zsh 后同步到 ~/.zsh/init.zsh
bin/deploy.sh sync

# 安装第三方主题文件（btop / atuin）
bin/install-themes.sh

# 验证部署状态
bin/deploy.sh check
```

部署后续命令：
```bash
brew bundle install --file=$DOTFILES_ROOT/Brewfile   # 软件安装
bin/install-ai-cli.sh                                 # claude-code / codex / grok-build（官方 curl 脚本，不走 brew）
zimfw install                                         # zsh 模块
mise install                                          # 语言运行时
infat --config ~/.config/infat/config.toml            # 文件关联
duti -s com.microsoft.VSCode .sh all                  # infat 对 sh/bash/plist 报 error -50, 改用 duti
duti -s com.microsoft.VSCode .bash all
duti -s com.microsoft.VSCode .plist all
chsh -s /opt/homebrew/bin/zsh                         # 默认 shell
```

## 仓库结构

```
dotfiles/
├── bin/
│   ├── deploy.sh           部署主脚本（CONSUMER 用）
│   ├── install-themes.sh   第三方主题下载
│   └── install-ai-cli.sh   claude-code / codex / grok-build 官方 curl 安装（CONSUMER 用）
├── debug/
│   └── profile.zsh         zsh 启动 profile 调试（ZSH_PROFILE=1 启用）
├── zsh/                    [TEMPLATE] zsh 入口文件
│   ├── zshenv              环境变量 + PATH（含两个占位符）
│   ├── zprofile            登录 shell（brew shellenv + mise --shims）
│   ├── zshrc               zimfw 引导 + source ~/.zsh/init.zsh
│   └── zimrc               zim 模块声明
├── init.zsh                [TEMPLATE] 交互式 shell 全部配置
├── templates/
│   ├── mise_config.toml    mise 全局配置（含 __STORAGE_ROOT__）
│   └── zsh_secrets.template 空白密钥模板
├── ghostty/config          [TEMPLATE] 终端配置
├── starship/starship.toml  [TEMPLATE] 提示符
├── btop/btop.conf          [TEMPLATE] 系统监控
├── yazi/                   [TEMPLATE] 文件管理器
├── atuin/config.toml       [TEMPLATE] 历史搜索
├── bat/config              [TEMPLATE] cat 替代
├── ripgrep/config          [TEMPLATE] grep 替代
├── infat/config.toml       [TEMPLATE] 文件关联
├── git/                    [TEMPLATE] git 通用配置（include 引用，不复制）
├── technitium/README.md    [DOC] 本地 Technitium DNS 配置说明（配置为二进制不入库，照文档重建）
├── Brewfile                软件清单（直接被 brew bundle 读，不部署）
├── CLAUDE.md               本文件（AI 规则）
└── README.md               使用文档
```

## 部署目标对照

| 仓库文件 | 部署目标 | 覆盖策略 | 处理方式 |
|---|---|---|---|
| `zsh/zshenv` | `~/.zshenv` | 重配覆盖 | sed 替换占位符 |
| `zsh/zshrc` | `~/.zshrc` | 重配覆盖 | 直接复制 |
| `zsh/zprofile` | `~/.zprofile` | 重配覆盖 | 直接复制 |
| `zsh/zimrc` | `~/.zimrc` | 重配覆盖 | 直接复制 |
| `init.zsh` | `~/.zsh/init.zsh` | `sync` 同步 | 直接复制 |
| `templates/mise_config.toml` | `~/.config/mise/config.toml` | 重配覆盖 | sed 替换占位符 |
| `templates/zsh_secrets.template` | `~/.zsh_secrets` | 仅首次 | 复制 + chmod 600 |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` | 仅首次 | 直接复制 |
| `starship/starship.toml` | `~/.config/starship.toml` | 仅首次 | 直接复制 |
| `btop/btop.conf` | `~/.config/btop/btop.conf` | 仅首次 | 直接复制 |
| `yazi/keymap.toml` | `~/.config/yazi/keymap.toml` | 仅首次 | 直接复制 |
| `yazi/theme.toml` | `~/.config/yazi/theme.toml` | 仅首次 | 直接复制 |
| `atuin/config.toml` | `~/.config/atuin/config.toml` | 仅首次 | 直接复制 |
| `bat/config` | `~/.config/bat/config` | 仅首次 | 直接复制 |
| `ripgrep/config` | `~/.config/ripgrep/config` | 仅首次 | 直接复制 |
| `infat/config.toml` | `~/.config/infat/config.toml` | init 覆盖 | 直接复制 |
| `git/ignore` | `~/.config/git/ignore` | 仅首次 | 直接复制 |
| `git/config` | (不复制) | - | `~/.gitconfig` 加 `[include] path = ...` |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` | jq 深合并 | 本地字段保留, 仓库同名 key 覆盖 |
| `Brewfile` | (不复制) | - | `brew bundle install --file=...` 直接读 |
| `bin/install-ai-cli.sh` | (不复制) | 每次重跑 = 更新 | 官方 curl 脚本装 claude-code / codex / grok-build |

## Shell 加载顺序

```
~/.zshenv      所有 shell             环境变量 / PATH（含 keg-only 与用户 CLI）/ DOTFILES_ROOT
~/.zprofile    登录 shell（zshrc 前）  brew shellenv（HOMEBREW_*）后恢复 PATH；非交互 mise shims
~/.zshrc       交互式 shell            zimfw 引导 -> source ~/.zsh/init.zsh
  ~/.zimrc     由 zimfw 读取            zim 模块列表
    zim 模块: environment, input, completions, fzf-tab, syntax-highlighting, autosuggestions
  ~/.zsh/init.zsh                      交互式配置（部署版 init.zsh）
```

PATH 只在 `zsh/zshenv` 的 `_dotfiles_setup_path` 维护。`~/.zprofile` 在 `path_helper` 和 `brew shellenv` 之后再调一次该函数，否则登录壳会把 `/usr/bin` 抬到 keg-only 前面。brew caveats 和安装器 `echo >> ~/.zshrc` 的片段部署时会被覆盖，不要手动留在 `~/.zshrc` / `~/.zprofile`。

PATH 分层（先到的赢）：

1. 用户 CLI 与语言目录
2. 必须盖住系统的 keg-only：`ffmpeg-full` / `mysql-client` / `macos-trash` / `libpq` / `curl` / `sqlite` / `icu4c`
3. `$HOMEBREW_PREFIX/bin`
4. coreutils `gnubin`（GNU `date`/`timeout`；交互式 `ls`/`rm` 仍走 init.zsh 别名）。不加 libtool gnubin
5. `/usr/bin` 等系统路径
6. 系统之后的 keg-only：`llvm`（`clang-format` / `llvm-config`；`clang` 仍是 Apple）、`ncurses`、`libarchive`（`bsdtar` 旁路；`tar`/`clear` 仍是系统）

`JAVA_HOME` 由 mise `java` 设置，不把 brew openjdk 放进 PATH。python 走 mise / uv，不把 `python@*/libexec` 放进 PATH。llvm 不写进全局 `LDFLAGS`。

## 占位符规则

`zsh/zshenv` 和 `templates/mise_config.toml` 含两类占位符，**仅在部署时**由 `bin/deploy.sh init` 替换：

| 占位符 | 部署时替换为 | 影响变量 |
|---|---|---|
| `__STORAGE_ROOT__` | 用户选的存储根绝对路径 | `CODE_LANGUAGES_HOME` |
| `__DOTFILES_ROOT__` | 仓库克隆的绝对路径 | `DOTFILES_ROOT` |

**绝不**：
- 在仓库模板里写绝对路径（必须保留占位符）
- 部署版 `~/.zshenv` 反向同步回 `zsh/zshenv`（会污染模板）
- AI 手写 sed 命令（必须调用 `bin/deploy.sh init`）

## proto + mise 工具版本管理

**分工**：
- `mise activate zsh`（在 `init.zsh` 内）：全局运行时（node / go / rust / python）+ precmd hook 重置 PATH
- `~/.proto/bin`（PATH 内）：proto CLI 本身
- `~/.proto/shims`（PATH 内）：proto-only 工具（atlas / buf / cosign）。`sops` 由 brew 管理

不用 `proto activate`：proto 只注册 chpwd_functions，mise 的 precmd 每次 prompt 重置 PATH 会覆盖 proto chpwd 效果。proto-shim 内置 fallback 逻辑，不依赖 `proto activate` 设的 `__ORIG_PATH`。

## Git 签名

1Password SSH 签名（`gpg.format = ssh`，`gpg.ssh.program` 指向 1Password）。commit 默认 GPG 签名。GitHub credential 通过 `gh auth git-credential`。

机制定义在仓库 `git/config`，本机 `~/.gitconfig` 通过 `[include]` 引用；`[user]` 身份和 `signingkey` 在本机主文件，不进仓库。修改通用配置编辑 `git/config` 即对所有机器生效。

## 主题：GitHub Light Colorblind（统一 light 配色 + 色盲友好）

所有终端工具 + VS Code 统一使用 GitHub Light Colorblind 配色。
**橙色 (#b35900) 替代红色，蓝色 (#0969da) / 紫色 (#8250df) 替代绿色**，避免红绿色盲混淆。

| 工具 | 配置位置 | 主题来源 |
|---|---|---|
| ghostty | `ghostty/config` | 内置（`theme = GitHub Light Colorblind`） |
| starship | `starship/starship.toml` | 不指定 palette，跟随终端 ANSI 配色 |
| bat | `bat/config` | `--theme="ansi"` 跟随终端 ANSI 配色 |
| fzf | `init.zsh` 内 `FZF_DEFAULT_OPTS` | 手写 |
| btop | `btop/btop.conf` 引用 + `bin/install-themes.sh btop` 从仓库 `btop/themes/` 复制 | 仓库自带主题文件 |
| yazi | `yazi/theme.toml` | 手写 |
| atuin | `atuin/config.toml` | 不指定主题，fallback 跟随终端 ANSI |
| vscode | `vscode/settings.json` 设 `workbench.colorTheme: "GitHub Light Colorblind"`（扩展 `GitHub.github-vscode-theme` 需经 VS Code 内置 Settings Sync / 手动安装，不再由 Brewfile 托管） | 扩展自带 |

修改主题：编辑对应配置文件（ghostty/starship/btop/yazi/init.zsh fzf 段），跑 `bin/deploy.sh init <ROOT>` 重新部署 + `bin/install-themes.sh` 复制 btop 主题。

## 调试 / Profile

`ZSH_PROFILE=1` 启用 zsh 启动 profile（详见 `debug/profile.zsh` 顶部）。默认关闭，零开销。

```bash
# 临时开启（一次性测试）
ZSH_PROFILE=1 zsh -i -l -c exit

# 长期开启（编辑 ~/.zshenv 加 export ZSH_PROFILE=1，再开新窗口）
# 关闭：删除 ~/.zshenv 那行
```

## 敏感信息

`~/.zsh_secrets` 不进版本控制（`.gitignore` 排除）。从 `templates/zsh_secrets.template` 复制创建，权限 600。AI 不得把部署版内容回写模板。
