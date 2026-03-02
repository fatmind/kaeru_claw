#!/bin/bash
set -e

# ============================================================
# kaeru_claw — Mac mini 一键初始化脚本
# 把你的 Mac mini 变成 AI 旅行龙虾
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

IS_CHINA=false
PROXY_PORT="${PROXY_PORT:-7897}"

print_banner() {
    echo ""
    echo -e "${RED}  🦞 kaeru_claw${NC}"
    echo -e "  Mac mini 一键配置脚本"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }
ok()      { echo -e "  ${GREEN}✅${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠️${NC}  $1"; }
fail()    { echo -e "  ${RED}❌${NC} $1"; }
step()    { echo -e "\n  ${BLUE}▸ $1${NC}"; }

need_sudo() {
    if [ "$EUID" -ne 0 ]; then
        fail "请用 sudo 运行此脚本：sudo ./setup-mac.sh"
        exit 1
    fi
}

# ────────────────────────────────────────
# 0. 询问用户所在地区
# ────────────────────────────────────────
ask_region() {
    step "地区选择"
    echo ""
    echo "  你在中国大陆吗？"
    echo "  大陆用户会自动配置 Homebrew 镜像源和终端代理快捷命令"
    echo ""
    read -p "  是否中国大陆用户？[y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        IS_CHINA=true
        ok "已选择：中国大陆（将配置国内镜像源）"
    else
        IS_CHINA=false
        ok "已选择：海外（使用默认源）"
    fi
}

# ────────────────────────────────────────
# 1. 配置 Homebrew 镜像（大陆用户）
# ────────────────────────────────────────
configure_brew_mirror() {
    if [ "$IS_CHINA" = false ]; then
        return
    fi

    step "配置 Homebrew 国内镜像（清华源）"
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(eval echo "~$REAL_USER")
    ZSHRC="$REAL_HOME/.zshrc"

    MIRROR_BLOCK='
# ── kaeru_claw Homebrew 镜像（清华源）──
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
# ── kaeru_claw Homebrew 镜像 END ──'

    if [ -f "$ZSHRC" ] && grep -q "kaeru_claw Homebrew 镜像" "$ZSHRC"; then
        ok "Homebrew 镜像已配置"
    else
        echo "$MIRROR_BLOCK" >> "$ZSHRC"
        chown "$REAL_USER" "$ZSHRC"
        ok "Homebrew 清华镜像已写入 .zshrc"
    fi

    # 让当前 shell 也生效
    export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
}

# ────────────────────────────────────────
# 2. 安装 Homebrew（如果没有）
# ────────────────────────────────────────
install_homebrew() {
    step "检查 Homebrew"
    if command -v brew &>/dev/null; then
        ok "Homebrew 已安装"
    else
        info "安装 Homebrew..."
        REAL_USER="${SUDO_USER:-$USER}"
        if [ "$IS_CHINA" = true ]; then
            # 大陆使用清华镜像安装
            sudo -u "$REAL_USER" /bin/bash -c "$(curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install/raw/HEAD/install.sh)"
        else
            sudo -u "$REAL_USER" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        ok "Homebrew 安装完成"
    fi
}

# ────────────────────────────────────────
# 3. 安装必要软件
# ────────────────────────────────────────
install_apps() {
    step "安装必要软件"
    REAL_USER="${SUDO_USER:-$USER}"

    local apps=("tailscale" "rustdesk")
    for app in "${apps[@]}"; do
        if sudo -u "$REAL_USER" brew list --cask "$app" &>/dev/null; then
            ok "$app 已安装"
        else
            info "安装 $app..."
            sudo -u "$REAL_USER" brew install --cask "$app"
            ok "$app 安装完成"
        fi
    done
}

# ────────────────────────────────────────
# 4. 配置能耗设置（永不睡眠）
# ────────────────────────────────────────
configure_energy() {
    step "配置能耗设置"

    pmset -a sleep 0
    ok "系统睡眠 → 永不"

    pmset -a disablesleep 1
    ok "禁用睡眠开关 → 开启"

    pmset -a displaysleep 10
    ok "显示器休眠 → 10 分钟（省电，不影响运行）"

    pmset -a tcpkeepalive 1
    ok "TCP 保持连接 → 开启（Tailscale 隧道不断）"

    pmset -a womp 1
    ok "网络唤醒 → 开启"

    pmset -a autorestart 1
    ok "断电后自动启动 → 开启"

    pmset -a powernap 0
    ok "Power Nap → 关闭"
}

# ────────────────────────────────────────
# 5. 开启 SSH 远程登录
# ────────────────────────────────────────
enable_ssh() {
    step "开启 SSH 远程登录"

    if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
        ok "SSH 远程登录已开启"
    else
        systemsetup -setremotelogin on
        ok "SSH 远程登录已开启"
    fi
}

# ────────────────────────────────────────
# 6. 添加开机自启项
# ────────────────────────────────────────
add_login_items() {
    step "配置开机自启项"
    REAL_USER="${SUDO_USER:-$USER}"

    local apps_to_add=(
        "/Applications/Tailscale.app"
        "/Applications/RustDesk.app"
    )

    for app_path in "${apps_to_add[@]}"; do
        app_name=$(basename "$app_path" .app)
        if [ -d "$app_path" ]; then
            sudo -u "$REAL_USER" osascript -e "
                tell application \"System Events\"
                    if not (exists login item \"$app_name\") then
                        make login item at end with properties {path:\"$app_path\", hidden:false}
                    end if
                end tell
            " 2>/dev/null
            ok "$app_name → 开机自启"
        else
            warn "$app_name 未安装，跳过"
        fi
    done
}

# ────────────────────────────────────────
# 7. 配置终端代理快捷命令（大陆用户）
# ────────────────────────────────────────
configure_proxy_helpers() {
    if [ "$IS_CHINA" = false ]; then
        return
    fi

    step "配置终端代理快捷命令"
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(eval echo "~$REAL_USER")
    ZSHRC="$REAL_HOME/.zshrc"

    PROXY_BLOCK="
# ── kaeru_claw 代理快捷命令 ──
proxy_on() {
    export https_proxy=http://127.0.0.1:${PROXY_PORT}
    export http_proxy=http://127.0.0.1:${PROXY_PORT}
    export all_proxy=socks5://127.0.0.1:${PROXY_PORT}
    echo \"🦞 代理已开启 (port ${PROXY_PORT})\"
}
proxy_off() {
    unset https_proxy http_proxy all_proxy
    echo \"🦞 代理已关闭\"
}
# ── kaeru_claw END ──"

    if [ -f "$ZSHRC" ] && grep -q "kaeru_claw 代理快捷命令" "$ZSHRC"; then
        ok "代理快捷命令已存在于 .zshrc"
    else
        echo "$PROXY_BLOCK" >> "$ZSHRC"
        chown "$REAL_USER" "$ZSHRC"
        ok "已添加 proxy_on / proxy_off 到 .zshrc"
    fi

    info "使用方法：proxy_on 开启代理，proxy_off 关闭代理"
    info "代理端口：${PROXY_PORT}（可通过 PROXY_PORT 环境变量自定义）"
}

# ────────────────────────────────────────
# 8. 启动 Tailscale
# ────────────────────────────────────────
start_tailscale() {
    step "启动 Tailscale"

    if [ -d "/Applications/Tailscale.app" ]; then
        REAL_USER="${SUDO_USER:-$USER}"
        sudo -u "$REAL_USER" open -a "Tailscale"
        ok "Tailscale 已启动"
        info "首次使用请在菜单栏点击 Tailscale 图标登录"
    else
        warn "Tailscale 未安装"
    fi
}

# ────────────────────────────────────────
# 汇总
# ────────────────────────────────────────
print_summary() {
    echo ""
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${GREEN}✅ Mac mini 配置完成！${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  接下来你需要："
    echo ""
    echo "  1. 点击菜单栏 Tailscale 图标 → 登录你的账号"
    echo "  2. 记下你的 Tailscale IP（100.x.x.x）"
    echo "  3. 在 iPad 上配置（参考 ipad-guide.md）"
    echo "  4. 启动开发服务器时加上 -H 0.0.0.0 / --host 0.0.0.0"
    echo ""
    if [ "$IS_CHINA" = true ]; then
        echo "  大陆用户提示："
        echo "  • 新开终端后 Homebrew 镜像自动生效"
        echo "  • proxy_on / proxy_off 控制终端代理"
        echo ""
    fi
    echo "  运行 ./check.sh 随时检查环境状态"
    echo ""
}

# ════════════════════════════════════════
# MAIN
# ════════════════════════════════════════
print_banner
need_sudo
ask_region
configure_brew_mirror
install_homebrew
install_apps
configure_energy
enable_ssh
add_login_items
configure_proxy_helpers
start_tailscale
print_summary
