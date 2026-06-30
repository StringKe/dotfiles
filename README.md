# dotfiles

macOS 开发环境配置的**只读模板仓库**。

仓库内文件是模板源，通过 `bin/deploy.sh` 复制（+ 占位符替换）到用户 home。仓库不被用户 shell 直接读取（唯一例外：`git/config` 由 `~/.gitconfig` 的 `[include]` 引用）。

主题统一 **GitHub Light Colorblind**（橙色替代红，蓝色替代绿，避红绿色盲混淆），覆盖 ghostty / starship / btop / yazi / atuin / bat / fzf / vscode。

## 前置准备

```bash
# 1. Xcode CLT
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. 克隆仓库
mkdir -p /Volumes/Storage/Code/SelfCode
git clone https://github.com/StringKe/dotfiles.git /Volumes/Storage/Code/SelfCode/dotfiles
```

## 部署（推荐：直接调脚本）

```bash
cd /Volumes/Storage/Code/SelfCode/dotfiles

# 首次部署或重配。STORAGE_ROOT 是绝对路径（如 /Volumes/Storage 或 $HOME 的字面展开）
bin/deploy.sh init /Volumes/Storage

# 软件
brew bundle install --file=$PWD/Brewfile

# 应用 shell（启动新 shell）
exec zsh

# zim 模块 + 语言运行时
zimfw install
mise install

# 第三方主题（btop / atuin）
bin/install-themes.sh

# 文件关联（代码文件 → VS Code；跑完必须恢复浏览器 handler）
infat --config ~/.config/infat/config.toml
bin/fix-browser-handlers.sh

# 默认 shell
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh

# 验证
bin/deploy.sh check
```

## 通过 AI 初始化 / 更新

把以下提示词发给 AI 助手（Claude Code / Cursor / Codex 等）。AI 会按 CONSUMER 模式（只读仓库）操作，自动分流"首次部署 / 重配 / 迁移 / 拉新版本更新"四种场景。

````
你正在帮助用户操作 dotfiles 仓库（已克隆到本机, 记为 DOTFILES_ROOT）。仓库是只读模板, 部署产物在 ~/。

## 1. 角色 (HARD RULES)

你是 CONSUMER。允许:
- 读 DOTFILES_ROOT 任何文件
- 调用 DOTFILES_ROOT/bin/deploy.sh, DOTFILES_ROOT/bin/install-themes.sh
- 修改 ~/ 下的部署产物 (~/.zshenv / ~/.config/...)
- 运行 brew / zimfw / mise / infat / git pull 等外部工具

禁止:
- 在 DOTFILES_ROOT 内新建任何文件 (含临时脚本 / patch / .env / 备份)
- 修改 DOTFILES_ROOT 内任何现有文件
- git add / commit / push 操作仓库 (除非用户明确说"提交"且声明 MAINTAINER 模式)
- 把本机绝对路径回写到模板 (必须保留 __STORAGE_ROOT__ / __DOTFILES_ROOT__ 占位符)
- 自己手写 sed 命令做占位符替换 (必须调 bin/deploy.sh init)

## 2. 定位 DOTFILES_ROOT

依次检测含 Brewfile 的目录:
1. $HOME/Code/SelfCode/dotfiles
2. /Volumes/Storage/Code/SelfCode/dotfiles
3. $HOME/Code/ 下 find Brewfile

均无则告知用户先 git clone (README 前置准备)。

## 3. 判定场景

读 ~/.zshenv:
- 不存在               -> 场景 A 首次部署
- 含未替换占位符       -> 场景 A 首次部署 (上次部署没完成)
- 已部署 (有 DOTFILES_ROOT export) -> 进 3a 进一步判定

### 3a. 已部署机器场景判定

询问用户意图 (单选):
- "我克隆了新机器, 帮我初始化"         -> 场景 A 首次部署
- "我换存储位置, 比如从 $HOME 搬到 /Volumes/Storage" -> 场景 C 迁移
- "我 git pull 了新版本仓库, 帮我应用"  -> 场景 D 更新 (跳到 5)
- "我没改什么, 想重新跑一遍部署修复一下" -> 场景 B 重配

### 3b. 询问 NEW_ROOT (仅场景 A/B/C 需要)

候选:
- /Volumes/Storage (USB 外置盘)
- $HOME 的绝对值 (如 /Users/<username>)

要求: 绝对路径, 不接受 ~ 或 $HOME 字面。

判定:
| 场景 | 条件 | 动作 |
|---|---|---|
| A 首次 | 无 CURRENT_ROOT | 直接 bin/deploy.sh init NEW_ROOT |
| B 重配 | CURRENT_ROOT == NEW_ROOT | bin/deploy.sh init NEW_ROOT |
| C 迁移 | CURRENT_ROOT != NEW_ROOT | 先迁数据 (见 4), 再 bin/deploy.sh init NEW_ROOT |

## 4. 数据迁移 (仅场景 C)

输出迁移分析表 (源 / 目标 / 大小 / 跨卷)。用户确认后:
1. df -h 看目标卷剩余
2. mkdir -p NEW_ROOT
3. 逐目录 mv (目标已存在则停下询问)
4. 完成后让用户验证新位置可用, 再自行清理旧位置

## 5. 更新场景 (D) - 拉新版本应用

只在场景 D 走此节, 场景 A/B/C 跳到 6。

### 5a. 拉新版本

```bash
cd $DOTFILES_ROOT
git fetch origin
git log --oneline HEAD..origin/main           # 看本机落后多少 commit
```

如果输出为空 -> 已是最新, 告知用户无需操作, 结束。

询问用户是否拉取:
```bash
git pull --ff-only origin main
```

如果含 untracked / dirty -> 告知用户先 stash 或 commit, 不强行覆盖。

### 5b. 分析改动类型 (决定要跑什么)

跑 git diff --name-only HEAD@{1}..HEAD 看本次更新动了哪些文件。按以下规则分流, 每条命中就跑对应命令:

| 改动文件 | 对应命令 | 说明 |
|---|---|---|
| init.zsh | bin/deploy.sh sync | 复制到 ~/.zsh/init.zsh |
| zsh/zshenv | bin/deploy.sh init <CURRENT_ROOT> | 覆盖 ~/.zshenv (含占位符替换) |
| zsh/zprofile, zsh/zshrc | bin/deploy.sh init <CURRENT_ROOT> | 直接覆盖 |
| zsh/zimrc | bin/deploy.sh init <CURRENT_ROOT> + zimfw install | 模块清单变了 |
| templates/mise_config.toml | bin/deploy.sh init <CURRENT_ROOT> | 覆盖 ~/.config/mise/config.toml |
| Brewfile | brew bundle install --file=$DOTFILES_ROOT/Brewfile | 装新软件 (vscode 扩展不再托管, AI CLI 走 curl) |
| ghostty/, starship/, btop/, atuin/, yazi/, bat/ | bin/deploy.sh init <CURRENT_ROOT> | 仅首次部署文件, 已存在不覆盖 (见 5c) |
| ripgrep/, infat/, git/ignore | bin/deploy.sh init <CURRENT_ROOT> | 同上 |
| git/config | 无操作 | ~/.gitconfig [include] 引用, 自动生效 |
| bin/* | 无操作 | 脚本下次调用时生效 |
| debug/profile.zsh | 无操作 | 仅 ZSH_PROFILE=1 时被 source |
| CLAUDE.md, README.md, docs/* | 无操作 | 仅文档 |

### 5c. 主题或仅首次覆盖类文件改动 (重要)

ghostty / starship / btop / atuin / yazi / bat / ripgrep / infat 走 deploy_if_absent (已存在跳过)。如果仓库改了它们 (如主题切换), 用户本机老版本不会被覆盖。

需要先删本机旧版再重跑 deploy:

```bash
# 询问用户是否覆盖 (有自定义会丢)
rm ~/.config/<对应文件>
bin/deploy.sh init <CURRENT_ROOT>
```

主题文件 (btop / atuin 的 .theme) 还要跑:
```bash
bin/install-themes.sh
```

### 5d. 应用更新

```bash
exec zsh                                  # 重载 shell, 所有 zsh/* 改动生效
ghostty +reload-config 2>/dev/null || true # ghostty 主题改动
```

跳过 6, 直接到 7 验证。

## 6. 部署 (场景 A/B/C)

```bash
bin/deploy.sh init <NEW_ROOT>
brew bundle install --file=$DOTFILES_ROOT/Brewfile
bin/install-themes.sh
exec zsh
zimfw install
mise install
infat --config ~/.config/infat/config.toml
bin/fix-browser-handlers.sh
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh
```

## 7. 验证

跑 bin/deploy.sh check, 报告通过 / 失败项。额外检查:
- echo $DOTFILES_ROOT 输出仓库绝对路径
- ~/.zshrc 末尾含 source ~/.zsh/init.zsh
- ~/.zim/modules/ 含 zsh-syntax-highlighting / autosuggestions / fzf-tab 等
- ghostty 主题: grep '^theme' "$HOME/Library/Application Support/com.mitchellh.ghostty/config" 输出 GitHub Light Colorblind
- starship: 不指定 palette, 跟随终端 ANSI 配色 (见 starship/starship.toml 注释)

## 8. 提醒

- 编辑 ~/.zsh_secrets 填密钥 (首次部署时 cp 自空白模板)
- 仓库主人编辑 init.zsh 后跑 bin/deploy.sh sync 同步 ~/.zsh/init.zsh
- ZSH_PROFILE=1 启用启动 timing 调试 (用完 unset 或删 ~/.zshenv 那行)
````

## 仓库结构

```
dotfiles/
├── bin/
│   ├── deploy.sh           部署主脚本
│   └── install-themes.sh   第三方主题下载（btop / atuin）
├── debug/
│   └── profile.zsh         ZSH_PROFILE=1 启用的启动 timing 调试
├── zsh/                    [TEMPLATE] zsh 入口
├── init.zsh                [TEMPLATE] 交互式配置 -> ~/.zsh/init.zsh
├── templates/              [TEMPLATE] 含占位符的模板
├── ghostty/                [TEMPLATE] 终端
├── starship/               [TEMPLATE] 提示符
├── btop/                   [TEMPLATE] 系统监控
├── yazi/                   [TEMPLATE] 文件管理器
├── atuin/                  [TEMPLATE] 历史搜索
├── bat/                    [TEMPLATE] cat 替代
├── vscode/settings.json    [TEMPLATE] 主题 + 字体 + 基础项（jq merge 到本机）
├── ripgrep/                [TEMPLATE] grep 替代
├── infat/                  [TEMPLATE] 文件关联
├── git/                    [TEMPLATE] git 通用配置（include 引用，不复制）
├── Brewfile                软件清单
├── CLAUDE.md               AI 协作规则
└── README.md               本文件
```

## 常用别名

| 别名 | 说明 |
|---|---|
| `ls` / `ll` / `lt` | eza（现代 ls） |
| `hh` | atuin 历史搜索 |
| `lg` | lazygit |
| `y` | yazi（退出时切到 cwd） |
| `k` 系列 | kubectl 快捷（kgp / kl / kaf 等，详见 init.zsh） |

## 演进流程（MAINTAINER）

修改仓库内容前明确告知 AI："这是 MAINTAINER 模式，修改仓库 X。"

| 想改什么 | 编辑哪 | 同步方式 |
|---|---|---|
| 别名 / 函数 / 工具激活 / prompt | `init.zsh` | `bin/deploy.sh sync` |
| zim 插件列表 | `zsh/zimrc` | 重新部署 + `zimfw install` |
| 环境变量 | `zsh/zshenv`（**保留占位符**） | `bin/deploy.sh init <ROOT>` |
| 软件清单 | `Brewfile` | `brew bundle install` |
| 终端主题 | `ghostty/config` | 重新部署 |
| 提示符 | `starship/starship.toml` | 重新部署 |
| Git 通用配置 | `git/config` | 自动生效（`[include]` 引用） |

不论 MAINTAINER 还是 CONSUMER，**绝不**:
- 把部署版绝对路径回写到模板
- 把 `~/.zsh_secrets` 内实际密钥写到 `templates/zsh_secrets.template`
- 在仓库内创建临时文件 / 备份 / .env

## 调试

```bash
# 测启动 timing
ZSH_PROFILE=1 zsh -i -l -c exit

# 长期开启（看每次 cd / clear 的 hook 耗时）
echo 'export ZSH_PROFILE=1' >> ~/.zshenv
# 开新窗口，输出 [prof*] 行
# 用完: sed -i '' '/export ZSH_PROFILE=1/d' ~/.zshenv
```

详见 `debug/profile.zsh` 顶部说明。
