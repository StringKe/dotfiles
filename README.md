# dotfiles

macOS 开发环境配置模板。大部分配置文件复制到系统路径后独立于仓库；例外：`init.zsh` 由 zimfw 作为本地模块直接从仓库加载，修改后重开终端立即生效。

## 前置准备

以下三步需手动完成：

1. 安装 Xcode Command Line Tools：

```bash
xcode-select --install
```

2. 安装 Homebrew：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

3. 克隆仓库（推荐放在存储根下的 `Code/SelfCode/`）：

```bash
mkdir -p /Volumes/Storage/Code/SelfCode
git clone https://github.com/StringKe/dotfiles.git /Volumes/Storage/Code/SelfCode/dotfiles
```

## 通过 AI 初始化

将以下提示词发送给 AI 助手（Claude Code、Cursor 等）。新机器与已部署机器均适用，AI 会自动检测当前状态并按首次部署 / 重配 / 迁移分流。

````
## 1. 角色与上下文

你正在初始化一台 macOS 开发机。dotfiles 仓库已克隆到某处，记为 DOTFILES_ROOT。

**部署模型：**
- 大部分配置文件复制到系统路径，复制后独立于仓库。
- 例外：`init.zsh`（交互式 shell 全部配置）**不复制**，由 zimfw 通过 `zmodule $DOTFILES_ROOT` 从仓库直接加载。修改后重开终端立即生效。

按 Section 2-8 顺序执行，每步完成后报告状态。

## 2. 预检

验证：uname -s 为 Darwin；xcode-select -p 成功；command -v brew 成功。

解析 DOTFILES_ROOT：依次检测首个含 Brewfile 的目录——`$HOME/Code/SelfCode/dotfiles`、`/Volumes/Storage/Code/SelfCode/dotfiles`；若仍无，在 `$HOME/Code` 与 `/Volumes/*/Code/SelfCode/dotfiles` 下查找。记下绝对路径。

任一失败则告知用户回到 README 的"前置准备"章节。

## 3. 存储根选择与迁移

`__STORAGE_ROOT__` 是仓库模板中的替换标记，部署时替换为用户选择的绝对路径（NEW_ROOT）。存储根下固定子目录：`Code/`、`Languages/`（工具链）、`ollama/`（模型）。

### 3a. 检测当前状态

读取 `~/.zshenv`（不存在则"首次部署"）。按优先级解析 CURRENT_ROOT：
1. `export CODE_LANGUAGES_HOME=".../Languages"` -> 去掉末尾 `/Languages`
2. `export OLLAMA_MODELS=".../ollama/models"` -> 去掉末尾 `/ollama/models`
3. 文件含 `__STORAGE_ROOT__` -> 按首次部署处理
4. 以上均无 -> 首次部署

### 3b. 询问目标存储根

询问用户 NEW_ROOT（绝对路径，不接受 `~` / `$HOME`），候选：`/Volumes/Storage`、`$HOME` 绝对值、自定义路径。

### 3c. 按情形分流

| 情形 | 判定 | 动作 |
|---|---|---|
| 首次部署 | 无 CURRENT_ROOT | 记下 NEW_ROOT，执行后续 Section |
| 重配不换位置 | NEW_ROOT == CURRENT_ROOT | 覆盖配置文件，数据目录不动 |
| 迁移换位置 | NEW_ROOT != CURRENT_ROOT | 先执行 3d 迁移，再执行后续 Section |

确定 NEW_ROOT 后：若 DOTFILES_ROOT 不在 `NEW_ROOT/Code/SelfCode/dotfiles`，询问是否 `mv`（可选）。

### 3d. 迁移数据（仅 NEW_ROOT != CURRENT_ROOT）

先输出迁移分析表（源/目标/大小/是否跨卷），再动手：
1. `df -h` 确认目标卷空间足够
2. 用户确认后 `mkdir -p NEW_ROOT`，逐目录 `mv`（目标已存在则停下询问）
3. 迁移完成后提示用户验证新路径，再自行清理旧位置

## 4. 软件安装

```bash
brew bundle install --file=$DOTFILES_ROOT/Brewfile
```

部分失败时解释原因并继续。

## 5. 配置文件部署

### 5a. init.zsh（不复制）

`DOTFILES_ROOT/init.zsh` 不需要复制，由 zimfw 直接加载。

### 5b. 需要部署的文件

| 仓库文件 | 目标路径 | 覆盖策略 |
|---|---|---|
| zsh/zshenv | ~/.zshenv | 无条件覆盖（双占位符替换） |
| zsh/zshrc | ~/.zshrc | 无条件覆盖 |
| zsh/zprofile | ~/.zprofile | 无条件覆盖 |
| zsh/zimrc | ~/.zimrc | 无条件覆盖 |
| templates/mise_config.toml | ~/.config/mise/config.toml | 无条件覆盖（占位符替换） |
| ghostty/config | ~/Library/Application Support/com.mitchellh.ghostty/config | 跳过已存在（询问 diff） |
| starship/starship.toml | ~/.config/starship.toml | 跳过已存在（询问 diff） |
| ripgrep/config | ~/.config/ripgrep/config | 跳过已存在（询问 diff） |
| yazi/keymap.toml | ~/.config/yazi/keymap.toml | 跳过已存在（询问 diff） |
| git/ignore | ~/.config/git/ignore | 跳过已存在（询问 diff） |
| git/config | ~/.gitconfig | 见 5e（[include] 引用，不整体复制） |
| atuin/config.toml | ~/.config/atuin/config.toml | 跳过已存在（询问 diff） |
| btop/btop.conf | ~/.config/btop/btop.conf | 跳过已存在（询问 diff） |
| infat/config.toml | ~/.config/infat/config.toml | 跳过已存在（询问 diff） |

### 5c. 占位符替换

`zsh/zshenv` 含两类占位符，写入前全部替换（使用 `>|` 强制覆写，避免 zsh NO_CLOBBER）：

```bash
sed -e "s|__STORAGE_ROOT__|${NEW_ROOT}|g" \
    -e "s|__DOTFILES_ROOT__|${DOTFILES_ROOT}|g" \
    "$DOTFILES_ROOT/zsh/zshenv" >| ~/.zshenv
```

`templates/mise_config.toml` 只含 `__STORAGE_ROOT__`：

```bash
sed "s|__STORAGE_ROOT__|${NEW_ROOT}|g" \
    "$DOTFILES_ROOT/templates/mise_config.toml" >| ~/.config/mise/config.toml
```

禁止在已部署文件中保留任何占位符。禁止 `export STORAGE_ROOT`。

### 5d. 升级检测（已部署旧版本）

部署前检查，若命中则告知用户将被更新：
- `~/.zshenv` 不含 `export DOTFILES_ROOT=` -> 旧版，重配后自动加入；同时检查 `~/.zimrc` 是否含 `zmodule $DOTFILES_ROOT`，若无则追加
- `~/.zshenv` 的 `path=()` 缺少 `$HOME/.proto/bin` 或 `$HOME/.proto/shims` -> 旧版，重配后修复
- `~/.zprofile` 含 `mise activate zsh --shims` 但不含 `[[ ! -o interactive ]]` -> 缺少交互式判断
- `~/.zshrc` 含 `eval "$(direnv hook zsh)"` -> 已迁移到 `zmodule zimfw/direnv`；重配后运行 `zimfw install`
- `~/.zshrc` 含大量别名/函数/工具激活 -> 旧版未拆分，新版已迁移到 `init.zsh`
- `~/.gitconfig` 整体复制自仓库（含通用字段但无 `[include]`）-> 改为 include 引用（见 5e），本机身份/签名独立保留

### 5e. git/config（include 引用，不整体复制）

`git/config` 是通用 Git 配置（gpg/commit/credential 等），不含身份和签名密钥。不整体复制覆盖 `~/.gitconfig`，而由本机 `~/.gitconfig` 通过 `[include]` 引用：仓库改动 live 生效，本机 `[user]` 签名密钥独立保留，credential helper 多值（先空值重置再设 gh）原样生效。

本机 `~/.gitconfig` 形态（只放机器特有字段 + include）：

```ini
[user]
	name = ...
	email = ...
	signingkey = ssh-ed25519 ...
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
[include]
	path = DOTFILES_ROOT/git/config
```

git 不展开环境变量，`path` 须为仓库 git/config 的绝对路径（用实际 DOTFILES_ROOT 替换）。

部署逻辑：
- 首次（无 `~/.gitconfig`）：从现有 `git config --global` 读 user.name/email/signingkey（无则询问），生成主文件含 `[user]` + `[include] path`
- 已存在：保留本机所有字段，删除与仓库重复的通用字段段（gpg/commit/core/init/safe/credential），末尾确保 `[include] path` 指向仓库 git/config

修改通用 Git 配置直接编辑仓库 `git/config`，对所有 include 它的机器立即生效。

## 6. 系统配置

### 6a. Secrets 文件

仅当 ~/.zsh_secrets 不存在时：
```bash
cp $DOTFILES_ROOT/templates/zsh_secrets.template ~/.zsh_secrets
chmod 600 ~/.zsh_secrets
```

### 6b. 语言环境目录

```bash
mkdir -p NEW_ROOT/Code/SelfCode
mkdir -p NEW_ROOT/Languages/{cli/{zoxide,atuin,helm,starship},mise/{data,cache},go,rust/{rustup,cargo},nodejs/{npm-cache,npm-global,pnpm-global,pnpm-store,yarn-global,node-gyp},bun,deno,java/{gradle,maven},python/{pip-cache,pipx/bin,uv/{cache,python,tools,bin},huggingface},php/composer}
mkdir -p NEW_ROOT/ollama/models
```

### 6c. Zim 框架

```bash
curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
DOTFILES_ROOT="<仓库绝对路径>" ZIM_HOME="$HOME/.zim" zsh "$HOME/.zim/zimfw.zsh" install
```

验证 init.zsh 已加载：
```bash
exec zsh -c 'echo $DOTFILES_ROOT'
```
若输出为空，检查 `~/.zshenv` 中 `DOTFILES_ROOT` 是否已替换为绝对路径。

### 6d. 文件关联

```bash
infat --config ~/.config/infat/config.toml
```

### 6e. 默认 Shell

```bash
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh
```

## 7. 验证清单

逐项检查并报告通过/失败：
1. `brew doctor` 无严重警告
2. `rg '__STORAGE_ROOT__|__DOTFILES_ROOT__' ~/.zshenv ~/.config/mise/config.toml` 无输出；无 `export STORAGE_ROOT`；`DOTFILES_ROOT` 已替换为仓库绝对路径
3. `~/.zsh_secrets` 存在且权限为 600
4. NEW_ROOT/Languages/ 目录结构完整；NEW_ROOT/ollama/models 存在
5. `~/.zim/modules/` 含 direnv、fzf-tab 等模块
6. 默认 shell 为 `/opt/homebrew/bin/zsh`（`dscl . -read ~/ UserShell`）
7. `exec zsh` 后：`echo $DOTFILES_ROOT` 输出仓库路径；`which proto` 输出 `~/.proto/bin/proto`；`echo $PATH | tr ':' '\n' | grep -E 'proto|moon'` 命中三条
8. `~/.zshrc` 仅含 zimfw 引导；`~/.zimrc` 含 `zmodule zimfw/direnv` 和 `zmodule $DOTFILES_ROOT`

## 8. 后续提醒

- 编辑 `~/.zsh_secrets` 填入 API 密钥等敏感信息
- 运行 `exec zsh` 使新配置生效
- 运行 `mise install` 安装语言运行时（Node.js、Rust、Go、uv）
- 修改交互式 shell 配置直接编辑 `DOTFILES_ROOT/init.zsh`，重开终端即生效
````

## 目录结构

```
dotfiles/
├── init.zsh                # 交互式 shell 全部配置（zimfw 本地模块，无需复制）
├── Brewfile                # Homebrew 软件清单
├── zsh/
│   ├── zshenv              # 环境变量模板（含 __STORAGE_ROOT__ / __DOTFILES_ROOT__ 占位符）
│   ├── zshrc               # 仅 zimfw 引导（约 25 行）
│   ├── zprofile            # 登录 shell（Homebrew env / mise --shims）
│   └── zimrc               # zimfw 插件列表（末尾含 zmodule $DOTFILES_ROOT）
├── ghostty/config          # Ghostty 终端配置
├── starship/starship.toml  # Starship 提示符
├── ripgrep/config          # ripgrep 全局配置
├── yazi/keymap.toml        # yazi 键位
├── git/{config,ignore}     # Git 全局配置和 gitignore
├── atuin/config.toml       # Atuin 历史搜索
├── btop/btop.conf          # btop 系统监控
├── infat/config.toml       # macOS 文件关联
└── templates/
    ├── mise_config.toml    # mise 配置模板（含 __STORAGE_ROOT__）
    └── zsh_secrets.template
```

## Shell 别名

| 别名 | 说明 |
|---|---|
| `ls` / `ll` / `lt` | eza（现代 ls） |
| `hh` | atuin 历史搜索 |
| `lg` | lazygit |
| `y` | yazi 文件管理器 |
| `k` / `kgp` / `kl` 等 | kubectl 快捷键（完整列表见 `init.zsh`） |

## 定制指引

| 想修改什么 | 编辑哪里 | 生效方式 |
|---|---|---|
| 别名/函数/工具激活/prompt | `DOTFILES_ROOT/init.zsh` | 重开终端 |
| zim 插件 | `DOTFILES_ROOT/zsh/zimrc` -> 重配 -> `zimfw install` | `exec zsh` |
| 环境变量 | `~/.zshenv`（本机），同步回仓库时改回占位符 | `exec zsh` |
| 软件清单 | `DOTFILES_ROOT/Brewfile` -> `brew bundle install` | 立即 |
| 文件关联 | `~/.config/infat/config.toml` -> `infat` | 立即 |
| 敏感信息 | `~/.zsh_secrets` | `exec zsh` |

## 同步回仓库

`init.zsh` 直接 commit，无需复制。

`~/.zshenv` 修改后同步回仓库前：
1. 将 `CODE_LANGUAGES_HOME` 绝对路径改回 `__STORAGE_ROOT__/Languages`
2. 将 `OLLAMA_MODELS` 绝对路径改回 `__STORAGE_ROOT__/ollama/models`
3. 将 `DOTFILES_ROOT` 绝对路径改回 `__DOTFILES_ROOT__`
4. `rg '__STORAGE_ROOT__|__DOTFILES_ROOT__' $DOTFILES_ROOT --include='*.zsh' --include='*.toml'` 确认仅命中模板文件
