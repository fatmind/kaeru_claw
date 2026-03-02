# iPad Air 配置指南

[English](./ipad-guide.md) | 中文

> 大约 3 分钟完成，全部在 iPad 上操作。

---

## ⚠️ 大陆用户必读

Tailscale 和 RustDesk **不在中国区 App Store** 上架。你需要一个**美区 Apple ID** 才能下载。

如果还没有美区账号：
1. 在 [appleid.apple.com](https://appleid.apple.com) 注册一个新 Apple ID
2. 国家/地区选 **United States**
3. 付款方式选 **None**
4. 地址可以填美国免税州地址（如 Oregon）
5. 注册完成后，在 iPad 的 App Store → 头像 → 退出登录 → 用美区账号登录
6. 下载完所需 App 后，可以切回中国区账号

> Termius 在中国区 App Store 也有，可以用中国区账号下载。

---

## 第一步：安装 App（3 个）

用**美区 Apple ID** 登录 App Store 后搜索安装：

| App | 用途 | 价格 |
|-----|------|------|
| **Tailscale** | 建立加密隧道，连回 Mac mini | 免费 |
| **Termius** | SSH 终端，跑命令 | 免费 |
| **RustDesk** | 远程桌面，看 Mac 屏幕（可选） | 免费 |

---

## 第二步：配置 Tailscale

1. 打开 Tailscale App
2. 点击 **Sign in** → 用和 Mac mini **同一个账号**登录
3. 允许 VPN 配置弹窗
4. 等待连接，看到设备列表中 Mac mini 显示**绿点** = 成功

> 必须用同一个 Tailscale 账号登录，两台设备才能互通。

记下 Mac mini 的 Tailscale IP（100.x.x.x 格式），后面要用。

查看方式：Tailscale App 设备列表里点击 Mac mini 即可看到。

---

## 第三步：配置 Termius（SSH 终端）

1. 打开 Termius → 点击 **+** → **New Host**
2. 填写：

| 字段 | 值 |
|------|-----|
| Alias | 随便起名，比如 `Mac mini` |
| Hostname | Mac mini 的 Tailscale IP（如 `100.65.176.14`） |
| Port | `22` |
| Username | Mac mini 的用户名（如 `shijian`） |
| Password | Mac mini 的开机密码 |

3. 点击 **Save**，然后点击连接
4. 首次连接会提示信任主机指纹，点 **Continue**
5. 看到命令行提示符 = 成功

### 连上之后能做什么

```bash
# 远程执行 shell
ls -la

# 启动开发服务器（记得加 0.0.0.0）
cd ~/your-project
npm run dev -- -H 0.0.0.0
```

---

## 第四步：配置 RustDesk（可选，远程桌面）

1. 打开 RustDesk → 输入 Mac mini 的 **Tailscale IP**（推荐）
2. 点击连接 → 输入 RustDesk 密码（在 Mac mini 的 RustDesk 设置中查看）
3. 看到 Mac mini 桌面 = 成功

> 优先用 Tailscale IP 连接，数据走加密隧道不经公网。

---

## 日常使用流程

```
1. 打开 iPad 上的 Tailscale → 确认 Mac mini 在线（绿点）
2. 看网页效果 → Safari 输入 http://<Mac-IP>:3000
3. 跑命令     → Termius 连 SSH
4. 看桌面     → RustDesk 连桌面
```

---

## 大陆用户：Tailscale 与翻墙 VPN 切换

iPad 上 Tailscale 和翻墙工具都用 VPN 通道，iOS 只能同时开一个 VPN。

**解决方案：按需切换。**

| 需要做什么 | 开哪个 |
|-----------|--------|
| 远程访问 Mac mini | Tailscale |
| 翻墙上网 | 翻墙工具 |

切换方法：设置 → VPN → 切换开关。

---

## 常见问题

### 连不上 Mac mini？

1. Tailscale 是否显示 Connected？
2. Mac mini 是否在线（绿点）？→ 不在线说明 Mac mini 端 Tailscale 没开或网络有问题
3. 能 ping 通但服务不响应？→ 检查开发服务器是否监听了 `0.0.0.0`

### SSH 连接超时？

- 检查 Mac mini 的 SSH 是否开启（setup-mac.sh 会自动开）
- 检查 Tailscale IP 是否正确
- 尝试在 Tailscale App 里 ping Mac mini

### RustDesk 连不上？

- 确认 Mac mini 上 RustDesk 正在运行
- 确认用的是 Tailscale IP 而不是 RustDesk ID
- Mac mini 上 RustDesk 需要「辅助功能」「输入监控」「屏幕录制」权限
