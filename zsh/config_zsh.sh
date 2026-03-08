#!/bin/bash

# 整合版 ZSH 配置脚本
# 包含依赖检查、安装和配置

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量
OS_TYPE=""
PKG_MANAGER_UPDATE=""
PKG_MANAGER_INSTALL=""
PKG_MANAGER_QUERY="" # For checking if package is installed

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "此脚本需要root权限运行"
        print_info "请使用: sudo $0"
        exit 1
    fi
}

# 检测操作系统并设置包管理器
detect_os() {
    if [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
        PKG_MANAGER_UPDATE="apt-get update"
        PKG_MANAGER_INSTALL="apt-get install -y"
        PKG_MANAGER_QUERY="dpkg -l | grep -q '^ii  %s '"
        print_success "检测到Debian系统"
    elif [ -f /etc/arch-release ]; then
        OS_TYPE="arch"
        PKG_MANAGER_UPDATE="pacman -Sy"
        PKG_MANAGER_INSTALL="pacman -S --noconfirm"
        PKG_MANAGER_QUERY="pacman -Q %s"
        print_success "检测到Arch Linux系统"
    elif [ -f /etc/manjaro-release ]; then
        OS_TYPE="manjaro"
        PKG_MANAGER_UPDATE="pacman -Sy"
        PKG_MANAGER_INSTALL="pacman -S --noconfirm"
        PKG_MANAGER_QUERY="pacman -Q %s"
        print_success "检测到Manjaro Linux系统"
    elif [ -f /etc/openwrt_version ]; then
        OS_TYPE="openwrt"
        PKG_MANAGER_UPDATE="opkg update"
        PKG_MANAGER_INSTALL="opkg install"
        PKG_MANAGER_QUERY="opkg list-installed | grep -q '^%s -'"
        print_success "检测到OpenWrt系统"
    else
        print_error "不支持的操作系统。此脚本仅支持Debian, Arch, Manjaro, OpenWrt。"
        exit 1
    fi
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查包是否已安装
package_installed() {
    local package=$1
    local query_cmd=$(printf "$PKG_MANAGER_QUERY" "$package")
    eval "$query_cmd" >/dev/null 2>&1
}

# 安装单个包
install_package() {
    local package=$1
    if package_installed "$package"; then
        print_success "$package 已安装"
    else
        eval "$PKG_MANAGER_INSTALL $package"
        print_success "$package 安装完成"
    fi
}

# 检查和安装依赖项
install_dependencies() {
    print_info "=== 检查和安装依赖项 ==="
    
    # 更新包列表
    print_info "更新软件包列表..."
    eval "$PKG_MANAGER_UPDATE"
    
    # 必需的软件包
    local packages=()
    case "$OS_TYPE" in
        debian|openwrt)
            packages=(
                "zsh"
                "git" 
                "curl"
                "wget"
                "autojump"
                "fontconfig" # Not available on OpenWrt, will be skipped or handled
            )
            ;;
        arch|manjaro)
            packages=(
                "zsh"
                "git" 
                "curl"
                "wget"
                "autojump" # Will be installed as autojump-zsh by install_package
                "fontconfig"
            )
            ;;
    esac
    
    # 安装软件包
    for package in "${packages[@]}"; do
        # Skip fontconfig for OpenWrt as it's usually not relevant/available
        if [[ "$OS_TYPE" == "openwrt" && "$package" == "fontconfig" ]]; then
            print_warning "OpenWrt系统通常不需要或不提供fontconfig，跳过安装。"
            continue
        fi
        install_package "$package"
    done
    
    print_success "所有依赖项安装完成"
}

# 获取实际用户信息
get_real_user() {
    if [ -n "$SUDO_USER" ]; then
        REAL_USER="$SUDO_USER"
        REAL_HOME="/home/$SUDO_USER"
    else
        REAL_USER="root"
        REAL_HOME="/root"
    fi
    print_info "配置用户: $REAL_USER"
    print_info "用户主目录: $REAL_HOME"
}

# 检查当前shell
check_current_shell() {
    local current_shell=$(getent passwd "$REAL_USER" | cut -d: -f7)
    print_info "当前用户 $REAL_USER 的shell: $current_shell"
    
    if [ "$current_shell" = "/bin/zsh" ] || [ "$current_shell" = "/usr/bin/zsh" ]; then
        print_warning "当前shell已经是zsh"
        return 0
    else
        print_info "当前shell不是zsh，需要切换"
        return 1
    fi
}

# 安装并配置zsh
install_zsh() {
    # 检查zsh是否已安装
    if command_exists zsh; then
        print_success "zsh 已安装"
    else
        print_info "正在安装zsh..."
        eval "$PKG_MANAGER_INSTALL zsh"
        print_success "zsh 安装完成"
    fi

    print_info "=== 配置ZSH ==="
    # 设置zsh为默认shell
    print_info "设置zsh为默认shell..."
    chsh -s "$(command -v zsh)" "$REAL_USER"
    print_success "已设置zsh为 $REAL_USER 的默认shell"
    # 提醒注销重新打开终端
    print_warning "请注销并重新打开终端使zsh生效"
}

# 安装oh-my-zsh
install_oh_my_zsh() {
    print_info "=== 安装Oh My Zsh ==="
    
    local oh_my_zsh_dir="$REAL_HOME/.oh-my-zsh"
    
    if [ -d "$oh_my_zsh_dir" ]; then
        print_warning "Oh My Zsh 已存在，跳过安装"
        return
    fi
    
    print_info "正在安装Oh My Zsh..."
    # 使用sudo -u切换到目标用户执行git clone
    # Note: This script is run as root, so git clone needs to be run as REAL_USER
    sudo -u "$REAL_USER" git clone https://github.com/robbyrussell/oh-my-zsh.git "$oh_my_zsh_dir"
    print_success "Oh My Zsh 安装完成"

    # 安装powerlevel10k主题
    print_info "正在安装powerlevel10k主题..."
    sudo -u "$REAL_USER" git clone https://github.com/romkatv/powerlevel10k.git "$oh_my_zsh_dir/themes/powerlevel10k"
    print_success "powerlevel10k主题安装完成"
}

# 安装 MesloLGS NF 字体
install_fonts() {
    # Skip font installation for OpenWrt
    if [ "$OS_TYPE" == "openwrt" ]; then
        print_warning "OpenWrt系统通常不需要图形字体，跳过字体安装。"
        return
    fi

    print_info "=== 安装 MesloLGS NF 字体 ==="
    
    local font_dir="/usr/share/fonts/truetype/meslo"
    
    if [ -d "$font_dir" ]; then
        print_warning "MesloLGS NF 字体目录已存在，跳过安装"
        return
    fi
    
    print_info "正在下载 MesloLGS NF 字体..."
    mkdir -p "$font_dir"
    
    local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
    wget -q --show-progress -O "$font_dir/MesloLGS NF Regular.ttf" "$base_url/MesloLGS%20NF%20Regular.ttf"
    wget -q --show-progress -O "$font_dir/MesloLGS NF Bold.ttf" "$base_url/MesloLGS%20NF%20Bold.ttf"
    wget -q --show-progress -O "$font_dir/MesloLGS NF Italic.ttf" "$base_url/MesloLGS%20NF%20Italic.ttf"
    wget -q --show-progress -O "$font_dir/MesloLGS NF Bold Italic.ttf" "$base_url/MesloLGS%20NF%20Bold%20Italic.ttf"
    
    print_info "更新字体缓存..."
    fc-cache -f -v "$font_dir" > /dev/null 2>&1
    print_success "MesloLGS NF 字体安装完成"
}

# 下载和配置.zshrc
configure_zshrc() {
    print_info "=== 配置.zshrc ==="

    local target_file="$REAL_HOME/.zshrc"

    # OpenWrt：写入最小化配置，无需联网
    if [ "$OS_TYPE" = "openwrt" ]; then
        print_info "OpenWrt: 写入最小化 .zshrc..."
        cat > "$target_file" <<'EOF'
# OpenWrt minimal zshrc
export TERM=xterm-256color
autoload -Uz compinit && compinit
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %# '
EOF
        chown "$REAL_USER:$REAL_USER" "$target_file" 2>/dev/null || true
        print_success "最小化 .zshrc 配置完成"
        return
    fi

    local github_url="https://raw.githubusercontent.com/ChaunceyXCX/my-config-files/master/zsh/.zshrc"
    local temp_file="/tmp/temp_zshrc"

    # 下载配置文件
    print_info "下载zshrc配置文件..."
    if ! curl -fSL -o "$temp_file" "$github_url"; then
        print_error "zshrc配置文件下载失败"
        return 1
    fi

    # 处理目标文件
    if [ ! -f "$target_file" ]; then
        print_info "$target_file 不存在，正在创建..."
        touch "$target_file"
    else
        print_info "$target_file 已存在，将追加内容"
    fi

    # 插入文件内容
    cat "$temp_file" >> "$target_file"
    chown "$REAL_USER:$REAL_USER" "$target_file"
    rm "$temp_file"

    print_success "zshrc配置完成"
}

# 安装zsh插件
install_zsh_plugins() {
    print_info "=== 安装ZSH插件 ==="
    
    local plugins_dir="$REAL_HOME/.oh-my-zsh/custom/plugins" # Use custom plugins directory
    mkdir -p "$plugins_dir" # Ensure directory exists
    
    # 自动提示插件
    if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
        print_info "安装zsh-autosuggestions插件..."
        sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"
        print_success "zsh-autosuggestions 安装完成"
    else
        print_success "zsh-autosuggestions 已存在"
    fi

    # 语法高亮插件
    if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        print_info "安装zsh-syntax-highlighting插件..."
        sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting 安装完成"
    else
        print_success "zsh-syntax-highlighting 已存在"
    fi
}

# 显示完成信息
show_completion_info() {
    print_success "=== ZSH配置完成 ==="
    echo
    print_info "安装的组件："
    echo "  ✅ ZSH shell"
    echo "  ✅ Oh My Zsh"
    if [ "$OS_TYPE" != "openwrt" ]; then
        echo "  ✅ MesloLGS NF 字体"
    fi
    echo "  ✅ zsh-syntax-highlighting (语法高亮)" 
    echo "  ✅ zsh-autosuggestions (自动补全)" # Changed from 'incr' to 'zsh-autosuggestions'
    echo "  ✅ autojump (目录跳转)"
    echo
    print_warning "重要提醒："
    echo "  1. 需要重新登录或重启终端才能使用zsh"
    echo "  2. 首次使用zsh时会有配置向导"
    echo "  3. 配置文件位置: $REAL_HOME/.zshrc"
    echo
    print_info "常用命令："
    echo "  - 使用 'j <目录名>' 快速跳转目录"
    echo "  - 输入命令时会有自动建议（按右箭头接受）"
    echo
}

# 主函数
main() {
    echo
    print_info "=== ZSH一键配置脚本 ==="
    print_info "支持系统: Debian / Ubuntu / Arch / Manjaro / OpenWrt"
    echo

    # 检查权限 & 检测系统
    check_root
    detect_os
    get_real_user

    # 安装依赖
    install_dependencies

    # 配置 zsh 默认 shell
    check_current_shell || true
    install_zsh

    # Oh My Zsh / 字体 / 插件（OpenWrt 跳过）
    if [ "$OS_TYPE" != "openwrt" ]; then
        install_oh_my_zsh
        install_fonts
        install_zsh_plugins
    fi

    # 写入 .zshrc
    configure_zshrc

    # 显示完成信息
    show_completion_info

    print_success "脚本执行完成！"
    print_info "请重新登录以使用zsh"
}

# 运行主函数
main "$@"
