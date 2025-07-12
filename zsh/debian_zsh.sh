#!/bin/bash

# 获取实际用户信息
get_real_user() {
    REAL_USER="root"
    REAL_HOME="/root"
    print_info "强制使用root用户配置"
    print_info "用户主目录: $REAL_HOME"
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
    # 移除sudo -u切换用户
    git clone https://github.com/robbyrussell/oh-my-zsh.git "$oh_my_zsh_dir"
    print_success "Oh My Zsh 安装完成"
}

# 下载和配置.zshrc
configure_zshrc() {
    // ... 其他代码保持不变 ...
    
    # 处理目标文件（移除sudo切换用户）
    if [ ! -f "$target_file" ]; then
        print_info "$target_file 不存在，正在创建..."
        touch "$target_file"
    else
        print_info "$target_file 已存在，将追加内容"
    fi
    
    # 插入文件内容（移除权限修改）
    cat "$temp_file" >> "$target_file"
    // ... 后续代码保持不变 ...
}

# 安装zsh插件
install_zsh_plugins() {
    // ... 其他代码保持不变 ...
    
    # 语法高亮插件（移除sudo切换用户）
    if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        print_info "安装zsh-syntax-highlighting插件..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting 安装完成"
    fi
    
    # 自动补全插件（移除sudo切换用户）
    if [ ! -d "$plugins_dir/incr" ]; then
        print_info "安装incr自动补全插件..."
        local incr_file="/tmp/incr-0.2.zsh"
        wget -O "$incr_file" http://mimosa-pudica.net/src/incr-0.2.zsh
        mkdir -p "$plugins_dir/incr"
        mv "$incr_file" "$plugins_dir/incr/"
        print_success "incr自动补全插件安装完成"
    fi
}
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

# 检查系统是否为Debian
check_debian() {
    if [ ! -f /etc/debian_version ]; then
        print_error "此脚本仅支持Debian系统"
        exit 1
    fi
    print_success "检测到Debian系统"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查包是否已安装
package_installed() {
    dpkg -l | grep -q "^ii  $1 " 2>/dev/null
}

# 安装单个包
install_package() {
    local package=$1
    if package_installed "$package"; then
        print_success "$package 已安装"
    else
        print_info "正在安装 $package..."
        apt-get install -y "$package"
        print_success "$package 安装完成"
    fi
}

# 检查和安装依赖项
install_dependencies() {
    print_info "=== 检查和安装依赖项 ==="
    
    # 更新包列表
    print_info "更新软件包列表..."
    apt-get update
    
    # 必需的软件包
    local packages=(
        "zsh"
        "git" 
        "curl"
        "wget"
        "autojump"
    )
    
    # 安装软件包
    for package in "${packages[@]}"; do
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

# 安装zsh
install_zsh() {
    print_info "=== 配置ZSH ==="
    
    # 设置zsh为默认shell
    print_info "设置zsh为默认shell..."
    chsh -s /bin/zsh "$REAL_USER"
    print_success "已设置zsh为 $REAL_USER 的默认shell"
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
    sudo -u "$REAL_USER" git clone https://github.com/robbyrussell/oh-my-zsh.git "$oh_my_zsh_dir"
    print_success "Oh My Zsh 安装完成"
}

# 下载和配置.zshrc
configure_zshrc() {
    print_info "=== 配置.zshrc ==="
    
    local github_url="https://raw.githubusercontent.com/ChaunceyXCX/my-config-files/master/zsh/.zshrc"
    local target_file="$REAL_HOME/.zshrc"
    local temp_file="/tmp/temp_zshrc"
    
    # 下载配置文件
    print_info "下载zshrc配置文件..."
    curl -o "$temp_file" "$github_url"
    
    if [ $? -ne 0 ]; then
        print_error "zshrc配置文件下载失败"
        return 1
    fi
    
    # 处理目标文件
    if [ ! -f "$target_file" ]; then
        print_info "$target_file 不存在，正在创建..."
        sudo -u "$REAL_USER" touch "$target_file"
    else
        print_info "$target_file 已存在，将追加内容"
    fi
    
    # 插入文件内容
    cat "$temp_file" >> "$target_file"
    chown "$REAL_USER:$REAL_USER" "$target_file"
    
    # 删除临时文件
    rm "$temp_file"
    
    print_success "zshrc配置完成"
}

# 安装zsh插件
install_zsh_plugins() {
    print_info "=== 安装ZSH插件 ==="
    
    local plugins_dir="$REAL_HOME/.oh-my-zsh/plugins"
    
    # 自动建议插件
    # if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
    #     print_info "安装zsh-autosuggestions插件..."
    #     sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    #     print_success "zsh-autosuggestions 安装完成"
    # else
    #     print_success "zsh-autosuggestions 已存在"
    # fi
    
    # 语法高亮插件
    if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        print_info "安装zsh-syntax-highlighting插件..."
        sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting 安装完成"
    else
        print_success "zsh-syntax-highlighting 已存在"
    fi
    
    # 自动补全插件
    if [ ! -d "$plugins_dir/incr" ]; then
        print_info "安装incr自动补全插件..."
        local incr_file="/tmp/incr-0.2.zsh"
        wget -O "$incr_file" http://mimosa-pudica.net/src/incr-0.2.zsh
        sudo -u "$REAL_USER" mkdir -p "$plugins_dir/incr"
        mv "$incr_file" "$plugins_dir/incr/"
        chown -R "$REAL_USER:$REAL_USER" "$plugins_dir/incr"
        print_success "incr自动补全插件安装完成"
    else
        print_success "incr自动补全插件已存在"
    fi
}

# 显示完成信息
show_completion_info() {
    print_success "=== ZSH配置完成 ==="
    echo
    print_info "安装的组件："
    echo "  ✅ ZSH shell"
    echo "  ✅ Oh My Zsh"
    # echo "  ✅ zsh-autosuggestions (自动建议)"
    echo "  ✅ zsh-syntax-highlighting (语法高亮)" 
    echo "  ✅ incr (自动补全)"
    # echo "  ✅ bat (高亮版cat)"
    echo "  ✅ autojump (目录跳转)"
    echo
    print_warning "重要提醒："
    echo "  1. 需要重新登录或重启终端才能使用zsh"
    echo "  2. 首次使用zsh时会有配置向导"
    echo "  3. 配置文件位置: $REAL_HOME/.zshrc"
    echo
    print_info "常用命令："
    echo "  - 使用 'bat' 代替 'cat' 查看文件"
    echo "  - 使用 'j <目录名>' 快速跳转目录"
    echo "  - 输入命令时会有自动建议（按右箭头接受）"
    echo
}

# 主函数
main() {
    echo
    print_info "=== ZSH一键配置脚本 ==="
    print_info "适用于Debian系统"
    echo
    
    # 检查系统
    check_root
    check_debian
    get_real_user
    
    # 安装依赖
    install_dependencies
    
    # 配置zsh
    check_current_shell
    install_zsh
    install_oh_my_zsh
    configure_zshrc
    install_zsh_plugins
    
    # 显示完成信息
    show_completion_info
    
    print_success "脚本执行完成！"
    print_info "请重新登录以使用zsh"
}

# 运行主函数
main "$@"
