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

1. `zsh/zshenv` -> `~/.zshenv`：环境变量（所有 shell 都加载）。顶部定义 `STORAGE_ROOT`（部署时替换占位符 `__STORAGE_ROOT__`）及派生的 `CODE_LANGUAGES_HOME`（`$STORAGE_ROOT/Languages`），以及 CLI 工具数据路径、各语言路径、Ollama、keg-only 编译标志、PATH
2. `zsh/zprofile` -> `~/.zprofile`：登录 shell。Homebrew shellenv、mise shims 模式（供 IDE/GUI 访问）
3. `zsh/zshrc` -> `~/.zshrc`：交互式 shell。Zim 插件管理器 -> OrbStack -> mise activate -> fzf -> Atuin -> zoxide -> direnv -> fzf-tab 样式 -> kubectl 别名 -> eza/fd 别名 -> Starship prompt
4. `zsh/zimrc` -> `~/.zimrc`：Zim 模块声明。加载顺序有约束：completions fpath -> compinit -> fzf-tab -> syntax-highlighting -> autosuggestions

### 语言环境路径

所有语言工具链统一存放在 `$STORAGE_ROOT/Languages/` 下（通过 `$CODE_LANGUAGES_HOME` 引用）。CLI 工具数据（zoxide/atuin/helm/starship）存放在 `$CODE_LANGUAGES_HOME/cli/`。`$STORAGE_ROOT` 由部署时替换占位符 `__STORAGE_ROOT__` 确定（本机为 `/Volumes/Storage`）。

### 存储根占位符

`zsh/zshenv` 顶部的 `STORAGE_ROOT` 与 `mise/config.toml` 中的语言缓存路径在仓库内是占位符 `__STORAGE_ROOT__`，初始化时由 README 的 AI prompt 替换为用户选择的绝对路径。`STORAGE_ROOT` 下固定三个子目录：`Code/`（代码仓库）、`Languages/`（语言工具链与缓存）、`ollama/`（模型）。

**同步回仓库须反替换**：把本地 `~/.zshenv`、`~/.config/mise/config.toml` 复制回仓库前，必须将真实存储根（如 `/Volumes/Storage`）改回 `__STORAGE_ROOT__`，否则会把本机路径污染进模板。新版 `~/.zshenv` 仅顶部 `STORAGE_ROOT` 一处需改（其余路径经 `$CODE_LANGUAGES_HOME` 派生）；`mise/config.toml` 改 `[env]` 段各路径。

**已部署旧机识别**：README Section 3a 会从 `STORAGE_ROOT`、`CODE_LANGUAGES_HOME`（去 `/Languages` 后缀）或 `OLLAMA_MODELS` 推导 CURRENT_ROOT，支持无 `STORAGE_ROOT` 的旧版 `~/.zshenv`。

### Git 签名

使用 1Password SSH 签名（`gpg.format = ssh`，`gpg.ssh.program` 指向 1Password）。commit 默认启用 GPG 签名。GitHub credential 通过 `gh auth git-credential` 管理。

### Ghostty 终端配置

纯文本配置文件 `ghostty/config`，部署到 `~/Library/Application Support/com.mitchellh.ghostty/config`。修改后通过 `ghostty +reload-config` 即时生效。

### 敏感信息

`~/.zsh_secrets` 不纳入版本控制（`.gitignore` 排除），从 `templates/zsh_secrets.template` 复制创建，权限 600。
