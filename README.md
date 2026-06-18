# dotfiles

macOS 开发环境配置的**只读模板仓库**。

仓库内文件是模板源，通过 `bin/deploy.sh` 复制（+ 占位符替换）到用户 home。仓库不被用户 shell 直接读取（唯一例外：`git/config` 由 `~/.gitconfig` 的 `[include]` 引用）。

主题统一 **Catppuccin Latte**（light），覆盖 ghostty / starship / btop / yazi / atuin / bat / fzf / vscode。

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

# 文件关联
infat --config ~/.config/infat/config.toml

# 默认 shell
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh

# 验证
bin/deploy.sh check
```

## 通过 AI 初始化

把以下提示词发给 AI 助手。AI 会按 CONSUMER 模式（只读仓库）操作，遇到决策点（NEW_ROOT / 迁移）问用户。

````
你正在帮助用户初始化或更新 macOS 开发环境。dotfiles 仓库已克隆到本机，记为 DOTFILES_ROOT。

## 1. 角色

你是 CONSUMER。允许:
- 读 DOTFILES_ROOT 任何文件
- 调用 bin/deploy.sh, bin/install-themes.sh
- 修改 ~/ 下的部署产物
- 运行 brew / zimfw / mise / infat 等外部工具

禁止:
- git add / commit / push 操作仓库
- 在 DOTFILES_ROOT 内新建或修改任何文件
- 把本机绝对路径回写到模板（必须保留 __STORAGE_ROOT__ / __DOTFILES_ROOT__ 占位符）
- 自己手写 sed 命令做占位符替换（必须调 bin/deploy.sh init）

## 2. 定位 DOTFILES_ROOT

依次检测含 Brewfile 的目录：
1. $HOME/Code/SelfCode/dotfiles
2. /Volumes/Storage/Code/SelfCode/dotfiles
3. $HOME/Code/ 下 find Brewfile

均无则告知用户先 git clone（README 前置准备）。

## 3. 判定首次 / 重配 / 迁移

读 ~/.zshenv:
- 不存在 -> 首次部署
- 含 export CODE_LANGUAGES_HOME=".../Languages" -> 取出 CURRENT_ROOT（去掉末尾 /Languages）
- 含未替换占位符 -> 当作首次部署

询问用户 NEW_ROOT（绝对路径，不接受 ~ 或 $HOME 字面）。候选：
- /Volumes/Storage（USB 外置盘）
- $HOME 的绝对值（如 /Users/<username>）

判定：
| 情形 | 条件 | 动作 |
|---|---|---|
| 首次 | 无 CURRENT_ROOT | 直接 bin/deploy.sh init NEW_ROOT |
| 重配 | CURRENT_ROOT == NEW_ROOT | bin/deploy.sh init NEW_ROOT |
| 迁移 | CURRENT_ROOT != NEW_ROOT | 先迁数据（见 4），再 bin/deploy.sh init NEW_ROOT |

## 4. 数据迁移（仅 NEW_ROOT != CURRENT_ROOT）

输出迁移分析表（源 / 目标 / 大小 / 跨卷）。用户确认后:
1. df -h 看目标卷剩余
2. mkdir -p NEW_ROOT
3. 逐目录 mv（目标已存在则停下询问）
4. 完成后让用户验证新位置可用，再自行清理旧位置

## 5. 部署

```bash
bin/deploy.sh init <NEW_ROOT>
brew bundle install --file=$DOTFILES_ROOT/Brewfile
bin/install-themes.sh
```

## 6. 后续

```bash
exec zsh
zimfw install
mise install
infat --config ~/.config/infat/config.toml
grep -qF /opt/homebrew/bin/zsh /etc/shells || echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh
bin/deploy.sh check
```

## 7. 验证

跑 bin/deploy.sh check，报告通过 / 失败项。额外检查:
- echo $DOTFILES_ROOT 输出仓库绝对路径
- which proto 输出 ~/.proto/bin/proto
- ~/.zshrc 末尾含 source ~/.zsh/init.zsh
- ~/.zim/modules/ 含 zsh-syntax-highlighting / autosuggestions / fzf-tab 等

## 8. 提醒

- 编辑 ~/.zsh_secrets 填密钥
- 编辑仓库 init.zsh 后跑 bin/deploy.sh sync 同步到 ~/.zsh/init.zsh
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
