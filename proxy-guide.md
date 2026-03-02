# Proxy & VPN Guide for China Mainland Users

[中文](./proxy-guide.zh-CN.md) | English

> If you're outside China, you don't need any of this — Tailscale works out of the box.
>
> This guide is for developers in mainland China who need a proxy/VPN to access international services (GitHub, npm, AI APIs, etc.) while also using Tailscale for remote access.

---

## Recommended Proxy Service (Airport)

| Item | Details |
|------|---------|
| Provider | **JustMySocks (JMS)** |
| Sign up | [justmysocks3.net/members](https://justmysocks3.net/members/) |
| Protocol | Shadowsocks / V2Ray |
| Why JMS | Operated by BandwagonHost, stable IPs, auto-rotation when blocked |

After subscribing, you'll get a subscription URL to import into your proxy client.

---

## Recommended Proxy Clients

| Platform | Client | Download |
|----------|--------|----------|
| **macOS** | Clash Verge Rev | [GitHub Releases](https://github.com/clash-verge-rev/clash-verge-rev/releases) |
| **iPad / iPhone** | Karing | [GitHub](https://github.com/KaringX/karing) / App Store (US account) |
| **Android** | Clash Meta for Android | [clashmetaforandroid.com](https://clashmetaforandroid.com/) |

---

## Clash Verge on Mac: TUN Mode Explained

### The Key Insight

**CLI tools (npm, git, curl, brew, etc.) require TUN mode to go through the proxy. "System Proxy" alone is NOT enough.**

Why: most CLI tools don't read macOS system proxy settings. TUN mode creates a virtual network interface that intercepts ALL traffic at the OS level — CLI tools automatically go through the proxy with zero config.

### Clash Verge Settings Cheat Sheet

![Clash Verge TUN + Global mode](./images/clash-verge-tun-global.png)

| Scenario | Network Setting | Proxy Mode | Notes |
|----------|----------------|------------|-------|
| At home, CLI needs proxy | **TUN (Virtual NIC)** | **Global** | All traffic proxied, zero hassle |
| At home, save bandwidth | **TUN (Virtual NIC)** | **Rule-based** | Only matched traffic proxied, domestic direct |
| Away, need Tailscale | **System Proxy** (TUN off) | Rule/Global | TUN and Tailscale both use virtual NIC — they conflict |

### Critical: TUN Mode and Tailscale Cannot Run Together

Both create a virtual network interface and take over routing. Running both causes:
- Tailscale tunnel goes dead
- DNS resolution breaks
- Traffic gets routed to the wrong tunnel

**The rule: TUN on at home, TUN off + Tailscale on when away.**

---

## The Full Picture

```
┌─────────────────────────────────────────────────┐
│                 At Home                          │
│                                                  │
│  Clash Verge (TUN mode) ── proxy ──► Internet   │
│  Tailscale: OFF                                  │
│                                                  │
│  CLI tools (npm/git/curl) auto-proxied via TUN  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│                 Away (office / cafe)              │
│                                                  │
│  Clash Verge (System Proxy, TUN off)             │
│  Tailscale: ON ── tunnel ──► Mac mini at home   │
│                                                  │
│  CLI tools use proxy_on/proxy_off helpers       │
└─────────────────────────────────────────────────┘
```

---

## See Also

- [Main README](./README.md) — project overview and quick start
- [iPad Setup Guide](./ipad-guide.md) — iPad configuration steps
