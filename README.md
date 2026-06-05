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
所有配置文件是复制到目标路径，不是 symlink，复制后本地独立于仓库。
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

复制下列文件到目标路径。

**含 `__STORAGE_ROOT__` 占位符的仓库文件（写入系统前全文替换为 NEW_ROOT，禁止保留占位符、禁止 export STORAGE_ROOT）：**
- `zsh/zshenv`（`CODE_LANGUAGES_HOME`、`OLLAMA_MODELS` 两处字面量；其余经 `$CODE_LANGUAGES_HOME` 派生）
- `templates/mise_config.toml`（`[env]` 段全部路径）

其余配置文件无存储根占位符，路径在运行时由 `~/.zshenv` 环境变量提供（atuin/zoxide/starship/helm 等）。映射表：

| 仓库文件 | 目标路径 |
|---|---|
| zsh/zshenv | ~/.zshenv |
| zsh/zshrc | ~/.zshrc |
| zsh/zprofile | ~/.zprofile |
| zsh/zimrc | ~/.zimrc |
| ghostty/config | ~/Library/Application Support/com.mitchellh.ghostty/config |
| starship/starship.toml | ~/.config/starship.toml |
| ripgrep/config | ~/.config/ripgrep/config |
| yazi/keymap.toml | ~/.config/yazi/keymap.toml |
| git/ignore | ~/.config/git/ignore |
| git/config | ~/.gitconfig |
| atuin/config.toml | ~/.config/atuin/config.toml |
| templates/mise_config.toml | ~/.config/mise/config.toml |
| btop/btop.conf | ~/.config/btop/btop.conf |
| infat/config.toml | ~/.config/infat/config.toml |

规则：
- 目标不存在：创建父目录，复制文件
- `zsh/zshenv`、`templates/mise_config.toml`：写入前把 `__STORAGE_ROOT__` 全部替换为 NEW_ROOT，然后**无论目标是否存在一律覆盖**（首次部署、重配、迁移均如此）
- 其余文件：目标已存在则跳过并询问用户是否 diff 对比差异
- 仓库路径相对于 DOTFILES_ROOT

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
zsh -c "source ~/.zim/zimfw.zsh install"
```

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
2. 14 个配置文件全部存在；`rg __STORAGE_ROOT__ $DOTFILES_ROOT` 仅命中仓库模板（已部署的 `~/.zshenv`、`~/.config/mise/config.toml` 无占位符）；无 `export STORAGE_ROOT`；`CODE_LANGUAGES_HOME` 为 `NEW_ROOT/Languages`
3. Ghostty 配置文件存在（~/Library/Application Support/com.mitchellh.ghostty/config）
4. ~/.zsh_secrets 存在且权限为 600
5. NEW_ROOT/Languages/ 下目录结构完整，NEW_ROOT/ollama/models 存在
6. ~/.zim/zimfw.zsh 存在
7. 当前默认 shell 为 /opt/homebrew/bin/zsh（dscl . -read ~/ UserShell）
8. starship prompt 可用（command -v starship）
9. infat 文件关联已应用（infat info --ext json 输出包含 Visual Studio Code）
10. VSCode 扩展已安装（code --list-extensions | wc -l 大于 0）

## 8. 后续提醒

告知用户：
- 编辑 ~/.zsh_secrets 填入 API 密钥等敏感信息
- 重启终端或执行 exec zsh 使配置生效
- 运行 mise install 安装语言运行时（Node.js、Python 等）
- 打开 VSCode 登录 GitHub 以激活 Copilot
````

## 目录结构

```
dotfiles/
├── Brewfile                # Homebrew 软件清单
├── zsh/
│   ├── zshenv              # 环境变量（所有 shell）
│   ├── zshrc               # 交互式 shell 配置
│   ├── zprofile            # 登录 shell 配置
│   └── zimrc               # zimfw 插件列表
├── ghostty/
│   └── config                  # Ghostty 终端配置
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
    ├── mise_config.toml     # mise 配置模板（部署到 ~/.config/mise/config.toml）
    └── zsh_secrets.template # 敏感信息模板
```

## 文件映射

仓库文件作为初始模板复制到系统路径，首次安装后本地文件独立于仓库。

| 仓库文件 | 系统路径 |
|---|---|
| `zsh/zshenv` | `~/.zshenv` |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/zprofile` | `~/.zprofile` |
| `zsh/zimrc` | `~/.zimrc` |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `ripgrep/config` | `~/.config/ripgrep/config` |
| `yazi/keymap.toml` | `~/.config/yazi/keymap.toml` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/config` | `~/.gitconfig` |
| `atuin/config.toml` | `~/.config/atuin/config.toml` |
| `templates/mise_config.toml` | `~/.config/mise/config.toml` |
| `btop/btop.conf` | `~/.config/btop/btop.conf` |
| `infat/config.toml` | `~/.config/infat/config.toml` |

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

完整 kubectl 别名见 `zsh/zshrc`。

## 敏感信息

`~/.zsh_secrets` 不纳入版本控制。首次安装会从模板创建，需手动编辑填入实际值。

## 定制指引

配置文件复制到系统路径后即为本地独立副本，直接编辑系统路径下的文件即可。

| 想修改什么 | 编辑哪个文件 |
|---|---|
| 添加/移除软件 | `Brewfile`，然后 `brew bundle install --file=<dotfiles>/Brewfile` |
| 清理系统中多余的软件 | `brew bundle cleanup --force --file=<dotfiles>/Brewfile` |
| VSCode 扩展 | `Brewfile` 的 `vscode` 段，然后 `brew bundle install` |
| 文件关联 | `~/.config/infat/config.toml`，然后 `infat` 应用 |
| 终端外观 | `~/Library/Application Support/com.mitchellh.ghostty/config`，修改后 Cmd+Shift+, 生效 |
| Shell 别名/函数 | `~/.zshrc` |
| 环境变量 | `~/.zshenv` |
| 提示符样式 | `~/.config/starship.toml` |
| API 密钥等敏感信息 | `~/.zsh_secrets` |

如需将本地改动同步回仓库模板，手动将修改后的文件复制回 dotfiles 仓库对应路径，然后 commit push。

**同步回仓库前（必做）**：在 dotfiles 仓库内执行 `rg '__STORAGE_ROOT__|/Volumes/Storage'`，除 README/CLAUDE 示例外不得出现本机绝对路径。将 `~/.zshenv`、`~/.config/mise/config.toml` 复制到仓库的 `zsh/zshenv`、`templates/mise_config.toml`，并把存储根绝对路径**全部**改回 `__STORAGE_ROOT__`，勿引入 `export STORAGE_ROOT`。

## 占位符与路径职责

| 范围 | 说明 |
|---|---|
| 仓库模板 | 仅 `zsh/zshenv`、`templates/mise_config.toml` 含 `__STORAGE_ROOT__` |
| 部署后 `~/.zshenv` | `CODE_LANGUAGES_HOME`、`OLLAMA_MODELS` 为绝对路径；其余语言/CLI 变量经 `$CODE_LANGUAGES_HOME` 派生 |
| 部署后 `~/.config/mise/config.toml` | `[env]` 为绝对路径（供 shims/IDE）；`[tools]` 无存储路径 |
| 不写入存储根的文件 | `zshrc`、`zprofile`、`zimrc`、`ghostty`、`starship`、`atuin`、`git/*`、`infat`、`btop`、`ripgrep`、`yazi` 等——依赖 shell 环境变量或固定系统路径 |
| 存储根布局 | `NEW_ROOT/Code/`（代码仓库）、`NEW_ROOT/Languages/`（工具链）、`NEW_ROOT/ollama/`（模型） |

## 存储位置与迁移

存储根（`Languages/`、`ollama/`）由初始化时选择；部署后路径以 `~/.zshenv` 的 `CODE_LANGUAGES_HOME`、`OLLAMA_MODELS` 及 `~/.config/mise/config.toml` 中的绝对路径为准。无外置磁盘用家目录绝对路径；有独立卷可用 `/Volumes/Storage` 等。

迁移到新位置：重新对 AI 发送初始化 prompt，它会从 `CODE_LANGUAGES_HOME` 等推导当前根、询问新位置、搬移数据并覆盖配置文件。手动迁移：`mv` 旧 `Languages/`、`ollama/` 到新根，把上述文件中的旧绝对路径改为新根，`exec zsh` 生效。跨卷移动会复制+删除，注意目标卷空间。
