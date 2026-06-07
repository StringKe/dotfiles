# dotfiles

macOS 开发环境配置模板。文件首次复制到系统路径后本地独立，不使用 symlink。

Brewfile 包含 Homebrew formulae、cask、VSCode 扩展和 Mac App Store 应用的声明式清单，通过 `brew bundle` 一键安装。

## 前置准备

以下三步需手动完成（AI 运行环境本身的依赖）：

1. 安装 Xcode Command Line Tools：

```bash
xcode-select --install
```

2. 安装 Homebrew 并加载环境变量：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

3. 克隆仓库（推荐放在存储根下的 `Code/`，与 `Languages/` 布局一致；亦可先克隆到 `$HOME/Code/SelfCode/dotfiles`，初始化时再迁到 `NEW_ROOT/Code/SelfCode/dotfiles`）：

```bash
# 推荐（外置卷示例，路径按实际存储根修改）
mkdir -p /Volumes/Storage/Code/SelfCode
git clone https://github.com/StringKe/dotfiles.git /Volumes/Storage/Code/SelfCode/dotfiles

# 或家目录
mkdir -p ~/Code/SelfCode
git clone https://github.com/StringKe/dotfiles.git ~/Code/SelfCode/dotfiles
```

## 通过 AI 初始化

将以下提示词发送给 AI 助手（Claude Code、Cursor 等），它会读取仓库内容并智能执行全部初始化步骤。遇到冲突或错误时 AI 可自行判断处理，无需静态脚本的局限性。

**新机器与已部署机器均适用**：已配置过的用户重新发送同一段 prompt，会先检测当前存储根，再按首次部署 / 重配（不换位置）/ 迁移（换位置）分流。

````
## 1. 角色与上下文

你正在初始化一台 macOS 开发机。dotfiles 仓库已克隆到某处，记为 DOTFILES_ROOT（见 Section 2）。

**部署模型：**
- 大部分配置文件复制到系统路径（不使用 symlink），复制后本地独立于仓库。
- 例外：`init.zsh`（交互式 shell 全部配置）**不复制**，由 zimfw 作为本地模块从 DOTFILES_ROOT 直接加载。修改仓库中的 `init.zsh` 后重开终端立即生效。

按以下 Section 2-8 顺序执行，每步完成后报告状态。

## 2. 预检

验证以下条件，全部通过才继续：
- uname -s 为 Darwin
- xcode-select -p 成功
- command -v brew 成功
- 解析 DOTFILES_ROOT：按顺序检测首个含 Brewfile 的目录——`$HOME/Code/SelfCode/dotfiles`、`/Volumes/Storage/Code/SelfCode/dotfiles`；若仍无，在 `$HOME/Code` 与 `/Volumes/*/Code/SelfCode/dotfiles` 下查找。记下绝对路径供后续使用。

任一失败则告知用户回到 README 的"前置准备"章节。

## 3. 存储根选择与迁移

存储路径不写死。`__STORAGE_ROOT__` **仅是仓库模板中的替换标记**，部署时由 AI 在 `zsh/zshenv`、`templates/mise_config.toml` 内全文替换为用户选择的绝对路径（NEW_ROOT）；**不要**在已部署文件中保留 `__STORAGE_ROOT__`，也**不要** `export STORAGE_ROOT` 环境变量。存储根下固定子目录：`Code/`（代码仓库）、`Languages/`（语言工具链与缓存）、`ollama/`（模型）。本节确定存储根并处理已部署机器的迁移。

### 3a. 检测当前状态

读取 `~/.zshenv`（不存在则判定为"首次部署"）。按优先级解析 CURRENT_ROOT（存储根本身，不含 `/Languages` 后缀）：
1. `export CODE_LANGUAGES_HOME=".../Languages"`（绝对路径）-> CURRENT_ROOT = 去掉末尾 `/Languages`
2. 否则 `export OLLAMA_MODELS=".../ollama/models"` -> CURRENT_ROOT = 去掉末尾 `/ollama/models`
3. 否则误留的 `export STORAGE_ROOT="..."`（旧流程）-> CURRENT_ROOT = 该值
4. 若文件中仍含 `__STORAGE_ROOT__` -> 部署未完成，按首次部署处理或提示先完成占位符替换
5. 以上均未匹配 -> 判定为"首次部署"

解析到 CURRENT_ROOT 则判定为"已部署"，并向用户报告当前存储根。

### 3b. 询问目标存储根

询问用户 NEW_ROOT，要求回答绝对路径（不接受 `~` / `$HOME`，因为 toml 无法展开），给出候选：
- `/Volumes/Storage`（外置磁盘等独立卷）
- 家目录绝对路径，执行 `echo $HOME` 取值（如 `/Users/用户名`）
- 用户自定义的其他绝对路径

### 3c. 按情形分流

| 情形 | 判定 | 动作 |
|---|---|---|
| 首次部署 | 无 CURRENT_ROOT | 记下 NEW_ROOT，进入后续 Section（部署时替换占位符、按 NEW_ROOT 建目录） |
| 重配不换位置 | NEW_ROOT == CURRENT_ROOT | 继续后续 Section，覆盖部署配置文件，数据目录不动 |
| 迁移换位置 | NEW_ROOT != CURRENT_ROOT | 先执行 3d 迁移数据，再继续后续 Section |

确定 NEW_ROOT 后：建议 dotfiles 位于 `NEW_ROOT/Code/SelfCode/dotfiles`。若 DOTFILES_ROOT 不在该路径，询问用户是否将仓库 `mv` 过去（可选）；不迁移则继续用原 DOTFILES_ROOT。

### 3d. 迁移数据（仅 NEW_ROOT != CURRENT_ROOT）

1. 先输出迁移分析表再动手，列出每个待移动目录的源、目标、当前大小（`du -sh`）、是否跨卷：
   - `CURRENT_ROOT/Languages` -> `NEW_ROOT/Languages`
   - `CURRENT_ROOT/ollama` -> `NEW_ROOT/ollama`
2. 跨卷提醒（`/Volumes/Storage` 与家目录通常不同文件系统）：`mv` 实为复制+删除，慢且需峰值双倍空间，先用 `df -h` 确认目标卷剩余空间足够。
3. 用户确认后执行 `mkdir -p NEW_ROOT`，逐目录 `mv`。目标已存在同名目录则停下询问，不覆盖。
4. `Languages/` 默认整体迁移（含各语言全局包、pnpm-store、ollama 模型、atuin 历史、zoxide 数据）。纯缓存子目录（`go/cache`、`python/pip-cache`、`nodejs/npm-cache`、`python/uv/cache`、`java/gradle`、`java/maven`）可由用户选择跳过让其自动重建，默认全搬保证零丢失。
5. 迁移完成提示用户验证新路径生效后，再自行清理旧位置残留。

## 4. 软件安装

执行：
```bash
brew bundle install --file=$DOTFILES_ROOT/Brewfile
```

如果部分 formula/cask 安装失败，解释失败原因，继续安装其余项目。

## 5. 配置文件部署

### 5a. init.zsh（不复制）

`DOTFILES_ROOT/init.zsh` 包含交互式 shell 的全部配置。**不需要复制到系统路径**，由 zimfw 通过 `zmodule $DOTFILES_ROOT` 从仓库直接加载。修改后重开终端立即生效。

### 5b. 需要部署的文件

| 仓库文件 | 目标路径 | 覆盖策略 |
|---|---|---|
| zsh/zshenv | ~/.zshenv | 无条件覆盖（双占位符替换） |
| zsh/zshrc | ~/.zshrc | 无条件覆盖 |
| zsh/zprofile | ~/.zprofile | 无条件覆盖 |
| zsh/zimrc | ~/.zimrc | 无条件覆盖 |
| templates/mise_config.toml | ~/.config/mise/config.toml | 无条件覆盖（占位符替换，保留 [tools]） |
| ghostty/config | ~/Library/Application Support/com.mitchellh.ghostty/config | 跳过已存在（询问 diff） |
| starship/starship.toml | ~/.config/starship.toml | 跳过已存在（询问 diff） |
| ripgrep/config | ~/.config/ripgrep/config | 跳过已存在（询问 diff） |
| yazi/keymap.toml | ~/.config/yazi/keymap.toml | 跳过已存在（询问 diff） |
| git/ignore | ~/.config/git/ignore | 跳过已存在（询问 diff） |
| git/config | ~/.gitconfig | 跳过已存在（询问 diff） |
| atuin/config.toml | ~/.config/atuin/config.toml | 跳过已存在（询问 diff） |
| btop/btop.conf | ~/.config/btop/btop.conf | 跳过已存在（询问 diff） |
| infat/config.toml | ~/.config/infat/config.toml | 跳过已存在（询问 diff） |

### 5c. 占位符替换

`zsh/zshenv` 含两类占位符，写入 `~/.zshenv` 前全部替换：

```bash
sed -e "s|__STORAGE_ROOT__|${NEW_ROOT}|g" \
    -e "s|__DOTFILES_ROOT__|${DOTFILES_ROOT}|g" \
    "$DOTFILES_ROOT/zsh/zshenv" > ~/.zshenv
```

`templates/mise_config.toml` 只含 `__STORAGE_ROOT__`；若 `~/.config/mise/config.toml` 已有本机定制的 `[tools]`，重配时只替换 `[env]` 段路径，保留 `[tools]` 不动：

```bash
sed "s|__STORAGE_ROOT__|${NEW_ROOT}|g" \
    "$DOTFILES_ROOT/templates/mise_config.toml" > ~/.config/mise/config.toml
```

禁止在已部署文件中保留任何占位符。禁止 `export STORAGE_ROOT`。

### 5d. 升级检测（已部署旧版本）

部署前检查以下旧版本特征，若命中则告知用户该文件将被更新：
- `~/.zshenv` 不含 `export DOTFILES_ROOT=` -> 旧版无此变量，重配 zshenv 后自动加入；同时检查 `~/.zimrc` 是否含 `zmodule $DOTFILES_ROOT`，若无则追加到末尾
- `~/.zshenv` 的 `path=()` 数组缺少 `$HOME/.proto/bin` 或 `$HOME/.proto/shims` -> 旧版无 proto PATH，重配 zshenv 后自动修复
- `~/.zprofile` 含 `export PATH="$HOME/.moon/bin` -> 旧版 moon PATH 字符串拼接，已迁移到 zshenv
- `~/.zprofile` 含 `mise activate zsh --shims` 但不含 `[[ ! -o interactive ]]` -> 缺少交互式 shell 判断
- `~/.zshrc` 含 `eval "$(direnv hook zsh)"` -> 旧版手动 eval，已迁移到 zimrc 的 `zmodule zimfw/direnv`；重配后运行 `zimfw install`
- `~/.zshrc` 含大量配置内容（别名/函数/工具激活）-> 旧版未拆分，新版 zshrc 仅 zimfw 引导，全部内容已迁移到 `DOTFILES_ROOT/init.zsh`

仓库路径相对于 DOTFILES_ROOT

## 6. 系统配置

### 6a. Secrets 文件

仅当 ~/.zsh_secrets 不存在时：
```bash
cp $DOTFILES_ROOT/templates/zsh_secrets.template ~/.zsh_secrets
chmod 600 ~/.zsh_secrets
```

### 6b. 语言环境目录

在 Section 3 的 NEW_ROOT 下创建（替换 NEW_ROOT 为实际绝对路径）：

```bash
mkdir -p NEW_ROOT/Code/SelfCode
mkdir -p NEW_ROOT/Languages/{cli/{zoxide,atuin,helm,starship},mise/{data,cache},go,rust/{rustup,cargo},nodejs/{npm-cache,npm-global,pnpm-global,pnpm-store,yarn-global,node-gyp},bun,deno,java/{gradle,maven},python/{pip-cache,pipx/bin,uv/{cache,python,tools,bin},huggingface},php/composer}
mkdir -p NEW_ROOT/ollama/models
```

### 6c. Zim 框架

```bash
curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
# 安装所有模块（含 zimfw/direnv、Aloxaf/fzf-tab 等，本地 $DOTFILES_ROOT 模块跳过）
zsh -c "source ~/.zim/zimfw.zsh install"
```

验证 `DOTFILES_ROOT/init.zsh` 被正确加载：
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
# 将 Homebrew zsh 加入合法 shell 列表（如果不在）
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
# 切换默认 shell（需要用户密码）
chsh -s /opt/homebrew/bin/zsh
```

提示用户这一步需要输入密码。

## 7. 验证清单

逐项检查并报告通过/失败：
1. brew doctor 无严重警告
2. 配置文件全部存在；`rg '__STORAGE_ROOT__|__DOTFILES_ROOT__' ~/.zshenv ~/.config/mise/config.toml` 无输出（已部署文件无占位符）；`rg '__STORAGE_ROOT__|__DOTFILES_ROOT__' $DOTFILES_ROOT --include='*.zsh' --include='*.toml' -l` 仅命中仓库模板文件；无 `export STORAGE_ROOT`；`CODE_LANGUAGES_HOME` 为 `NEW_ROOT/Languages`；`DOTFILES_ROOT` 为仓库绝对路径
3. Ghostty 配置文件存在（~/Library/Application Support/com.mitchellh.ghostty/config）
4. ~/.zsh_secrets 存在且权限为 600
5. NEW_ROOT/Languages/ 下目录结构完整，NEW_ROOT/ollama/models 存在
6. ~/.zim/zimfw.zsh 存在；zimfw 模块已安装（ls ~/.zim/modules/ 列出 direnv、fzf-tab 等）
7. 当前默认 shell 为 /opt/homebrew/bin/zsh（dscl . -read ~/ UserShell）
8. starship prompt 可用（command -v starship）
9. infat 文件关联已应用（infat info --ext json 输出包含 Visual Studio Code）
10. VSCode 扩展已安装（code --list-extensions | wc -l 大于 0）
11. `exec zsh` 后验证：`echo $DOTFILES_ROOT` 输出仓库路径；`which proto` 输出 ~/.proto/bin/proto；`echo $PATH | tr ':' '\n' | grep -E 'proto|moon'` 命中 proto/bin、proto/shims、moon/bin
12. `~/.zshrc` 仅含 zimfw 引导（不含别名/函数/工具激活）；`~/.zimrc` 含 `zmodule zimfw/direnv` 和 `zmodule $DOTFILES_ROOT`
13. `~/.zprofile` 不含旧版 `export PATH="$HOME/.moon/bin`；mise --shims 行含 `[[ ! -o interactive ]]` 判断

## 8. 后续提醒

告知用户：
- 编辑 ~/.zsh_secrets 填入 API 密钥等敏感信息
- 执行 `exec zsh` 使新配置生效（或重开终端）
- 运行 `mise install` 安装语言运行时（Node.js、Rust、Go、uv）
- 打开 VSCode 登录 GitHub 以激活 Copilot
- 修改交互式 shell 配置（别名/函数/工具激活）直接编辑 `DOTFILES_ROOT/init.zsh`，重开终端即生效，无需重新部署
````

## 目录结构

```
dotfiles/
├── init.zsh                # 交互式 shell 全部配置（由 zimfw 作为本地模块加载，无需复制）
├── Brewfile                # Homebrew 软件清单
├── zsh/
│   ├── zshenv              # 环境变量模板（含 __STORAGE_ROOT__ / __DOTFILES_ROOT__ 占位符）
│   ├── zshrc               # 仅 zimfw 引导（10 行），无任何配置
│   ├── zprofile            # 登录 shell（Homebrew env / mise --shims）
│   └── zimrc               # zimfw 插件列表（末尾含 zmodule $DOTFILES_ROOT）
├── ghostty/
│   └── config              # Ghostty 终端配置
├── starship/
│   └── starship.toml       # Starship 提示符配置
├── ripgrep/
│   └── config              # ripgrep 全局配置
├── yazi/
│   └── keymap.toml         # yazi 文件管理器键位
├── git/
│   ├── config              # Git 全局配置
│   └── ignore              # 全局 gitignore
├── atuin/
│   └── config.toml         # Atuin 历史搜索配置
├── btop/
│   └── btop.conf           # btop 系统监控配置
├── infat/
│   └── config.toml         # macOS 文件关联配置
└── templates/
    ├── mise_config.toml     # mise 配置模板（含 __STORAGE_ROOT__ 占位符）
    └── zsh_secrets.template # 敏感信息模板
```

## 文件映射

| 仓库文件 | 系统路径 | 部署方式 |
|---|---|---|
| `init.zsh` | 无（直接从仓库加载） | zimfw 本地模块，修改立即生效 |
| `zsh/zshenv` | `~/.zshenv` | 双占位符替换后复制，重配覆盖 |
| `zsh/zshrc` | `~/.zshrc` | 复制，重配覆盖 |
| `zsh/zprofile` | `~/.zprofile` | 复制，重配覆盖 |
| `zsh/zimrc` | `~/.zimrc` | 复制，重配覆盖 |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` | 复制，已存在则跳过 |
| `starship/starship.toml` | `~/.config/starship.toml` | 复制，已存在则跳过 |
| `ripgrep/config` | `~/.config/ripgrep/config` | 复制，已存在则跳过 |
| `yazi/keymap.toml` | `~/.config/yazi/keymap.toml` | 复制，已存在则跳过 |
| `git/ignore` | `~/.config/git/ignore` | 复制，已存在则跳过 |
| `git/config` | `~/.gitconfig` | 复制，已存在则跳过 |
| `atuin/config.toml` | `~/.config/atuin/config.toml` | 复制，已存在则跳过 |
| `templates/mise_config.toml` | `~/.config/mise/config.toml` | 占位符替换后复制，重配覆盖 |
| `btop/btop.conf` | `~/.config/btop/btop.conf` | 复制，已存在则跳过 |
| `infat/config.toml` | `~/.config/infat/config.toml` | 复制，已存在则跳过 |

## Ghostty

Ghostty 使用纯文本配置文件 `~/Library/Application Support/com.mitchellh.ghostty/config`，修改后通过 `ghostty +reload-config` 或快捷键（Cmd+Shift+,）即时生效，无需重启。

## Shell 别名

| 别名 | 命令 | 说明 |
|---|---|---|
| `ls` | `eza --hyperlink --icons` | 现代 ls |
| `ll` | `eza -la --hyperlink --icons` | 详细列表 |
| `lt` | `eza --tree --hyperlink --icons` | 目录树 |
| `hh` | `atuin search -i` | 历史搜索 |
| `lg` | `lazygit` | Git TUI |
| `y` | yazi 包装函数 | 文件管理器 |
| `k` | `kubectl` | Kubernetes |
| `kctx` | `kubectx` | 切换 context |
| `kns` | `kubens` | 切换 namespace |

完整 kubectl 别名见 `init.zsh`。

## 敏感信息

`~/.zsh_secrets` 不纳入版本控制。首次安装会从模板创建，需手动编辑填入实际值。

## 定制指引

| 想修改什么 | 编辑哪里 | 生效方式 |
|---|---|---|
| Shell 别名/函数/工具激活/prompt | `DOTFILES_ROOT/init.zsh` | 重开终端自动生效 |
| zim 插件列表 | `DOTFILES_ROOT/zsh/zimrc` -> 重配部署后 `zimfw install` | `exec zsh` |
| 环境变量 | `~/.zshenv`（本机），同步回仓库时改回占位符 | `exec zsh` |
| 添加/移除软件 | `DOTFILES_ROOT/Brewfile`，然后 `brew bundle install` | 立即生效 |
| VSCode 扩展 | `DOTFILES_ROOT/Brewfile` 的 `vscode` 段，然后 `brew bundle install` | 立即生效 |
| 文件关联 | `~/.config/infat/config.toml`，然后 `infat` | 立即生效 |
| 终端外观 | `~/Library/Application Support/com.mitchellh.ghostty/config` | `ghostty +reload-config` |
| 提示符样式 | `~/.config/starship.toml` | 重开终端 |
| API 密钥等敏感信息 | `~/.zsh_secrets` | `exec zsh` |

## 同步回仓库

`init.zsh` 直接 commit，无需复制。

对于已部署后在本机修改的文件（如 `~/.zshenv`），同步回仓库前必须：
1. 将 `CODE_LANGUAGES_HOME` 绝对路径改回 `__STORAGE_ROOT__/Languages`
2. 将 `OLLAMA_MODELS` 绝对路径改回 `__STORAGE_ROOT__/ollama/models`
3. 将 `DOTFILES_ROOT` 绝对路径改回 `__DOTFILES_ROOT__`
4. 运行 `rg '__STORAGE_ROOT__|__DOTFILES_ROOT__' $DOTFILES_ROOT --include='*.zsh' --include='*.toml'`，确认仅命中模板文件（zsh/zshenv、templates/mise_config.toml）
5. 禁止 `export STORAGE_ROOT` 出现在任何提交文件中

## 占位符与路径职责

| 范围 | 说明 |
|---|---|
| 仓库模板（含占位符） | 仅 `zsh/zshenv`（`__STORAGE_ROOT__` + `__DOTFILES_ROOT__`）、`templates/mise_config.toml`（`__STORAGE_ROOT__`）。禁止 `mise/config.toml`，否则 mise 在 dotfiles 目录内会自动加载 |
| 部署后 `~/.zshenv` | `CODE_LANGUAGES_HOME`、`OLLAMA_MODELS` 为绝对路径；`DOTFILES_ROOT` 为仓库绝对路径；其余变量经 `$CODE_LANGUAGES_HOME` 派生 |
| 部署后 `~/.config/mise/config.toml` | `[env]` 为绝对路径（供 shims/IDE）；`[tools]` 无路径 |
| 不含占位符的文件 | `zshrc`（仅引导）、`zprofile`、`zimrc`、`ghostty`、`starship`、`atuin`、`git/*`、`infat`、`btop`、`ripgrep`、`yazi`——依赖 shell 环境变量或固定系统路径 |
| 不复制直接加载 | `init.zsh`——由 zimfw 通过 `$DOTFILES_ROOT` 路径加载，无需部署 |
| 存储根布局 | `NEW_ROOT/Code/`（代码仓库）、`NEW_ROOT/Languages/`（工具链）、`NEW_ROOT/ollama/`（模型） |

## 存储位置与迁移

存储根（`Languages/`、`ollama/`）由初始化时选择；部署后路径以 `~/.zshenv` 的 `CODE_LANGUAGES_HOME`、`OLLAMA_MODELS` 及 `~/.config/mise/config.toml` 中的绝对路径为准。无外置磁盘用家目录绝对路径；有独立卷可用 `/Volumes/Storage` 等。

迁移到新位置：重新对 AI 发送初始化 prompt，它会从 `CODE_LANGUAGES_HOME` 等推导当前根、询问新位置、搬移数据并覆盖配置文件。手动迁移：`mv` 旧 `Languages/`、`ollama/` 到新根，把上述文件中的旧绝对路径改为新根，`exec zsh` 生效。跨卷移动会复制+删除，注意目标卷空间。
