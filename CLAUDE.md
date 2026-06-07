# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

macOS 开发环境 dotfiles 模板仓库。大部分配置文件**复制到系统路径**，不使用 symlink。例外：`init.zsh` 不复制，而是由 zimfw 作为本地模块直接从仓库路径加载（通过 `zmodule $DOTFILES_ROOT`），修改后立即生效，无需重新部署。

## 常用命令

```bash
# 安装/同步所有软件
brew bundle install --file=$DOTFILES_ROOT/Brewfile

# 清理系统中 Brewfile 未声明的软件
brew bundle cleanup --force --file=$DOTFILES_ROOT/Brewfile

# 安装/更新 zim 模块（新增模块后必须运行）
zimfw install

# 重新生成 zim 初始化脚本（zimrc 变化后必须运行，或重开终端自动触发）
zimfw init

# 应用文件关联配置
infat --config ~/.config/infat/config.toml

# 安装语言运行时（mise 管理的 Node.js / Rust / Go / uv）
mise install
```

## 架构

### 部署模型

仓库是模板源，通过 README 中的 AI 引导 prompt 执行初始化。

**复制部署（copy-once）的文件：**
- `zsh/zshenv` -> `~/.zshenv`（存储根路径展开后复制，重配时覆盖）
- `zsh/zprofile` -> `~/.zprofile`（重配时覆盖）
- `zsh/zshrc` -> `~/.zshrc`（仅 zimfw 引导，极少变动，重配时覆盖）
- `zsh/zimrc` -> `~/.zimrc`（插件列表，重配时覆盖）
- 所有非 zsh 工具配置（ghostty、starship、atuin、git、btop、infat、yazi、ripgrep）-> 各自系统路径

**直接从仓库加载（无需复制）的文件：**
- `init.zsh` - zimfw 本地模块入口，包含全部交互式 shell 配置。通过 `~/.zimrc` 中的 `zmodule $DOTFILES_ROOT` 加载。**修改 `init.zsh` 立即生效，重开终端即可。**
- `git/config` - 通用 Git 配置（gpg/commit/credential 等，无身份）。通过本机 `~/.gitconfig` 的 `[include] path` 引用，**不整体复制**。本机 `~/.gitconfig` 只放 `[user]`（身份/签名密钥）和 `[filter "lfs"]` 等机器特有字段。修改仓库 `git/config` 立即对所有 include 它的机器生效。

### Shell 加载顺序

```
~/.zshenv      <- 所有 shell（含非交互式脚本）: 环境变量 / PATH / DOTFILES_ROOT
~/.zprofile    <- 登录 shell（在 zshrc 前）: Homebrew env / mise --shims（IDE 专用）
~/.zshrc       <- 交互式 shell: 仅 zimfw 引导（10 行），不含任何配置
  ~/.zimrc     <- zimfw 模块列表（由 zshrc 内的 zimfw 加载）
    -> zim 模块按顺序初始化: environment, input, completions, fzf-tab, direnv, ...
    -> zmodule $DOTFILES_ROOT -> dotfiles/init.zsh 被加载（交互式 shell 全部配置在此）
```

**各文件职责：**
- `~/.zshenv`：环境变量和 PATH，任何地方都能用的值（DOTFILES_ROOT / CODE_LANGUAGES_HOME / GOPATH 等）
- `~/.zprofile`：Homebrew shellenv + mise --shims（仅非交互式登录 shell）
- `~/.zshrc`：zimfw 引导，不放其他任何内容
- `dotfiles/init.zsh`：所有交互式配置（OrbStack / mise activate / fzf / atuin / zoxide / fzf-tab 样式 / kubectl 别名 / eza/fd 别名 / rm 包装 / y() / secrets / starship）

### proto + mise 工具版本管理

**分工原则：**
- `mise activate zsh`（在 `init.zsh` 中）：全局运行时版本管理（node / go / rust / python），通过 precmd hook 在每次 prompt 前重置 PATH，始终优先
- `~/.proto/bin`（在 PATH 中）：proto CLI 本身
- `~/.proto/shims`（在 PATH 中）：proto 管理的工具（atlas / buf / cosign / sops 等 proto-only 工具）
  - shims 是智能 shim：有 `.prototools` 配置时用配置版本，无配置时自动回退到 PATH 其余位置的同名工具（即 mise 版本）
  - mise 的 precmd hook 对共享工具（node / go）始终优先于 proto shims

**不使用 `proto activate`** 的原因：proto activate 只注册 `chpwd_functions`，而 mise activate 同时注册 `chpwd_functions`（追加到末位）和 `precmd_functions`。mise 的 precmd hook 在每次 Enter 前重置 PATH，永远覆盖 proto 的 chpwd 效果。proto-shim 内置 fallback 逻辑，不依赖 `proto activate` 设置的 `__ORIG_PATH`。

### 存储根占位符

`zsh/zshenv` 和 `templates/mise_config.toml` 含两类占位符，部署时由 AI 全文替换：

| 占位符 | 替换为 | 影响变量 |
|---|---|---|
| `__STORAGE_ROOT__` | 用户选择的存储根绝对路径 | CODE_LANGUAGES_HOME、OLLAMA_MODELS |
| `__DOTFILES_ROOT__` | dotfiles 仓库绝对路径 | DOTFILES_ROOT |

**规则：**
- 禁止 `export STORAGE_ROOT`（无此变量）
- `DOTFILES_ROOT` 是合法变量（zimfw 模块加载需要）
- `rg '__STORAGE_ROOT__|__DOTFILES_ROOT__'` 检查仓库：只应命中模板文件，不应出现在已部署的 `~/.zshenv`

### 同步回仓库

修改 `dotfiles/init.zsh` 直接 commit，无需手动复制。

修改 `~/.zshenv`（已部署版）同步回仓库：
1. 将 `CODE_LANGUAGES_HOME` 的绝对路径改回 `__STORAGE_ROOT__/Languages`
2. 将 `OLLAMA_MODELS` 的绝对路径改回 `__STORAGE_ROOT__/ollama/models`
3. 将 `DOTFILES_ROOT` 的绝对路径改回 `__DOTFILES_ROOT__`
4. `rg '__STORAGE_ROOT__|__DOTFILES_ROOT__'` 确认仅命中模板文件

### Git 签名

使用 1Password SSH 签名（`gpg.format = ssh`，`gpg.ssh.program` 指向 1Password）。commit 默认启用 GPG 签名。GitHub credential 通过 `gh auth git-credential` 管理。

签名机制和 credential 配置在仓库 `git/config`（通用），本机 `~/.gitconfig` 通过 `[include] path` 引用；`[user]` 身份和 `signingkey` 留在本机主文件，不进仓库。修改通用配置编辑 `git/config` 即对所有机器生效。

### Ghostty 终端配置

纯文本配置文件 `ghostty/config`，部署到 `~/Library/Application Support/com.mitchellh.ghostty/config`。修改后通过 `ghostty +reload-config` 即时生效。

### 敏感信息

`~/.zsh_secrets` 不纳入版本控制（`.gitignore` 排除），从 `templates/zsh_secrets.template` 复制创建，权限 600。
