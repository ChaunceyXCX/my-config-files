# 定义变量
GITHUB_URL="https://raw.githubusercontent.com/ChaunceyXCX/my-config-files/master/zsh/.zshrc"
TARGET_FILE="~/.zshrc"
TEMP_FILE="temp_zshrc"

# 检查当前 shell 是否为 zsh
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    echo "当前 shell 是 zsh，脚本退出"
#    exit 0
fi

# 继续执行其他操作
echo "当前 shell 不是 zsh，继续执行脚本"

# 检查是否安装了 zsh
if command -v zsh >/dev/null 2>&1; then
    echo "已安装 zsh"
else
    echo "未安装 zsh，开始安装"
    apt-get update && apt-get install -y zsh
fi

# 继续执行其他操作
echo "继续执行脚本..."


chsh -s /bin/zsh
echo "已设置 zsh 为默认 shell"
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
echo "已安装 oh-my-zsh"


# 下载文件
curl -o $TEMP_FILE $GITHUB_URL

# 检查下载是否成功
if [ $? -ne 0 ]; then
    echo "zshrc配置文件下载失败"
    exit 1
fi

# 插入文件内容到目标文件
cat $TEMP_FILE >> $TARGET_FILE

# 删除临时文件
rm $TEMP_FILE

echo "文件内容已插入到 $TARGET_FILE 中"

#自动推荐
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
echo "已安装 zsh-autosuggestions || 自动推荐"

#高亮
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
echo "已安装 zsh-syntax-highlighting"

#高亮版cat
apt-get install -y bat
echo "已安装 bat || 高亮版cat"

#自动补全
wget http://mimosa-pudica.net/src/incr-0.2.zsh && mkdir ~/.oh-my-zsh/plugins/incr/ && mv ./incr-0.2.zsh ~/.oh-my-zsh/plugins/incr/
echo "已安装 incr-0.2.zsh || 自动补全"
#autjump
apt-get install -y autojump
echo "已安装 autojump"

source ~/.zshrc


