# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

macOS 开发环境 dotfiles 模板仓库。配置文件是**复制到系统路径**的，不使用 symlink，复制后本地独立于仓库。

## 常用命令

```bash
# 安装/同步所有软件（Homebrew formulae + cask + VSCode 扩展 + MAS 应用）
brew bundle install --file=~/Code/SelfCode/dotfiles/Brewfile

# 清理系统中 Brewfile 未声明的软件
brew bundle cleanup --force --file=~/Code/SelfCode/dotfiles/Brewfile

# 应用文件关联配置
infat --config ~/.config/infat/config.toml

# 安装 Zim 插件
zsh -c "source ~/.zim/zimfw.zsh install"

# 安装语言运行时（mise 管理的 Node.js / Rust / Go / uv）
mise install
```

## 架构

### 部署模型

仓库是模板源，通过 README 中的 AI 引导 prompt 执行初始化。文件按映射表复制到系统路径（`zsh/zshrc` -> `~/.zshrc` 等），之后本地文件与仓库独立。要同步改动回仓库需手动复制文件回来再 commit。

### Shell 加载顺序

1. `zsh/zshenv` -> `~/.zshenv`：环境变量（所有 shell 都加载）。`CODE_LANGUAGES_HOME`（`{存储根}/Languages`）与 `OLLAMA_MODELS`（`{存储根}/ollama/models`）在部署后为绝对路径；其余语言/CLI 路径经 `$CODE_LANGUAGES_HOME` 派生，以及 keg-only 编译标志、PATH
2. `zsh/zprofile` -> `~/.zprofile`：登录 shell。Homebrew shellenv、mise shims 模式（供 IDE/GUI 访问）
3. `zsh/zshrc` -> `~/.zshrc`：交互式 shell。Zim 插件管理器 -> OrbStack -> mise activate -> fzf -> Atuin -> zoxide -> direnv -> fzf-tab 样式 -> kubectl 别名 -> eza/fd 别名 -> Starship prompt
4. `zsh/zimrc` -> `~/.zimrc`：Zim 模块声明。加载顺序有约束：completions fpath -> compinit -> fzf-tab -> syntax-highlighting -> autosuggestions

### 语言环境路径

所有语言工具链统一存放在 `{存储根}/Languages/`（`$CODE_LANGUAGES_HOME`）。CLI 工具数据（zoxide/atuin/helm/starship）在 `$CODE_LANGUAGES_HOME/cli/`。Ollama 模型在 `{存储根}/ollama/models`（`$OLLAMA_MODELS`）。

### 存储根占位符 `__STORAGE_ROOT__`

**仅存在于仓库模板**（`zsh/zshenv`、`mise/config.toml`），不是运行时环境变量。初始化时由 README 的 AI prompt 在写入系统路径前，将文件中全部 `__STORAGE_ROOT__` 替换为用户选择的绝对路径。存储根下固定三个子目录：`Code/`、`Languages/`、`ollama/`。

**禁止**在已部署的 `~/.zshenv` 中 `export STORAGE_ROOT`。

**同步回仓库须反替换**：复制 `~/.zshenv`、`~/.config/mise/config.toml` 回仓库前，将存储根绝对路径（如 `/Volumes/Storage`）全部改回 `__STORAGE_ROOT__`。

**已部署机器识别**：README Section 3a 从 `CODE_LANGUAGES_HOME`（去 `/Languages`）或 `OLLAMA_MODELS`（去 `/ollama/models`）推导 CURRENT_ROOT。

### Git 签名

使用 1Password SSH 签名（`gpg.format = ssh`，`gpg.ssh.program` 指向 1Password）。commit 默认启用 GPG 签名。GitHub credential 通过 `gh auth git-credential` 管理。

### Ghostty 终端配置

纯文本配置文件 `ghostty/config`，部署到 `~/Library/Application Support/com.mitchellh.ghostty/config`。修改后通过 `ghostty +reload-config` 即时生效。

### 敏感信息

`~/.zsh_secrets` 不纳入版本控制（`.gitignore` 排除），从 `templates/zsh_secrets.template` 复制创建，权限 600。