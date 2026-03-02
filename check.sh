#!/bin/bash

# ============================================================
# kaeru_claw — 环境检查脚本
# 快速诊断 Mac mini 远程开发环境状态
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

ok()   { echo -e "  ${GREEN}✅${NC} $1"; ((PASS++)); }
warn() { echo -e "  ${YELLOW}⚠️${NC}  $1"; ((WARN++)); }
fail() { echo -e "  ${RED}❌${NC} $1"; ((FAIL++)); }
dim()  { echo -e "  ${GRAY}   $1${NC}"; }

echo ""
echo -e "  ${RED}🦞 kaeru_claw 环境检查${NC}"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Tailscale ──
echo -e "  ${BLUE}▸ Tailscale${NC}"

if command -v tailscale &>/dev/null || [ -d "/Applications/Tailscale.app" ]; then
    ok "Tailscale 已安装"
else
    fail "Tailscale 未安装"
fi

if pgrep -x "Tailscale" &>/dev/null || pgrep -f "tailscaled" &>/dev/null; then
    ok "Tailscale 正在运行"

    TS_IP=$(tailscale ip -4 2>/dev/null)
    if [ -n "$TS_IP" ]; then
        ok "Tailscale IP: $TS_IP"
    else
        warn "Tailscale 运行中但未获取到 IP（可能未登录）"
    fi

    TS_STATUS=$(tailscale status --json 2>/dev/null | grep -o '"BackendState":"[^"]*"' | head -1)
    if echo "$TS_STATUS" | grep -q "Running"; then
        ok "Tailscale 状态: 已连接"
    else
        warn "Tailscale 状态异常，请检查登录状态"
    fi
else
    fail "Tailscale 未运行"
    dim "打开 /Applications/Tailscale.app 或运行: open -a Tailscale"
fi

echo ""

# ── SSH ──
echo -e "  ${BLUE}▸ SSH 远程登录${NC}"

if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
    ok "SSH 远程登录已开启"
else
    fail "SSH 远程登录未开启"
    dim "开启方法: 系统设置 → 通用 → 共享 → 远程登录"
fi

if nc -z localhost 22 2>/dev/null; then
    ok "SSH 端口 22 可访问"
else
    fail "SSH 端口 22 不可访问"
fi

echo ""

# ── 能耗设置 ──
echo -e "  ${BLUE}▸ 能耗设置${NC}"

PMSET_OUTPUT=$(pmset -g 2>/dev/null)

SLEEP_VAL=$(echo "$PMSET_OUTPUT" | grep -E "^ sleep\b" | awk '{print $2}')
if [ "$SLEEP_VAL" = "0" ]; then
    ok "系统睡眠: 永不 (sleep=0)"
else
    fail "系统睡眠: ${SLEEP_VAL} 分钟（应为 0）"
    dim "修复: sudo pmset -a sleep 0"
fi

if echo "$PMSET_OUTPUT" | grep -q "SleepDisabled.*1"; then
    ok "睡眠禁用开关: 已开启"
else
    warn "睡眠禁用开关: 未开启"
    dim "修复: sudo pmset -a disablesleep 1"
fi

WOMP_VAL=$(echo "$PMSET_OUTPUT" | grep -E "^ womp\b" | awk '{print $2}')
if [ "$WOMP_VAL" = "1" ]; then
    ok "网络唤醒: 已开启"
else
    warn "网络唤醒: 未开启"
    dim "修复: sudo pmset -a womp 1"
fi

TCP_VAL=$(echo "$PMSET_OUTPUT" | grep "tcpkeepalive" | awk '{print $2}')
if [ "$TCP_VAL" = "1" ]; then
    ok "TCP 保持连接: 已开启"
else
    warn "TCP 保持连接: 未开启"
    dim "修复: sudo pmset -a tcpkeepalive 1"
fi

AUTORESTART=$(echo "$PMSET_OUTPUT" | grep "autorestart" | awk '{print $2}')
if [ "$AUTORESTART" = "1" ]; then
    ok "断电后自动启动: 已开启"
else
    warn "断电后自动启动: 未开启"
    dim "修复: sudo pmset -a autorestart 1"
fi

echo ""

# ── RustDesk ──
echo -e "  ${BLUE}▸ RustDesk（可选）${NC}"

if [ -d "/Applications/RustDesk.app" ]; then
    ok "RustDesk 已安装"
    if pgrep -x "RustDesk" &>/dev/null; then
        ok "RustDesk 正在运行"
    else
        warn "RustDesk 未运行（可选组件，需要时再开）"
    fi
else
    warn "RustDesk 未安装（可选组件）"
    dim "安装: brew install --cask rustdesk"
fi

echo ""

# ── Clash Verge（可选）──
echo -e "  ${BLUE}▸ Clash Verge（可选，大陆用户）${NC}"

if [ -d "/Applications/Clash Verge.app" ]; then
    ok "Clash Verge 已安装"
    if pgrep -f "Clash Verge" &>/dev/null || pgrep -f "clash-verge" &>/dev/null; then
        ok "Clash Verge 正在运行"
    else
        warn "Clash Verge 未运行"
    fi
else
    warn "Clash Verge 未安装（大陆用户可选）"
fi

echo ""

# ── 代理快捷命令 ──
echo -e "  ${BLUE}▸ 终端代理快捷命令${NC}"

if [ -f "$HOME/.zshrc" ] && grep -q "kaeru_claw 代理快捷命令" "$HOME/.zshrc"; then
    ok "proxy_on / proxy_off 已配置"
else
    warn "代理快捷命令未配置"
    dim "运行 setup-mac.sh 可自动配置"
fi

echo ""

# ── 开发服务器检测 ──
echo -e "  ${BLUE}▸ 开发服务器${NC}"

DEV_FOUND=false
for port in 3000 3001 5173 5174 8000 8080 8888; do
    LISTEN_INFO=$(lsof -i :$port -sTCP:LISTEN 2>/dev/null | tail -1)
    if [ -n "$LISTEN_INFO" ]; then
        LISTEN_ADDR=$(echo "$LISTEN_INFO" | awk '{print $9}')
        PROC_NAME=$(echo "$LISTEN_INFO" | awk '{print $1}')
        if echo "$LISTEN_ADDR" | grep -q "^\*:"; then
            ok "端口 $port ($PROC_NAME) — 监听 0.0.0.0 ✓"
        else
            warn "端口 $port ($PROC_NAME) — 监听 $LISTEN_ADDR（应为 0.0.0.0）"
        fi
        DEV_FOUND=true
    fi
done

if [ "$DEV_FOUND" = false ]; then
    warn "未检测到开发服务器（常用端口 3000/5173/8000/8080）"
    dim "启动时记得加 --host 0.0.0.0 或 -H 0.0.0.0"
fi

# ── 汇总 ──
echo ""
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}✅ $PASS 通过${NC}  ${YELLOW}⚠️ $WARN 警告${NC}  ${RED}❌ $FAIL 失败${NC}"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
