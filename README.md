# 🦞 kaeru_claw

**把你的 Mac mini 变成 AI 旅行龙虾 — iPad 走到哪，写到哪。**

> kaeru（かえる）致敬旅行青蛙 — 这次轮到龙虾出门了。

你的 Mac mini 放在家里 24 小时不休眠，iPad 通过 Tailscale 加密隧道随时连回来 — 写代码、跑 AI、看效果。特别适合在公司摸鱼时给自己搞开发，所有流量走 Tailscale 私有网络，完全不经过公司内网，避免任何安全管控和审计。

---

## 这是什么

一套开箱即用的脚本和指南，帮你用 **Mac mini + iPad Air + Tailscale** 搭建安全的远程开发环境。

```
iPad Air (任何网络)                       Mac mini (家里)
  ┌─────────────┐    Tailscale 加密隧道    ┌──────────────┐
  │ Safari      │◄══════════════════════►│ 开发服务器    │
  │ Termius SSH │◄══════════════════════►│ 远程终端      │
  │ RustDesk    │◄══════════════════════►│ 远程桌面      │
  └─────────────┘                        └──────────────┘
       100.x.x.x  ◄── 私有网络 ──►  100.x.x.x
```

**三种访问方式互不冲突，同时使用：**

| 用途 | iPad 端 | 连接方式 |
|------|---------|---------|
| 看网页效果 | Safari | `http://<Mac-IP>:端口` |
| 跑命令 / AI CLI | Termius | SSH 到 Mac mini |
| 图形界面操作 | RustDesk | 远程桌面 |

---

## 快速开始

### Mac mini（5 分钟）

```bash
# 1. 下载脚本
curl -fsSL https://raw.githubusercontent.com/fatmind/kaeru_claw/main/setup-mac.sh -o setup-mac.sh

# 2. 一键配置
chmod +x setup-mac.sh && sudo ./setup-mac.sh

# 3. 检查结果
curl -fsSL https://raw.githubusercontent.com/fatmind/kaeru_claw/main/check.sh -o check.sh
chmod +x check.sh && ./check.sh
```

脚本会自动完成：
- ✅ 安装 Tailscale、RustDesk（通过 Homebrew）
- ✅ 配置「永不睡眠」+ 断电自启 + 网络唤醒
- ✅ 开启 SSH 远程登录
- ✅ 添加开机自启项（Tailscale、RustDesk）
- ✅ 大陆用户自动配置 Homebrew 镜像源 + 终端代理快捷命令

### iPad Air（3 分钟）

手动配置，步骤很少 → [iPad 配置指南](./ipad-guide.md)

需要安装 3 个 App：
1. **Tailscale** — 建立加密隧道
2. **Termius** — SSH 终端
3. **RustDesk** — 远程桌面（可选）

> ⚠️ 大陆用户注意：Tailscale 和 RustDesk 可能不在中国区 App Store，需要用**美区 Apple ID** 下载。详见 [iPad 配置指南](./ipad-guide.md)。

---

## 软件清单

| 软件 | 用途 | Mac mini | iPad |
|------|------|----------|------|
| [Tailscale](https://tailscale.com) | 虚拟专网隧道 | brew 安装 | App Store |
| [RustDesk](https://rustdesk.com) | 远程桌面 | brew 安装 | App Store |
| [Termius](https://termius.com) | SSH 客户端 | — | App Store |

---

## 环境检查

随时运行诊断脚本，确认一切正常：

```bash
./check.sh
```

输出示例：

```
🦞 kaeru_claw 环境检查
━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Tailscale 已安装并运行中
✅ SSH 远程登录已开启
✅ 睡眠已禁用 (sleep=0)
✅ 断电后自动启动已开启
⚠️  RustDesk 未运行（可选组件）
━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 常见问题

<details>
<summary><b>iPad 访问不了 Mac mini？</b></summary>

按顺序排查：
1. iPad 上 Tailscale 是否显示 Connected？
2. Mac mini 设备是否显示绿点在线？
3. `ping <Mac-Tailscale-IP>` 是否通？
4. 开发服务器是否监听了 `0.0.0.0`？（不是 `127.0.0.1`）

开发服务器必须绑定 `0.0.0.0`：
```bash
# Next.js
npm run dev -- -H 0.0.0.0
# Vite
npm run dev -- --host 0.0.0.0
# Python
python3 -m http.server 3000 --bind 0.0.0.0
```
</details>

<details>
<summary><b>SSH 连接被拒？</b></summary>

```bash
# Mac mini 上检查 SSH 是否开启
nc -z localhost 22 && echo "SSH 正常" || echo "SSH 没开"
# 如果没开：系统设置 → 通用 → 共享 → 远程登录
```
</details>

<details>
<summary><b>Tailscale 和翻墙 VPN 冲突？</b></summary>

翻墙工具如果用了 TUN/虚拟网卡模式，会和 Tailscale 冲突（都抢虚拟网卡）。

解决：翻墙工具切到「系统代理」模式（关闭 TUN），Tailscale 保持开启。CLI 工具用 `proxy_on` 走代理。

iPad（iOS 只能同时开一个 VPN）：需要远程时开 Tailscale，不需要时切回翻墙。
</details>

<details>
<summary><b>网站加载特别慢（>500ms）？</b></summary>

可能走了 Tailscale 中继而非直连：
```bash
tailscale status  # 看对端是 direct 还是 relay
```
如果是 relay，两边重启 Tailscale 触发重新打洞。
</details>

<details>
<summary><b>Tailscale IP 会变吗？</b></summary>

不会。100.x.x.x 是固定分配的，除非删除设备重新注册。也可以用设备名代替 IP（需开启 MagicDNS）：`http://your-mac-mini:3000`
</details>

---

## Mac mini 断电恢复链路

配置完成后，停电恢复的自动链路：

```
停电 → 来电 → 自动开机 → 自动登录 → 自启 Tailscale + RustDesk → 远程可连
```

唯一需要手动做的：启动你的开发服务器（因为每次跑的项目不一样）。

---

## 致谢

- [Tailscale](https://tailscale.com) — 让组网变得如此简单
- [RustDesk](https://rustdesk.com) — 开源远程桌面
- [Termius](https://termius.com) — 优秀的移动端 SSH 客户端
- [旅行青蛙](https://ja.wikipedia.org/wiki/%E6%97%85%E3%81%8B%E3%81%88%E3%82%8B) — 感谢那只青蛙带来的灵感

## License

[MIT](./LICENSE)
