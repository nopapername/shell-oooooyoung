Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
disk_info=$(df -h | grep -E '^/dev/' | sort -k4 -h -r)
max_disk=$(echo "$disk_info" | head -n 1 | awk '{print $1}')
max_disk_path=$(echo "$disk_info" | head -n 1 | awk '{print $6}')
cd "$max_disk_path" || exit

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_btc_full_node() {
    check_root
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu unzip zip -y
    sudo ufw allow 8333

    echo "最大磁盘路径为: $max_disk_path"

    latest_version_info=$(curl -s https://api.github.com/repos/bitcoin/bitcoin/releases/latest | grep "tag_name" | cut -d'"' -f4)
    latest_version=${latest_version_info#v}
    download_link="https://bitcoincore.org/bin/bitcoin-core-$latest_version/bitcoin-$latest_version-x86_64-linux-gnu.tar.gz"
    bitcoin_coin_path="$max_disk_path/bitcoin-core.tar.gz"
    
    wget -O $bitcoin_coin_path $download_link && \
    tar -xvf $bitcoin_coin_path && \
    bitcoin_directory=$(tar -tf $bitcoin_coin_path | head -n 1 | cut -f1 -d'/') && \
    mv "$bitcoin_directory" bitcoin-core && \
    chmod +x bitcoin-core

    echo "# Bitcoin environment variables" >> ~/.bashrc
    echo "export BTCPATH=$max_disk_path/bitcoin-core/bin" >> ~/.bashrc
    echo 'export PATH=$BTCPATH:$PATH' >> ~/.bashrc

    mkdir $max_disk_path/btc-data

    conf_file="$max_disk_path/btc-data/bitcoin.conf"
    conf_content=$(cat <<EOL
server=1
daemon=1
txindex=1
rpcuser=mybtc
rpcpassword=mybtc123
addnode=101.43.124.195:8333
addnode=27.152.157.149:8333
addnode=101.43.95.152:8333
addnode=222.186.20.60:8333
addnode=175.27.247.104:8333
addnode=110.40.210.253:8333
addnode=202.108.211.135:8333
addnode=180.108.105.174:8333
EOL
)
    # 检查配置文件是否已存在，如果不存在则创建
    if [ ! -f "$conf_file" ]; then
        echo "$conf_content" > "$conf_file"
        echo "bitcoin.conf created at $conf_file"
    else
        echo "bitcoin.conf already exists at $conf_file"
    fi

    source ~/.bashrc
}

run_btc_full_node() {
    source ~/.bashrc
    bitcoin-cli -datadir=$max_disk_path/btc-data stop > /dev/null 2>&1
    bitcoind -datadir=$max_disk_path/btc-data -txindex
}

check_btc_full_node_block_height() {
    source ~/.bashrc
    bitcoin-cli -rpcuser=mybtc -rpcpassword=mybtc123 getblockchaininfo
}

check_btc_full_node_log() {
    source ~/.bashrc
    tail -f $max_disk_path/btc-data/debug.log
}

echo && echo -e " ${Red_font_prefix}dusk_network 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装Btc全节点环境 ${Font_color_suffix}
 ${Green_font_prefix} 2.运行Btc全节点 ${Font_color_suffix}
 ${Green_font_prefix} 3.查看Btc全节点同步的区块高度 ${Font_color_suffix}
 ${Green_font_prefix} 4.查看Btc全节点日志 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照上面的步骤，请输入数字:" num
case "$num" in
1)
    install_btc_full_node
    ;;
2)
    run_btc_full_node
    ;;
3)
    check_btc_full_node_block_height
    ;;
4)
    check_btc_full_node_log
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac

