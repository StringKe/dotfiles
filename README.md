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

3. 克隆仓库：

```bash
git clone https://github.com/StringKe/dotfiles.git ~/Code/SelfCode/dotfiles
```

## 通过 AI 初始化

将以下提示词发送给 AI 助手（Claude Code、Cursor 等），它会读取仓库内容并智能执行全部初始化步骤。遇到冲突或错误时 AI 可自行判断处理，无需静态脚本的局限性。

````
## 1. 角色与上下文

你正在初始化一台 macOS 开发机。dotfiles 仓库已克隆到 ~/Code/SelfCode/dotfiles。
所有配置文件是复制到目标路径，不是 symlink，复制后本地独立于仓库。
按以下 Section 2-7 顺序执行，每步完成后报告状态。

## 2. 预检

验证以下条件，全部通过才继续：
- uname -s 为 Darwin
- xcode-select -p 成功
- command -v brew 成功
- ~/Code/SelfCode/dotfiles 目录存在且包含 Brewfile

任一失败则告知用户回到 README 的"前置准备"章节。

## 3. 软件安装

执行：
```bash
brew bundle install --file=~/Code/SelfCode/dotfiles/Brewfile
```

如果部分 formula/cask 安装失败，解释失败原因，继续安装其余项目。

## 4. 配置文件部署

按以下映射表复制文件：

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
| mise/config.toml | ~/.config/mise/config.toml |
| btop/btop.conf | ~/.config/btop/btop.conf |
| infat/config.toml | ~/.config/infat/config.toml |

规则：
- 目标不存在：创建父目录，复制文件
- 目标已存在：跳过，询问用户是否要 diff 对比差异
- 仓库路径相对于 ~/Code/SelfCode/dotfiles

## 5. 系统配置

### 5a. Secrets 文件

仅当 ~/.zsh_secrets 不存在时：
```bash
cp ~/Code/SelfCode/dotfiles/templates/zsh_secrets.template ~/.zsh_secrets
chmod 600 ~/.zsh_secrets
```

### 5b. 语言环境目录

```bash
mkdir -p ~/Code/Languages/{go,rust/{rustup,cargo},nodejs/{npm-cache,npm-global,pnpm-global,yarn-global},bun,deno,java/{gradle,maven-repo},python/{pip-cache,pipx,pipx/bin},php/composer}
```

### 5c. Zim 框架

```bash
curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
zsh -c "source ~/.zim/zimfw.zsh install"
```

### 5d. 文件关联

```bash
infat --config ~/.config/infat/config.toml
```

### 5e. 默认 Shell

```bash
# 将 Homebrew zsh 加入合法 shell 列表（如果不在）
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
# 切换默认 shell（需要用户密码）
chsh -s /opt/homebrew/bin/zsh
```

提示用户这一步需要输入密码。

## 6. 验证清单

逐项检查并报告通过/失败：
1. brew doctor 无严重警告
2. 14 个配置文件全部存在于目标路径
3. Ghostty 配置文件存在（~/Library/Application Support/com.mitchellh.ghostty/config）
4. ~/.zsh_secrets 存在且权限为 600
5. ~/Code/Languages/ 下目录结构完整
6. ~/.zim/zimfw.zsh 存在
7. 当前默认 shell 为 /opt/homebrew/bin/zsh（dscl . -read ~/ UserShell）
8. starship prompt 可用（command -v starship）
9. infat 文件关联已应用（infat info --ext json 输出包含 Visual Studio Code）
10. VSCode 扩展已安装（code --list-extensions | wc -l 大于 0）

## 7. 后续提醒

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
├── mise/
│   └── config.toml         # mise 运行时版本管理配置
├── btop/
│   └── btop.conf           # btop 系统监控配置
├── infat/
│   └── config.toml         # macOS 文件关联配置
└── templates/
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
| `ghostty/config` | `~/.config/ghostty/config` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `ripgrep/config` | `~/.config/ripgrep/config` |
| `yazi/keymap.toml` | `~/.config/yazi/keymap.toml` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/config` | `~/.gitconfig` |
| `atuin/config.toml` | `~/.config/atuin/config.toml` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
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
| 添加/移除软件 | `Brewfile`，然后 `brew bundle install --file=~/Code/SelfCode/dotfiles/Brewfile` |
| 清理系统中多余的软件 | `brew bundle cleanup --force --file=~/Code/SelfCode/dotfiles/Brewfile` |
| VSCode 扩展 | `Brewfile` 的 `vscode` 段，然后 `brew bundle install` |
| 文件关联 | `~/.config/infat/config.toml`，然后 `infat` 应用 |
| 终端外观 | `~/Library/Application Support/com.mitchellh.ghostty/config`，修改后 Cmd+Shift+, 生效 |
| Shell 别名/函数 | `~/.zshrc` |
| 环境变量 | `~/.zshenv` |
| 提示符样式 | `~/.config/starship.toml` |
| API 密钥等敏感信息 | `~/.zsh_secrets` |

如需将本地改动同步回仓库模板，手动将修改后的文件复制回 `~/Code/SelfCode/dotfiles/` 对应路径，然后 commit push。
