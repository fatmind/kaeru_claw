# iPad Air Setup Guide

[中文](./ipad-guide.zh-CN.md) | English

> About 3 minutes. Everything is done on the iPad.

---

## ⚠️ China Mainland Users

Tailscale and RustDesk are **not available on the China App Store**. You need a **US Apple ID** to download them.

If you don't have one yet:
1. Go to [appleid.apple.com](https://appleid.apple.com) and create a new Apple ID
2. Set Country/Region to **United States**
3. Payment method: **None**
4. Use any US address (e.g. a tax-free state like Oregon)
5. On iPad: App Store → tap profile → Sign Out → Sign in with the US account
6. Download the apps, then switch back to your China account

> Termius is available on the China App Store — no US account needed.

---

## Step 1: Install Apps (3 total)

Search and install from the App Store:

| App | Purpose | Price |
|-----|---------|-------|
| **Tailscale** | Encrypted tunnel back to Mac mini | Free |
| **Termius** | SSH terminal | Free |
| **RustDesk** | Remote desktop (optional) | Free |

---

## Step 2: Set Up Tailscale

1. Open Tailscale
2. Tap **Sign in** → log in with the **same account** as your Mac mini
3. Allow the VPN configuration prompt
4. Wait for connection — Mac mini shows a **green dot** = success

> Both devices must be logged into the same Tailscale account.

Note your Mac mini's Tailscale IP (100.x.x.x format) — you'll need it next.

How to find it: tap on your Mac mini in the Tailscale device list.

---

## Step 3: Set Up Termius (SSH Terminal)

1. Open Termius → tap **+** → **New Host**
2. Fill in:

| Field | Value |
|-------|-------|
| Alias | Any name, e.g. `Mac mini` |
| Hostname | Mac mini's Tailscale IP (e.g. `100.65.176.14`) |
| Port | `22` |
| Username | Your Mac mini username (e.g. `shijian`) |
| Password | Your Mac mini login password |

3. Tap **Save**, then tap to connect
4. First time: trust the host fingerprint → tap **Continue**
5. See a command prompt = success

### What You Can Do

```bash
# Run shell commands remotely
ls -la

# Start a dev server (remember 0.0.0.0)
cd ~/your-project
npm run dev -- -H 0.0.0.0
```

---

## Step 4: Set Up RustDesk (Optional, Remote Desktop)

1. Open RustDesk → enter Mac mini's **Tailscale IP** (recommended)
2. Connect → enter the RustDesk password (check Mac mini's RustDesk settings)
3. See Mac mini desktop = success

> Always use the Tailscale IP — traffic stays in the encrypted tunnel.

---

## Daily Workflow

```
1. Open Tailscale on iPad → confirm Mac mini is online (green dot)
2. Preview web UI  → Safari: http://<Mac-IP>:3000
3. Run commands    → Termius SSH
4. GUI access      → RustDesk
```

---

## China Users: Tailscale vs Proxy VPN

On iPad, both Tailscale and proxy tools use the VPN slot. iOS only allows one VPN at a time.

**Solution: switch as needed.**

| Need to... | Turn on |
|------------|---------|
| Access Mac mini remotely | Tailscale |
| Browse blocked sites | Proxy tool |

How to switch: Settings → VPN → toggle.

---

## Troubleshooting

### Can't connect to Mac mini?

1. Is Tailscale showing "Connected"?
2. Is Mac mini online (green dot)? → If not, check if Tailscale is running on the Mac
3. Can ping but service not responding? → Check if dev server is listening on `0.0.0.0`

### SSH connection timeout?

- Check if SSH is enabled on Mac mini (setup-mac.sh enables it automatically)
- Verify the Tailscale IP is correct
- Try pinging Mac mini from the Tailscale app

### RustDesk won't connect?

- Confirm RustDesk is running on Mac mini
- Use the Tailscale IP, not the RustDesk ID
- Mac mini needs Accessibility, Input Monitoring, and Screen Recording permissions for RustDesk
