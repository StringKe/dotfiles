---
name: worktree-done
description: "收尾 worktree：当前所在的、本会话 /worktree-start 新建的、用户点名的，逐个提交、rebase 到 origin 默认分支后快进推送、删除 worktree 与分支，最后让主检出的本地默认分支快进到最新。用户运行 /worktree-done 或 /worktree-done <名字> 时使用。"
user-invocable: true
disable-model-invocation: true
argument-hint: "[名字]"
---

# worktree 收尾

用户输入 `/worktree-done` 或 `/worktree-done <名字>` 即授权本次 commit 与快进推送到默认分支，不再逐项请示。只做收尾，不追加新功能。用 git worktree。不使用 Claude Code agents view。

默认分支：`git symbolic-ref --short refs/remotes/origin/HEAD` 得到 `origin/main` 这种形式，取斜杠后的名字。这条 ref 没有时，远程有 `main` 用 `main`，否则用 `master`。

## 1. 列出要收的 worktree

`git worktree list --porcelain` 列出全部，按归属分四类：

| 类别 | 怎么认 | 处理 |
|---|---|---|
| 当前所在 | `git rev-parse --show-toplevel` 在 `.claude/worktrees/<名字>/` 下 | 收尾 |
| 本会话新建 | 本会话 `/worktree-start` 进入或建的路径（含 EnterWorktree 返回的路径与分支），以及本会话子代理返回结果里给出的 worktree 路径与分支 | 收尾 |
| 用户点名 | `/worktree-done <名字>` 对应主检出下的 `.claude/worktrees/<名字>` | 收尾 |
| 其他 | 上面三类之外的，包括 `~/.cache/` 下的 detached worktree | 不动，只在报告里列出 |

- 会话在主检出，也没有本会话新建或用户点名的 worktree：只在主检出做第 3 至 6 步（没有本会话的改动就跳过），然后做第 8 步。
- 子代理还没有返回：不收，等它结束。用户要求立即收尾时把它列为 SKIP。子代理没有改动、目录已经不在时不用管。
- 目录和分支都已经不在：这是交互会话干净退出时的自动删除，记 SKIP，不重建。
- 先收本会话新建和用户点名的，最后收当前所在的那个。多个 worktree 逐个串行处理，每个都 rebase 到最新的 `origin/<默认分支>` 再推送，不并行推送。

## 2. 判定每个 worktree 的状态

对每个要收的 worktree（`git -C <worktree>` 执行，当前所在的直接执行）：

- `git status --short` 为空，且 `git fetch origin <默认分支>` 后 `git merge-base --is-ancestor HEAD origin/<默认分支>` 退出码为 0：提交已全部在默认分支上，直接跳到第 7 步删除。
- 有未提交改动：进入第 3 步提交。
- 只有未推送的提交：跳到第 4 步。

## 3. 提交

- 本会话自己的改动：按该仓库的提交规则逐个路径暂存。禁止 `git add -A`、`git add .`、`git commit -a`。
- 仓库没有写提交格式时，用 `type(scope): 简体中文说明`，不加 AI 署名。
- 子代理的改动：先读 `git diff` 与未跟踪文件，确认都属于派给它的任务再提交。子代理常只改不提交，由本会话代为提交。
- 看不出来源的文件停下，列出 worktree 与文件问用户。这个 worktree 不提交也不删，其余照常收。
- 按仓库规则拆 commit。仓库要求包的 commit 在消费应用之前时照做。
- detached HEAD 可以直接提交与推送，没有分支要删。

## 4. 验证

- 按该仓库的验证规则。本会话已有且未失效的证据直接复用。子代理不跑测试，它的代码改动由本会话在该 worktree 里跑定向检查。仓库没有验证规则时，跑本会话已经在用的那组检查。
- worktree 缺 `vendor/` 而测试需要它时，从主检出复制一份真实目录，不建符号链接。缺其他依赖时用仓库已有的安装方式，不新写安装器。
- FAIL 就在该 worktree 里修到通过，不带着失败推送。只改文档、提示词或 AI 配置时不跑测试。

## 5. 追平 origin

- `git fetch origin <默认分支>`，然后 `git rebase origin/<默认分支>`。
- 冲突能从两边意图判定就解决后 `git rebase --continue`。判定不了就 `git rebase --abort`，报告 worktree、提交与冲突文件，这个 worktree 保留不删，继续处理下一个。
- rebase 后 `HEAD` 与 `origin/<默认分支>` 相同：跳到第 7 步。
- rebase 改变了被测代码的上下文时，复测受影响的定向检查。

## 6. 推送

- 改了 submodule 指针时，先确认指针指向的 commit 已在该 submodule 自己的远端（在子目录 `git branch -r --contains <sha>` 非空）。没有就先在子目录推送。
- `git push origin HEAD:<默认分支>`，只接受快进。被拒说明 origin 又前进了，回到第 5 步。不 force push，不 `git merge`。
- 推送后核对：`git status --short` 为空，`git fetch origin <默认分支>` 后 `git merge-base --is-ancestor HEAD origin/<默认分支>` 退出码为 0。两项都满足才进入第 7 步。

## 7. 删除 worktree 与分支

删除都在主检出执行：`git -C <主检出> worktree remove <路径>`。

- 分支没有上游时 `git branch -d` 会误拒。先确认 `git merge-base --is-ancestor <分支> origin/<默认分支>` 退出码为 0，再 `git -C <主检出> branch -D <分支>`。不为 0 就回到第 5 步，不删分支。
- `<分支>` 用该 worktree 里的 `git branch --show-current`。Claude Code 用 EnterWorktree 或 `claude --worktree` 建的分支是 `worktree-<目录名>`。没有 EnterWorktree 时，`/worktree-start` 建的分支与目录同名。
- remove 被拒时按原因处理，不直接加 `--force`：
  - 有未跟踪但未忽略的文件：确认不需要保留后用 `trash` 删掉再 remove。
  - 含 submodule 的 worktree 不能直接 remove：确认 submodule 里没有未推送的提交与未提交改动，再带 `--force` remove。
  - worktree 被锁（`git worktree list --porcelain` 里有 `locked` 行）：锁的 reason 里带 pid 且 `ps -p <pid>` 已不存在时，`git worktree unlock <路径>` 后再 remove。pid 仍在就不删，记 SKIP。不用 `git worktree remove -f -f` 越过别人的锁。
  - worktree 目录已被手工删掉：`git worktree prune`，分支照上一条删。

## 8. 主检出追平

- 在主检出执行。主检出当前在默认分支上时 `git pull --ff-only`。不在默认分支上时 `git fetch origin <默认分支>:<默认分支>`，不切换主检出的分支。
- 主检出的未提交改动属于别的会话，不 stash、不 checkout、不 reset。追平因它们失败时，报告冲突文件，不强行追平。

## 报告

一行结论（推到默认分支的提交号，删除了哪些 worktree），再按 worktree 列表：

| worktree | 状态 | 证据 |
|---|---|---|
| `feature-a`（当前所在） | PASS | `abc1234 fix(scope): ...` 已推送，worktree 与分支已删 |
| `agent-xxxx`（本会话新建） | PASS | 代为提交 `def5678`，定向检查通过 |
| `agent-yyyy`（本会话新建） | FAIL | rebase 冲突，worktree 保留 |
| `other-name`（其他） | SKIP | 不属于本会话 |
| 主检出追平 | PASS | 当前 HEAD `def5678` |

状态只用 PASS / FAIL / SKIP / UNKNOWN。
