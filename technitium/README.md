# Technitium DNS Server（本地 DNS）

本机 DNS 架构说明。Technitium 的配置文件为二进制格式且含本机密码哈希，**不入库**；本文档是唯一入库产物，记录配置意图，换机时照此重建。

## 安装与服务

- 安装：Brewfile 已含 `brew "technitium-dns"`
- 服务：`sudo brew services start technitium-dns`，以 root 运行（LaunchDaemon `file:///Library/LaunchDaemons/homebrew.mxcl.technitium-dns.plist`），启动参数 `--stop-if-bind-fails`
- 配置目录：`file:///opt/homebrew/etc/technitium-dns/`（dns.config / auth.config / zones/ 均为 Technitium 私有二进制格式）
- Web 控制台：`http://127.0.0.1:5380/`

## 角色与监听

- 监听 `127.0.0.1:53`，作为系统主解析器（网络服务的 DNS 手动设为 127.0.0.1）
- 定位：本机递归缓存 + DoT 转发出口 + 承载内网 zone

## 上游转发器（DNS-over-TLS，端口 853）

| Provider | IPv4 | IPv6 |
|---|---|---|
| cloudflare-dns.com | 1.1.1.1 / 1.0.0.1 | 2606:4700:4700::1111 / ::1001 |
| dns.google | 8.8.8.8 / 8.8.4.4 | 2001:4860:4860::8888 / ::8844 |
| dns.quad9.net | 9.9.9.9 / 149.112.112.112 | 2620:fe::fe / 2620:fe::9 |
| dns.opendns.com | 208.67.222.222 / 208.67.220.220 | 2620:119:35::35 / 2620:119:53::53 |
| dns.adguard-dns.com | 94.140.14.14 / 94.140.15.15 | 2a10:50c0::ad1:ff / ::ad2:ff |
| protective.joindns4.eu | 86.54.11.1 / 86.54.11.201 | 2a13:1001::86:54:11:1 / :201 |

## 本地权威 zone

- `lan.sup-any.com`：内网设备域，含 `sup-any` 主机记录（A 192.168.1.1，即家庭网关侧服务）

## 系统 DNS 全景（scutil --dns）

```
resolver #1   默认            -> 127.0.0.1（本机 Technitium）
              search domains: sup-any.com, lan.sup-any.com
resolver #2   sup-any.com     -> 100.168.255.254（NetBird 内置 DNS，supplemental match）
resolver #4   168.100.in-addr.arpa -> 100.168.255.254（NetBird 反解）
```

resolver #2 / #4 由 NetBird daemon 动态注册（`State:/Network/Service/NetBird-Match-0/DNS`），100.168.255.254 是 NetBird 客户端在 utun 接口上自持的 DNS 代理地址，不是远端服务器。

## 已知坑：NetBird 劫持整个 sup-any.com

NetBird 网络的 peer DNS 域被设置为 `sup-any.com`（peer FQDN 形如 `<hostname>.sup-any.com`）。NetBird 客户端因此注册 supplemental resolver，把 **所有** `*.sup-any.com` 查询劫持到自己的内置 DNS，并对该域**权威应答**（flags 带 aa）：

- peer 注册表里存在的名字 -> 返回 overlay IP
- 不存在的名字（包括公网真实存在的子域，如 `https://auth.mip.sup-any.com/`）-> 权威 NXDOMAIN

后果：浏览器等走 mDNSResponder 的应用解析公网 `*.sup-any.com` 子域全部失败（"找不到 IP 地址"）；而 `dig` 只读 /etc/resolv.conf 的 resolver #1（127.0.0.1），解析正常，造成"命令行好的、浏览器坏的"假象。

**根治**：在 NetBird 管理面把网络 DNS 域从 `sup-any.com` 改为专用子域（推荐 `nb.sup-any.com`），使 supplemental match 只覆盖 overlay 子域，公网域恢复走 resolver #1。

## 备份与重建

- 配置为二进制，用控制台 Settings -> Backup 导出 zip 自行保管，不进本仓库
- 重建路径：`brew bundle install` 装包 -> `sudo brew services start technitium-dns` -> 控制台按本文档重建转发器与 zone -> 网络服务 DNS 指向 127.0.0.1
