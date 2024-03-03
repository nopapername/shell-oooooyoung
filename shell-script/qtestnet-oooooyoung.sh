Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"

PRI_KEYWORDS="123456"

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_q_validator_node_and_export_key() {
    check_root
    ufw allow 30313
    sudo apt install -y curl git wget lrzsz docker docker-compose
    git clone https://gitlab.com/q-dev/testnet-public-tools --depth 1
    cd /root/testnet-public-tools/testnet-validator
    sudo mkdir -p /root/testnet-public-tools/testnet-validator/keystore/
    echo "$PRI_KEYWORDS" > /root/testnet-public-tools/testnet-validator/keystore/pwd.txt
    docker-compose run --rm --entrypoint "geth account new --datadir=/data --password=/data/keystore/pwd.txt" testnet-validator-node > /root/testnet-public-tools/testnet-validator/q_address.txt
    cat /root/testnet-public-tools/testnet-validator/q_address.txt
    sz /root/testnet-public-tools/testnet-validator/keystore/UTC--*
}

config_and_run_q_validator_node() {
    read -e -p "请输入你的服务器公共地址ip：" IP_ADDRESS
    read -e -p "请输入你的验证者名称：" VALIDATOR_NAME
    cd /root/testnet-public-tools/testnet-validator
    QADDRESS=$(cat /root/testnet-public-tools/testnet-validator/q_address.txt | grep 'Public address of the key:' | awk '{print $6}')
    QADDRESSWITHOUT0x=${QADDRESS:2}
    sed -i "s/0000000000000000000000000000000000000000/$QADDRESSWITHOUT0x/g" /root/testnet-public-tools/testnet-validator/.env
    sed -i "s/192.0.0.0/$IP_ADDRESS/g" /root/testnet-public-tools/testnet-validator/.env
    sed -i "s/0000000000000000000000000000000000000000/$QADDRESSWITHOUT0x/g" /root/testnet-public-tools/testnet-validator/config.json
    sed -i "s/supersecurepassword/$PRI_KEYWORDS/g" /root/testnet-public-tools/testnet-validator/config.json
    sed -i "s/\"geth\",/\"geth\", \"--ethstats=$VALIDATOR_NAME:qstats-testnet@stats.qtestnet.org\",/g" /root/testnet-public-tools/testnet-validator/docker-compose.yaml
    docker-compose up -d
    docker-compose logs -f --tail "100"
}

restart_q_validator_node() {
    cd /root/testnet-public-tools/testnet-validator
    docker-compose down
    docker-compose up -d
    docker-compose logs -f --tail "100"
}

echo && echo -e " ${Red_font_prefix}q_blockchain 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装q验证节点环境并生成钱包私钥导出 ${Font_color_suffix}
 ${Green_font_prefix} 2.配置文件并运行q验证者节点 ${Font_color_suffix}
 ${Green_font_prefix} 3.重启q验证者节点 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程执行以上步骤，请输入数字 [1-3]:" num
case "$num" in
1)
    install_q_validator_node_and_export_key
    ;;
2)
    config_and_run_q_validator_node
    ;;
3)
    restart_q_validator_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
