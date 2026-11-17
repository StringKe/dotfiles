---
name: magpie-route
description: 维护 magpie 的模型路由分组：Claude、GPT 两个系列各有大脑、深度和干活三个角色组，按模型而不是按供应商排优先级。新增、更换、停用供应商或订阅，新一代模型发布，用户说「调一下路由」「重建分组」「换了供应商」「检查路由对不对」时使用。magpie 命令的通用写法见 magpie-setup skill。
---

# magpie-route

agent 只认角色组。每个模型系列各有大脑（brain）、深度（deep）和干活（worker）三个组：日常用 brain，子代理和杂活用 worker，特别复杂的任务手动切到 deep。一个组里只放同一系列的模型。不建 Grok 的组，Grok 订阅和 Kiro 的 Grok 4.7 不进任何组。角色组里写模型，同一个模型由哪家供应商提供交给模型层处理。换供应商只动模型层，角色组和 agent 配置不变。

## 目标状态

### 角色组

| 组 | 成员 | 用途 |
| --- | --- | --- |
| `group/claude-brain` | 依次：Opus 5.5 -> `group/claude-worker` | Claude 系列主对话，Claude Code 与 OpenCode 的默认模型 |
| `group/claude-deep` | 依次：Fable 5.2 -> Opus 5.5 -> `group/claude-worker` | Claude 系列的复杂任务 |
| `group/claude-worker` | Sonnet 5.5 | Claude 系列的子代理、Explore、起标题、压缩上下文 |
| `group/gpt-brain` | 依次：GPT-6.1 Sol -> GPT-6 Astra -> `group/gpt-worker` | GPT 系列主对话 |
| `group/gpt-deep` | 依次：GPT-6 Astra -> GPT-6.1 Sol -> `group/gpt-worker` | GPT 系列的复杂任务 |
| `group/gpt-worker` | 依次：GPT-6.1 Terra -> GPT-6.1 Sol | GPT 系列的子代理 |

- 任何组都不放小模型，Claude 最低是 Sonnet：Haiku 不进任何组，并用 `magpie model disable '*claude-haiku*'` 停用，Claude Code 的 haiku 档指向 `group/claude-worker`；GPT 的 Luna 同样不用。GPT-6.1 Terra 不算小模型，智能指数 51.3，Sol 是 54.6（来源：https://genmagic.co/compare/openai-gpt-6-1-sol-vs-openai-gpt-6-1-terra ）。新一代模型进组前先查它是不是该厂商的小模型档。
- 给组改名时，运行中的 Claude Code 会话用 Rex 发 `/model group/<新组>[1m]` 切过去，会弹「Switch model?」确认框，再发一次回车；正在回复的会话等它停下再发。全部切完、旧名不再有请求后删掉旧组，见「调整步骤」第 7 条。
- 所有角色组都用 `routing=order stays=turn`，成员写 `auto/<模型>`。角色组只决定用哪个模型，用哪家供应商由模型层轮流决定，模型层的 `stays=session` 让一个会话固定在一家，保住缓存。角色组不用 `stays=session`：第一位的模型暂时不可用时会话落到第二位，`session` 会让它一直留在第二位，额度恢复或新增供应商后也回不到第一位；`turn` 每次用户发言重新按顺序选。
- 每个 brain 组和 deep 组两条规则，指向同系列的 worker：`use=group/<系列>-worker use-effort=high when=subagent`，`use=group/<系列>-worker compact`。规则的 `use=` 必须是组成员，所以 worker 组放在最后一位。
- 子代理用规则分流，不设 `magpie claude subagent`。那个字段会覆盖全部子代理，Explore 和自己写了 `model:` 的子代理也会被改掉。

### 不同的活怎么进不同的组

模型看不到分组。走哪个组由两件事决定：会话选了哪个组，子代理请求的是哪个模型名。

- 会话：在 `/model` 或 OpenCode 的模型列表里选组。日常用 `claude-brain`，复杂任务切 `claude-deep`，想用 GPT 时选 GPT 系列的组。
- Claude Code 的子代理按这个顺序取模型：派发时主模型传的 `model` 参数（`opus`、`fable`、`sonnet`、`haiku`），子代理定义里的 `model:` 字段，`CLAUDE_CODE_SUBAGENT_MODEL`，最后沿用主对话的模型。来源：https://code.claude.com/docs/en/sub-agents

| 子代理怎么派 | 请求的模型 | 结果 |
| --- | --- | --- |
| 不指定，沿用主模型 | 主会话选的 brain 或 deep 组 | 命中子代理规则 -> 同系列 worker，effort high |
| `opus` | `auto/claude-opus-5-5` | Opus 5.5 |
| `fable` | `auto/claude-fable-5-2` | Fable 5.2，high |
| `sonnet`、`haiku`，以及 Explore | `group/claude-worker` | Sonnet 5.5 |

- opus 档和 fable 档指向模型组，不指向 `claude-brain`、`claude-deep`。指向角色组的话，子代理规则会把明确要 Opus 或 Fable 的子代理也改成 worker。
- 要让某类子代理固定用某个档位，在 `~/.claude/agents/<名>.md` 的 frontmatter 里写 `model: fable`，或在全局提示词里写明哪类任务派哪个档位。
- OpenCode 不告诉 magpie 哪个请求来自子代理，没有单独配置的子代理跟主对话走同一个组。它的内置子代理已在 `agents` 里单独指定模型，见下面 agent 一节。
- `opencode.jsonc` 是指向 dotfiles 的符号链接，改了链接目标后 OpenCode 不会察觉。改完执行 `touch -h ~/.config/opencode/opencode.jsonc`，再用 `opencode run` 测一次子代理。

选型依据（2026-11 的评测）：

- Opus 5.5 是日常主力，medium 档的 FrontierCode 得分不低于 xhigh 和 max，成本只有 max 的约 1/8。来源：https://www.anthropic.com/claude-opus-5-5 、https://moelueker.com/blog/claude-opus-5-5-review
- Fable 5.2 智能指数第一，high 档性价比最好，max 更贵且不更好。来源：https://artificialanalysis.ai/models/releases/comparisons/claude-opus-5-5-vs-claude-fable-5-2
- GPT-6.1 Sol 在多数编码与工作流评测上接近 GPT-6 Astra，价格约为 1/5，做 GPT 系列的大脑；Astra 仍是最强的 GPT，放第二位。GPT-6.1 Terra 速度约为 Sol 的 3 倍，适合子代理和摘要。来源：https://openai.com/index/introducing-gpt-6-1-sol/ 、https://openai.com/index/introducing-gpt-6-1-terra/
- GPT-6 Luna 在查代码这类任务上不可靠，不放进任何组。来源：https://bito.ai/blog/gpt-6-1-terra-vs-gpt-6-1-sol-vs-gpt-6-luna/

### 模型层

- 「自动创建路由组」保持关闭（`magpie group auto off`）。模型组只保留角色组用到的那几个，是改过的组，关闭后照常生效。新模型要建模型组时直接 `magpie group add "<模型名>" models='<订阅>/<模型>,re:.*/<模型正则>' routing=rotate stays=session`，不用打开自动创建。
- Claude 模型组写成 `magpie group set auto-claude-opus-5-5 models='claude/claude-opus-5-5,re:.*claude-opus-5[.-]5' routing=expiring stays=session`，用正则收进各家中转，以后新增供应商会自动加进来。GPT 模型组设 `routing=rotate stays=session`。
- 模型组不能省成在角色组里直接列 `provider/model`：角色组用 `stays=turn` 每轮重选，直接列供应商会让同一会话在几家之间来回换、缓存全丢；模型组的 `stays=session` 把会话固定在一家，`expiring`、`rotate` 决定先用哪家的额度。一个模型只有一家时才在角色组里直接写 `<provider>/<model>`。
- 只接受 Claude Code 请求的中转 key，在对应的模型组里加 `pause=<relay>/<model> when="agent is not claude"`。不加的话，其他 agent 的请求被 403 拒绝后，magpie 会让这家暂时休息，Claude Code 也跟着被挤到下一家。
- 裸模型名的请求（比如老会话发的 `claude-opus-5-5`）也走 `auto/<模型>` 组。
- Claude 中转的 key 可以给 Claude Code 用，不加 pause。唯一的例外是以 assistant 消息结尾（prefill）的请求：Claude 4.6 及以后的模型在 Anthropic API 上一律拒绝，报 `This model does not support assistant message prefill. The conversation must end with a user message.`（来源：https://platform.claude.com/docs/en/api/errors ），用官方 API key 的中转都会原样转回这个 400，与 key 是否正确无关。Claude 订阅和 Kiro 不经 Anthropic API，接受这种请求。Claude Code 自己的请求以 user 消息结尾，不受影响。magpie 只给 OpenAI 格式（Chat、Responses）的客户端补一条 user 消息重试；Anthropic 格式的客户端原样收到 400，不换下一家，这个会话要发一次「继续」。Claude 模型组用 `expiring`，按量付费的中转排在订阅和 Kiro 之后，只在两者都用完时接手，碰到这种 400 的机会很少。停用或删除供应商后，引用它的规则要一起删：`magpie group set <组> models-=<provider/model>` 会连带删掉指向它的规则；成员已不在组里的规则会让 `magpie group rule rm` 对其他编号报错，先删这一条。新中转用 `claude -p` 或带 Claude Code UA 的 curl 测一次正常请求即可。
- 中转只接 Claude 的 key 和只接 OpenAI 的 key 在 magpie 里是两个服务商，比如「鱼鱼连线 Claude」和「鱼鱼连线 OpenAI」。
- 中转按协议放行模型：GPT 走 `/v1/messages` 常被拒（`This group does not allow /v1/messages dispatch`、「当前分组不允许调度模型」），Gemini 报「不支持当前入口协议」。GPT 用 `magpie model api <provider/model…> responses`；Gemini 先 `magpie provider set <id> gemini=<中转根地址>`，再 `magpie model api <provider/model…> gemini`。换协议后再测，不要按第一次的报错判定这家不支持。
- GPT 的模型组同样用正则收进中转：`magpie group set auto-gpt-6-1-sol models='codex/gpt-6.1-sol,re:.*/gpt-6\.1-sol' routing=rotate stays=session`。手工改过成员的组不会自动收进新供应商，要写正则。组里只把订阅写成明确成员，中转和 Kiro 一律靠正则收进来：正则匹配的是 `magpie models` 当前的列表，新供应商暴露了同名模型就自动加入，供应商删掉或不再暴露就自动退出；明确写出的成员在供应商删掉后会留下 `not served` 的残项，要手动 `models-=`。所以「自动创建路由组」不用打开，打开后会给每个有两家以上的模型各建一个组，列表又变乱。
- Kiro 订阅经插件接入：`magpie plugin add @magpie-community/opencode-kiro-auth`，`magpie plugin login kiro`。它提供 Opus 5.5、Sonnet 5.5、Haiku 5.5、Grok 4.7，模型名带点（`kiro/claude-opus-5.5`），Claude 正则写 `[.-]` 才能收进来；没有 Fable。Kiro 会在请求前加约 2000 token 自己的系统提示词，问模型身份时答「Kiro」，属正常。它按月给 credits，Claude 模型组用 `expiring` 时在 Claude 订阅窗口用完后接上。可以登录多个 Kiro 账号，`magpie quota` 逐个列出，用完一个自动换下一个。curl 也能调通，不需要 `pause` 规则。

### 每个组用哪种路由

| 组 | 路由 | 原因 |
| --- | --- | --- |
| Claude 模型组 | `expiring` | Claude 订阅先用，5 小时窗口用完再到中转。中转会按关键词删掉 Claude Code 的部分消息，对话变成以 assistant 结尾，报 `does not support assistant message prefill` 或 `keyword prompt removal left no messages`；400 不会换家，会话卡在这家连续报错 |
| GPT 模型组 | `rotate` | Codex 订阅和 OpenAI 中转轮流接新会话，中转的余额用掉，不留着当后备 |
| 角色组 | `order` | 第一位是指定的模型，后面是同系列的降级 |

- `rotate` 加 `stays=session`：每个新会话轮到下一家，会话内的请求留在同一家，缓存不断。某家报错、余额用完时，这个会话转到下一家。
- 按量付费的 key 不设每日上限。上限到顶会把这家当作当天已用完，跟「中转余额用完为止」相反。
- 订阅账号用到上限时，任何路由都会把它当作已用完直接跳过，直到窗口重置。`magpie provider account-cap <id> <账号> <百分比>` 可以设定提前让出的比例。
- 同一家有两个以上订阅时，在服务商上设 `magpie provider set <id> routing=pace`，或用 `magpie provider pool` 定顺序和上限。

### agent

| agent | 设置 |
| --- | --- |
| Claude Code | `magpie claude group/claude-brain`，`opus auto/claude-opus-5-5`，`fable auto/claude-fable-5-2`，`sonnet group/claude-worker`，`haiku group/claude-worker`，`fable_effort high`，effort 保持 medium |
| OpenCode | `magpie opencode group/claude-brain`，`small group/claude-worker`；`~/.config/opencode/opencode.jsonc` 的 `agents` 里 `general`、`compaction`、`explore`、`summary`、`title` 都写 `magpie/group/claude-worker` |
| 其他 agent | 不接 magpie。Library 的 MCP 服务和 skill 只分发给 `claude`、`opencode`：`magpie library mcp agents <名> claude,opencode`，`magpie library skill agents <名> claude,opencode` |
| Codex | 不接 magpie，走自己的 ChatGPT 登录 |

- 收窄模型列表：OpenCode 用 `magpie visible opencode claude-brain,claude-deep,claude-worker,gpt-brain,gpt-deep,gpt-worker`；Claude Code 在这串后面再加 `auto-claude-opus-5-5,auto-claude-fable-5-2`，因为档位只能指向列表里可见的模型。按名字请求其他模型的老会话仍然能用。
- 顺序是先设 `visible`，再设档位。顺序反了，`magpie claude opus <模型>` 会报这个模型对 Claude Code 不可见。
- 旧一代模型用 `magpie model disable '<glob>'` 停用，例如 `'*claude-opus-4*'`、`'*gpt-5.6-*'`。

### 上下文压缩与命令输出

- 上下文压缩用 agent 自带的：Claude Code 按 `ai/claude/settings.json` 的 `autoCompactWindow`，OpenCode 用 `agents.compaction` 指定的 `group/claude-worker`。billion-context 在 magpie「Library -> billion-context」里对所有 agent 都关闭，`bili plugin list` 应全部是 `not installed`。原因：Claude Code 只能经它的本地代理接入（`ANTHROPIC_BASE_URL=http://127.0.0.1:<端口>/bili/...`），代理在登记过的会话全部退出后自己关闭，所有 Claude Code 会话会同时报 `ECONNREFUSED`；它的压缩失败轮还会发出以 assistant 结尾的请求，中转报 prefill 400。
- Claude Code 的 `~/.claude/settings.json` 里 `env.ANTHROPIC_BASE_URL` 必须是 `http://127.0.0.1:3425`。关掉 billion-context 时 bili 的卸载会把这一项整个删掉，新会话改连 Anthropic 官方接口，报 `401 Invalid bearer token`。用 `jq '.env.ANTHROPIC_BASE_URL="http://127.0.0.1:3425"'` 补回；不要用 `magpie claude <模型>` 重设，它会把 opus、sonnet、haiku 档位一起改成主模型。补回后 `claude -p 'reply ok'` 应回 `ok`。运行中的会话会重新读取这个地址，不用重开。
- RTK（https://www.rtk-ai.app ）把 agent 的 shell 命令改写成 `rtk <命令>` 并压缩输出，用 `magpie library rtk` 查看和开关，Claude Code、OpenCode 都开着。`rtk gain` 看省下的 token 和每条命令的压缩比例。它主要压缩 `rg` 的输出，模型不知道输出被删减过。出现模型没读到关键输出、反复重跑同一命令时，先用 `magpie library rtk off claude`、`magpie library rtk off opencode` 关掉再对比。


### 先用完某家中转的余额

要让一家按量付费的中转（例如 WandAPI）先用完：
- 余额接进 magpie：`magpie provider set <id> balance=<余额接口> balance.path=<字段>`。WandAPI 是 `balance=https://api.wandapi.ai/v1/usage balance.path='$remaining'`，用 `magpie quota <id>` 核对。
- GPT 模型组加 `use=<中转>/<模型>,<订阅>/<模型> agents=claude,opencode,memory`：中转排第一，订阅第二，别的中转只在两者都不行时接手。余额用完后 magpie 按欠费跳过它，不用回头改规则。
- Claude 模型组只对 Chat 格式的 agent 加 `use=<中转>/<模型> agents=opencode,memory`，Claude Code 仍按 prefill 那条暂停。
- 消耗速度：`jq -s '[.[] | select(.provider=="<id>" and .t > "<时刻>")] | group_by(.served) | map({m:.[0].served, n:length, in:(map(.in)|add)})' ~/.config/magpie/usage.jsonl`，余额看 `magpie quota <id>`。

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
7. 删组之前查最近有没有会话还在请求它：`jq -r 'select(.t > "<时刻>") | .req' ~/.config/magpie/usage.jsonl | sort | uniq -c`。还有请求就先保留，或者用同一个 id 建一个只含新组的转发组。直接删会让这些会话收到 404。

## 验证

每次请求的记录在 `~/.config/magpie/usage.jsonl`：`req` 是请求的模型，`provider/served` 是实际服务的模型。

```sh
for g in claude-brain claude-deep claude-worker gpt-brain gpt-deep gpt-worker; do curl -s http://127.0.0.1:3425/v1/messages -H 'x-api-key: magpie' -H 'anthropic-version: 2023-06-01' -H 'content-type: application/json' -d "{\"model\":\"group/$g\",\"max_tokens\":16,\"messages\":[{\"role\":\"user\",\"content\":\"reply ok\"}]}" >/dev/null; done
claude -p 'Launch five general-purpose subagents with the Agent tool, each with the prompt "reply sub ok": no model parameter, then model "opus", "fable", "sonnet", "haiku". Then launch an Explore subagent that lists files here. Then reply done.' --max-turns 16 --allowedTools='Task,Agent,Read,Glob,Bash(ls:*)'
opencode run 'reply ok'
jq -r 'select(.t > "<开始时刻>") | "\(.agent) \(.req) -> \(.provider)/\(.served) \(.status)"' ~/.config/magpie/usage.jsonl | sort | uniq -c
```

通过的标准：

- 主对话：`group/claude-brain` 落到 Opus 5.5，`group/claude-deep` 落到 Fable 5.2，`group/gpt-deep` 落到 GPT-6 Astra。
- 子代理与「不同的活怎么进不同的组」一节的表格一致：不指定模型、`sonnet`、`haiku` 和 Explore -> Sonnet 5.5；`opus` -> Opus 5.5；`fable` -> Fable 5.2。主对话不出现 GPT 的模型。
- 对同一个模型组发几条内容不同的请求，`provider` 依次换成订阅和各家中转。
- 非 claude agent：请求不会落到只认 Claude Code 的中转上。
- 改动之后没有 404 和 403。

`claude -p` 的 `--allowedTools` 会把后面的参数都当成工具名，所以提示词写在它前面，或者写成 `--allowedTools=...`。

## 会话报错排查

先扫一遍开着的会话：`rex ls --json` 取 `.sessions[].session_id`，`rex block ls -s <session> --json` 取 `.blocks[].block_id`，跳过自己的 `$REX_BLOCK`，`rex capture -s <session> -b <block> --trim --unwrap` 看最后 25 行。报错行可能是旧的，以最后几行是否在运行（有计时、`esc to interrupt`）为准。停住的会话发 `rex send -s <session> -b <block> '继续'` 再 `rex send-key -s <session> -b <block> enter`；正在运行的不发。

很多会话同时出错时，不由本会话逐个重启，而是通知各项目的总控（每个项目统管子会话的那个标签，看子会话收到的 `Message from @<名>` 就能认出）：说明原因和已做的修复，列出出错的子会话，让总控逐个核对，偏离的先写交接再关掉重开。

再按报错对照 `~/.config/magpie/usage.jsonl`（`jq -r 'select(.t > "<时刻>" and .status != 200) | "\(.agent) \(.req) -> \(.provider) \(.status)"' | sort | uniq -c`）：

| 报错 | 原因 | 处理 |
| --- | --- | --- |
| 所有 Claude Code 会话 `ECONNREFUSED` | `ANTHROPIC_BASE_URL` 指向的本地地址没有进程在听，多数是还指向已关掉的 billion-context 代理（`/bili/`） | 按「上下文压缩与命令输出」一节把地址改成 `http://127.0.0.1:3425`，给停住的会话发「继续」 |
| 新开的 Claude Code 报 `401 Invalid bearer token` | `env.ANTHROPIC_BASE_URL` 被删，请求去了 Anthropic 官方接口 | 同上，补回地址 |
| `does not support assistant message prefill`、`final assistant content cannot end with trailing whitespace` | 请求以 assistant 结尾，走 Anthropic API 的中转拒绝 | 见「模型层」的 prefill 一条；单次出现发「继续」 |
| `The upstream service could not process the request` | 中转偶发 400，magpie 对 400 不换家 | 零星出现发「继续」；同一会话连续出现再给这家加 pause |

## 易错点

- `magpie claude opus`、`sonnet`、`haiku`、`fable` 后面不带值时，会把主模型改成 Claude Code 自己的这个档位，等于断开 magpie。查看当前设置只用 `magpie claude`。
- 组成员不能写 `group/x:high`，固定 effort 用规则的 `use-effort=` 或 agent 的 `*_effort` 字段。
- 一个组里写多个正则时，命中的模型按 `magpie models` 的列表顺序排，不按正则的书写顺序。要控制顺序，先把模型名明确写出来。
- `auto/x` 存进组里会变成 `group/auto-x`，`magpie groups` 列表里会显示 `(not served)`。这只是显示问题，实际能否路由以 usage.jsonl 为准。
- Claude Code 的 advisor 走 magpie 时不生效：它在 Anthropic 服务端运行，只认 Claude Code 自己认识的模型名。难题改用 `/model` 切到 fable 档。
- 走 Claude 订阅的请求，magpie 会在调用方的项目目录里启动一个交互模式的 Claude Code（`--setting-sources "" --permission-mode default`）。它出现在 `ListAgents` 里，名字是「目录名-两位十六进制」，不读用户的 `crossSessionInbound`。bypass 模式的会话发给它的消息会被扣下，然后过期。源码位置：`internal/gateway/claude_subscription.go`、`internal/claudetui/tui.go` 的 `interactiveArgs`、`internal/gateway/claude_warmup.go` 的 `claudeRunSettings`。
- 脱敏把普通名词当成凭据时（例如 `1Password`、`opx`），把它加进 `~/.config/magpie/settings.json` 的 `redactAllow`（App 里「隐私」页的「从不脱敏」），整词匹配、不分大小写。只对之后新发的文字生效：之前已经脱敏发出去的同一段文字（含全局提示词）为了命中厂商的提示词缓存，在 magpie 重启前继续脱敏。核对看 `~/.config/magpie/masking/<日期>.jsonl` 里新请求的 `values`。
- 已在运行的会话保留启动时的环境变量。用 `ps eww -U $USER | rg -o 'ANTHROPIC_BASE_URL=\S+' | sort | uniq -c` 查还有多少进程绕过 magpie，这些进程要重启才会走新配置。
