---
name: worktree-start
description: "进入隔离 worktree。Claude Code 调用 EnterWorktree，会话切到 .claude/worktrees/<名字>，分支为 worktree-<名字>，基线是 origin 默认分支。工作区干净且会话没用 --name 或 /rename 起名时，交互退出会删掉 worktree 和分支。没有 EnterWorktree 时用 git worktree add，会话目录不变，退出不删。用户运行 /worktree-start 或 /worktree-start <名字> 时使用。"
user-invocable: true
disable-model-invocation: true
argument-hint: "[名字]"
---

# 进入 worktree

用户输入 `/worktree-start` 或 `/worktree-start <名字>` 即开始。只进入隔离检出，不 commit，不 push。不使用 Claude Code agents view。

`git rev-parse --show-toplevel` 已在 `.claude/worktrees/` 下：停下，报告路径、分支、HEAD。不再创建。

不切换主检出的当前分支，不动它的未提交改动。

## 名字与基线

- 用户给了名字，且每个 `/` 分段只含字母、数字、点、下划线、连字符，总长不超过 64：原样使用。
- 否则从本轮任务取一个短 slug：小写字母、数字、连字符，首尾是字母或数字，不超过 40 个字符。报告里写实际名字。
- 主检出是 `git rev-parse --path-format=absolute --git-common-dir` 的父目录（该路径以 `/.git` 结尾）。
- 默认分支：`git symbolic-ref --short refs/remotes/origin/HEAD`，取斜杠后的名字。没有这条 ref 时，远程有 `main` 用 `main`，否则用 `master`。
- 在主检出执行 `git fetch origin <默认分支>`。
- 目录 `.claude/worktrees/<名字>` 已存在就换名字，不覆盖，不复用。
- Claude Code 还要看分支 `worktree-<名字>`。没有 EnterWorktree 时还要看分支 `<名字>`。已存在就换名字。

## Claude Code

本会话有 EnterWorktree 时走这里。

调用 EnterWorktree，只传 `name`，不传 `path`。它创建并进入：

- 目录：`<主检出>/.claude/worktrees/<名字>`
- 分支：`worktree-<名字>`
- 基线：`worktree.baseRef` 为 `fresh` 时是刚 fetch 的 `origin/<默认分支>`，不带主检出的未提交改动

进入后执行 `git config --worktree worktree.plugin worktree`。已有这个值就不改。

之后的读、改、测试、git 都在这个目录。先不复制 `vendor/`、`node_modules/`。要跑测试时按 `/worktree-done` 的验证一节再补。任务碰到 submodule 时，再 `git submodule update --init <路径>`。

交互会话退出时，只处理 Claude Code 自己建的 worktree：

| 状态 | 退出 |
|---|---|
| 工作区干净，相对进入时没有新提交，会话没有 `--name` 或 `/rename` | 自动删除 worktree 和分支 |
| 会话起过名，或有未提交改动、新提交，或状态核对不了 | 先问保留还是删除。选删除会连未提交改动和新提交一起去掉 |
| `claude -p` | 不删，并留下 lock。pid 已退出时由 `/worktree-done` 解锁再删 |

要提交并快进推送到默认分支，用 `/worktree-done`。退出删除不会推送。

## 没有 EnterWorktree

Grok 和 OpenCode 走这里。本会话的工作目录不变，退出不删除。

在主检出执行：

```bash
git worktree add -b <名字> .claude/worktrees/<名字> origin/<默认分支>
git -C .claude/worktrees/<名字> config --worktree worktree.plugin worktree
```

分支名是 `<名字>`。之后的读、改、测试、git 都用该目录的绝对路径。不在主检出改文件。收尾用 `/worktree-done`。

## 报告

一行：路径、分支、基线提交号、本会话是否已进入、退出会不会自动删。
