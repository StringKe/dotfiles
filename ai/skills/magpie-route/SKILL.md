---
name: magpie-route
description: 维护 magpie 的模型路由分组：大脑、深度、干活、快速四个角色组按模型而不是按供应商排优先级。新增、更换、停用供应商或订阅，新一代模型发布，用户说「调一下路由」「重建分组」「换了供应商」「检查路由对不对」时使用。magpie 命令的通用写法见 magpie-setup skill。
---

# magpie-route

agent 只认 4 个角色组。角色组里写模型，同一个模型由哪家供应商提供交给模型层处理。换供应商只动模型层，角色组和 agent 配置不变。

## 目标状态

### 角色组

| 组 | 成员 | 用途 |
| --- | --- | --- |
| `group/brain` | 依次：Opus 5.5 -> GPT-6.1 Sol -> Grok 4.7 -> `group/worker` | 主对话 |
| `group/deep` | 依次：Fable 5.2 -> GPT-6 Astra -> Opus 5.5 -> `group/worker` | 架构、疑难问题、长时间无人值守任务 |
| `group/worker` | 依次：GPT-6.1 Sol -> Sonnet 5.5 -> GPT-6.1 Terra | 写代码的子代理、压缩上下文 |
| `group/fast` | 依次：Haiku 5.5 -> GPT-6.1 Terra -> Grok 4.7 Fast | Explore 子代理、起标题、小任务 |

- 四个角色组都用 `routing=order stays=session`，成员写 `auto/<模型>`。角色组只决定用哪个模型，用哪家供应商由模型层轮流决定。`stays=session` 让一个会话固定在一家，保住缓存。
- `brain` 和 `deep` 各两条规则：`use=group/worker use-effort=high when=subagent`，`use=group/worker compact`。规则的 `use=` 必须是组成员，所以 `group/worker` 放在这两个组的最后一位。
- 子代理用规则分流，不设 `magpie claude subagent`。那个字段会覆盖全部子代理，Explore 和自己写了 `model:` 的子代理也会被改掉。

### 不同的活怎么进不同的组

模型看不到分组。走哪个组由两件事决定：会话选了哪个组，子代理请求的是哪个模型名。

- 会话：在 `/model` 或 OpenCode 的模型列表里选组。日常用 `brain`，难题开一个 `deep` 会话。
- Claude Code 的子代理按这个顺序取模型：派发时主模型传的 `model` 参数（`opus`、`fable`、`sonnet`、`haiku`），子代理定义里的 `model:` 字段，`CLAUDE_CODE_SUBAGENT_MODEL`，最后沿用主对话的模型。来源：https://code.claude.com/docs/en/sub-agents

| 子代理怎么派 | 请求的模型 | 结果 |
| --- | --- | --- |
| 不指定，沿用主模型 | `group/brain` 或 `group/deep` | 命中子代理规则 -> worker，effort high |
| `opus` | `auto/claude-opus-5-5` | Opus 5.5 |
| `fable` | `auto/claude-fable-5-2` | Fable 5.2，high |
| `sonnet` | `group/worker` | GPT-6.1 Sol |
| `haiku`，以及 Explore | `group/fast` | Haiku 5.5 |

- opus 档和 fable 档指向模型组，不指向 `brain` 和 `deep`。指向角色组的话，子代理规则会把明确要 Opus 或 Fable 的子代理也改成 worker。
- 要让某类子代理固定用某个档位，在 `~/.claude/agents/<名>.md` 的 frontmatter 里写 `model: fable`，或在全局提示词里写明哪类任务派哪个档位。
- OpenCode 不告诉 magpie 哪个请求来自子代理，没有单独配置的子代理跟主对话走同一个组。它的内置子代理已在 `agents` 里单独指定模型，见下面 agent 一节。
- `opencode.jsonc` 是指向 dotfiles 的符号链接，改了链接目标后 OpenCode 不会察觉。改完执行 `touch -h ~/.config/opencode/opencode.jsonc`，再用 `opencode run` 测一次子代理。

选型依据（2026-11 的评测）：

- Opus 5.5 是日常主力，medium 档的 FrontierCode 得分不低于 xhigh 和 max，成本只有 max 的约 1/8。来源：https://www.anthropic.com/claude-opus-5-5 、https://moelueker.com/blog/claude-opus-5-5-review
- Fable 5.2 智能指数第一，high 档性价比最好，max 更贵且不更好。来源：https://artificialanalysis.ai/models/releases/comparisons/claude-opus-5-5-vs-claude-fable-5-2
- 写代码的子代理，GPT-6.1 Sol 在 high 档通过率高于 Sonnet 5.5，成本约为 1/7，所以 worker 第一位是 Sol。来源：https://vulcanbench.com/benchmarks/swe-v4-sonnet55-vs-frontier.html
- 只读、探索类子代理用 Haiku 5.5 即可。GPT-6 Luna 在查代码这类任务上不可靠，不放进任何组。来源：https://www.ovidius.ai/blog/claude-code-subagents-haiku-vs-sonnet-vs-opus-benchmarked 、https://bito.ai/blog/gpt-6-1-terra-vs-gpt-6-1-sol-vs-gpt-6-luna/

### 模型层

- 有两家以上供应商的模型，magpie 会自动生成 `auto/<模型>` 组（`magpie group auto on` 打开）。Claude 模型组写成 `magpie group set auto-claude-opus-5-5 models='claude/claude-opus-5-5,re:.*claude-opus-5[.-]5' routing=rotate stays=session`，用正则收进各家中转，以后新增供应商会自动加进来。GPT 模型组（Codex 订阅加 OpenAI 中转）同样设 `routing=rotate stays=session`。
- 只有一家的模型，角色组里直接写 `provider/model`，比如 `grok/grok-4.7`。
- 只接受 Claude Code 请求的中转 key，在对应的模型组里加 `pause=<relay>/<model> when="agent is not claude"`。不加的话，其他 agent 的请求被 403 拒绝后，magpie 会让这家暂时休息，Claude Code 也跟着被挤到下一家。
- 裸模型名的请求（比如老会话发的 `claude-opus-5-5`）也走 `auto/<模型>` 组。
- 中转只接 Claude 的 key 和只接 OpenAI 的 key 在 magpie 里是两个服务商，比如「鱼鱼连线 Claude」和「鱼鱼连线 OpenAI」。
- 中转按协议放行模型：GPT 走 `/v1/messages` 常被拒（`This group does not allow /v1/messages dispatch`、「当前分组不允许调度模型」），Gemini 报「不支持当前入口协议」。GPT 用 `magpie model api <provider/model…> responses`；Gemini 先 `magpie provider set <id> gemini=<中转根地址>`，再 `magpie model api <provider/model…> gemini`。换协议后再测，不要按第一次的报错判定这家不支持。
- GPT、Grok 的模型组同样用正则收进中转：`magpie group set auto-gpt-6-1-sol models='codex/gpt-6.1-sol,re:.*/gpt-6\.1-sol' routing=rotate stays=session`。手工改过成员的组不会自动收进新供应商，要写正则。

### 每个组用哪种路由

| 组 | 路由 | 原因 |
| --- | --- | --- |
| 模型层 `auto/<模型>` | `rotate` | 订阅和各家中转轮流接新会话，中转的余额是买来用完的，不留着当后备 |
| 四个角色组 | `order` | 第一位是指定的模型。角色组用 `rotate` 会把主对话轮到 GPT、Grok 上 |

- `rotate` 加 `stays=session`：每个新会话轮到下一家，会话内的请求留在同一家，缓存不断。某家报错、余额用完时，这个会话转到下一家。
- 按量付费的 key 不设每日上限。上限到顶会把这家当作当天已用完，跟「中转余额用完为止」相反。
- 订阅账号用到上限时，任何路由都会把它当作已用完直接跳过，直到窗口重置。`magpie provider account-cap <id> <账号> <百分比>` 可以设定提前让出的比例。
- 订阅账号用到上限时，任何路由都会把它当作已用完直接跳过，直到窗口重置。`magpie provider account-cap <id> <账号> <百分比>` 可以设定提前让出的比例。
- 同一家有两个以上订阅时，在服务商上设 `magpie provider set <id> routing=pace`，或用 `magpie provider pool` 定顺序和上限。

### agent

| agent | 设置 |
| --- | --- |
| Claude Code | `magpie claude group/brain`，`opus auto/claude-opus-5-5`，`fable auto/claude-fable-5-2`，`sonnet group/worker`，`haiku group/fast`，`fable_effort high`，effort 保持 medium |
| OpenCode | `magpie opencode group/brain`，`small group/fast`；`~/.config/opencode/opencode.jsonc` 的 `agents` 里写 `general`、`compaction` -> `magpie/group/worker`，`explore`、`summary`、`title` -> `magpie/group/fast` |
| 其他 agent | 不接 magpie。Library 的 MCP 服务和 skill 只分发给 `claude`、`opencode`：`magpie library mcp agents <名> claude,opencode`，`magpie library skill agents <名> claude,opencode` |
| Codex | 不接 magpie，走自己的 ChatGPT 登录 |

- 收窄模型列表：OpenCode 用 `magpie visible opencode brain,deep,worker,fast`；Claude Code 用 `magpie visible claude brain,deep,worker,fast,auto-claude-opus-5-5,auto-claude-fable-5-2`，因为档位只能指向列表里可见的模型。按名字请求其他模型的老会话仍然能用。
- 顺序是先设 `visible`，再设档位。顺序反了，`magpie claude opus <模型>` 会报这个模型对 Claude Code 不可见。
- 旧一代模型用 `magpie model disable '<glob>'` 停用，例如 `'*claude-opus-4*'`、`'*gpt-5.6-*'`。

## 调整步骤

1. 存档：`magpie backup <文件>` 存全部配置，`magpie save before-route` 存各 agent 的设置。
2. 读现状：`magpie providers`、`magpie quota`、`magpie groups`、`magpie models`。
3. 新增供应商：
   - 加完先跑 `magpie provider test <id>`，再用真实客户端测一次。有的中转 key 只认 Claude Code，curl 返回 403，`claude -p` 却能通。
   - 中转的模型清单不等于这把 key 能调的模型。按上面「中转按协议放行模型」一条换协议后，把清单里的模型逐个用 curl 发一条请求，再用 `magpie provider models <id> <能调通且有分组会用到的模型…>` 只暴露这些。curl 测试时每条消息的内容要不同，内容相同的请求会被认成同一个会话，落在同一家。
   - 核对余额读数。new-api 类中转的「不限额度」key，`data.total_available` 永远等于已用量的负数，余额要改读 `magpie provider set <id> balance.path='$data.user_quota.total_available / 500000'`。
4. 停用供应商：用 `magpie provider off <id>`，不用 `rm`。然后检查 `~/.config/magpie/stash.json` 里的 `claude.base_url` 是否还指向它，执行 `magpie claude default` 时会写回这个地址。要清就先备份，再用 jq 删掉 `claude.base_url` 和 `claude.auth_token`。
5. 重新对照模型层：
   - 某模型变成两家以上：出现 `auto/<模型>` 组，按上面的写法排序，再把角色组里的 `provider/model` 换成 `auto/<模型>`。
   - 某模型只剩一家：`auto/<模型>` 组消失，角色组里换成 `provider/model`。
6. 新一代模型：直接替换角色组里对应的位置，再停用上一代。
7. 删组之前查最近有没有会话还在请求它：`jq -r 'select(.t > "<时刻>") | .req' ~/.config/magpie/usage.jsonl | sort | uniq -c`。还有请求就先保留，或者用同一个 id 建一个只含 `group/brain` 的转发组。直接删会让这些会话收到 404。

## 验证

每次请求的记录在 `~/.config/magpie/usage.jsonl`：`req` 是请求的模型，`provider/served` 是实际服务的模型。

```sh
for g in brain deep worker fast; do curl -s http://127.0.0.1:3425/v1/messages -H 'x-api-key: magpie' -H 'anthropic-version: 2023-06-01' -H 'content-type: application/json' -d "{\"model\":\"group/$g\",\"max_tokens\":16,\"messages\":[{\"role\":\"user\",\"content\":\"reply ok\"}]}" >/dev/null; done
claude -p 'Launch five general-purpose subagents with the Agent tool, each with the prompt "reply sub ok": no model parameter, then model "opus", "fable", "sonnet", "haiku". Then launch an Explore subagent that lists files here. Then reply done.' --max-turns 16 --allowedTools='Task,Agent,Read,Glob,Bash(ls:*)'
opencode run 'reply ok'
jq -r 'select(.t > "<开始时刻>") | "\(.agent) \(.req) -> \(.provider)/\(.served) \(.status)"' ~/.config/magpie/usage.jsonl | sort | uniq -c
```

通过的标准：

- 主对话：`group/brain -> claude/claude-opus-5-5`。
- 子代理与「不同的活怎么进不同的组」一节的表格一致：不指定模型和 `sonnet` -> GPT-6.1 Sol；`opus` -> Opus 5.5；`fable` -> Fable 5.2；`haiku` 和 Explore -> Haiku 5.5。
- 对同一个模型组发几条内容不同的请求，`provider` 依次换成订阅和各家中转。
- 非 claude agent：请求不会落到只认 Claude Code 的中转上。
- 改动之后没有 404 和 403。

`claude -p` 的 `--allowedTools` 会把后面的参数都当成工具名，所以提示词写在它前面，或者写成 `--allowedTools=...`。

## 易错点

- `magpie claude opus`、`sonnet`、`haiku`、`fable` 后面不带值时，会把主模型改成 Claude Code 自己的这个档位，等于断开 magpie。查看当前设置只用 `magpie claude`。
- 组成员不能写 `group/x:high`，固定 effort 用规则的 `use-effort=` 或 agent 的 `*_effort` 字段。
- 一个组里写多个正则时，命中的模型按 `magpie models` 的列表顺序排，不按正则的书写顺序。要控制顺序，先把模型名明确写出来。
- `auto/x` 存进组里会变成 `group/auto-x`，`magpie groups` 列表里会显示 `(not served)`。这只是显示问题，实际能否路由以 usage.jsonl 为准。
- Claude Code 的 advisor 走 magpie 时不生效：它在 Anthropic 服务端运行，只认 Claude Code 自己认识的模型名。难题改用 `/model` 切到 fable 档。
- 走 Claude 订阅的请求，magpie 会在调用方的项目目录里启动一个交互模式的 Claude Code（`--setting-sources "" --permission-mode default`）。它出现在 `ListAgents` 里，名字是「目录名-两位十六进制」，不读用户的 `crossSessionInbound`。bypass 模式的会话发给它的消息会被扣下，然后过期。源码位置：`internal/gateway/claude_subscription.go`、`internal/claudetui/tui.go` 的 `interactiveArgs`、`internal/gateway/claude_warmup.go` 的 `claudeRunSettings`。
- 已在运行的会话保留启动时的环境变量。用 `ps eww -U $USER | rg -o 'ANTHROPIC_BASE_URL=\S+' | sort | uniq -c` 查还有多少进程绕过 magpie，这些进程要重启才会走新配置。
