---
name: op-session
description: agent 调用 1Password CLI 的方式：所有 op 命令（item list/get、vault list、read、run、inject、whoami 等）改用本 skill 的 opx，参数与 op 相同。直接跑 op 时每个新进程都要用户按一次 Touch ID，opx 把请求交给 Rex 会话 op-broker 里的常驻终端执行，授权一次后最多 12 小时不再弹窗。
---

# op-session

1Password CLI 的授权按终端计：同一个终端里按一次 Touch ID，闲置 10 分钟内或 12 小时以内的后续命令都不再弹窗。agent 的每条命令都是新进程，直接跑 `op` 会每次弹授权。

`opx` 把 `op` 的参数交给 Rex 会话 `op-broker` 里的常驻进程 `op-broker` 执行，结果、stderr 和退出码原样返回。常驻进程每 5 分钟用一次已用过的账号，保持授权不过期。

## 用法

```bash
~/.claude/skills/op-session/scripts/opx vault list --account <账号>.1password.com
~/.claude/skills/op-session/scripts/opx item get <条目> --vault '<vault>' --account <账号>.1password.com --format json
~/.claude/skills/op-session/scripts/opx run --env-file .env.op -- aws sts get-caller-identity
```

- 参数与 `op` 完全相同，不写 `op` 本身。
- 第一次调用时常驻进程没在跑，`opx` 会在 Rex 新建会话 `op-broker` 启动它，用户按一次 Touch ID。12 小时后或 1Password 锁定后再按一次。
- 命令在调用方的工作目录执行，相对路径照常可用。stdin 是管道或文件时一并转交。
- 调用方的环境变量不会带过去。`op run` 要用的变量写进 `--env-file`，或写成 `op run -- env K=V <命令>`。
- 默认等 300 秒，等不到返回 124，通常是 Touch ID 没按，用 `rex capture` 看会话 `op-broker`。超时可用环境变量 `OPX_TIMEOUT` 调整。
- 请求文件在 `~/.local/state/op-broker`（权限 700），执行完即删。
- 操作日志在 `~/.local/state/op-broker/audit/<YYYY-MM>.jsonl`，一条请求一行：时刻（UTC）、子命令、账号、vault、条目标题与 ID、读取或写入的字段名、`op run` 的命令名、退出码、耗时，以及调用方的 Rex 会话、tab、Claude 会话 ID 与工作目录。字段值、赋值参数的值、`op run` 的命令参数、stdin 与输出都不记。按条目查：`jq -c 'select(.item == "<标题>")' ~/.local/state/op-broker/audit/*.jsonl`。
- Rex 会话 `op-broker` 的屏幕上一行一条请求：本地日期与时刻、调用方 tab、子命令、vault/条目 [字段]、退出码。
- 不要关闭 Rex 会话 `op-broker`。关掉后下次调用会重新启动，并要求重新授权。
