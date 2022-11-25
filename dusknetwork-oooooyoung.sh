Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_dusk_wallet_and_run() {
    check_root
    sudo apt install wget
    sudo apt install curl
    sudo apt install lrzsz
    mkdir /root/wallet
    cd ~ && wget -O /root/wallet/ruskwallet0.12.0-linux-x64.tar.gz https://github.com/dusk-network/wallet-cli/releases/download/v0.12.0/ruskwallet0.12.0-linux-x64.tar.gz && chmod +x ruskwallet0.12.0-linux-x64.tar.gz
    tar -xv -f /root/wallet/ruskwallet0.12.0-linux-x64.tar.gz -C /root/wallet/
    cd wallet/rusk-wallet0.12.0-linux-x64
    wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb && sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
    ./rusk-wallet
}

get_wallet_key_in_windows() {
    cd ~
    read -e -p "请输入你刚刚生成的dusk钱包地址adress: " DUSK_ADDRESS
    mv .dusk/rusk-wallet/$DUSK_ADDRESS.key .dusk/rusk-wallet/consensus.keys
    sz .dusk/rusk-wallet/$DUSK_ADDRESS.cpk
}

get_and_start_dusk_node() {
    curl --proto '=https' --tlsv1.2 -sSf https://dusk-infra.ams3.digitaloceanspaces.com/rusk/itn-installer.sh | sh
    mv -f .dusk/rusk-wallet/consensus.keys /opt/dusk/conf/
    echo 'DUSK_CONSENSUS_KEYS_PASS=' > /opt/dusk/services/dusk.conf
    service rusk start
    service dusk start
    tail -f /var/log/dusk.log
}

start_rusk_wallet() {
    wallet/rusk-wallet0.12.0-linux-x64/rusk-wallet
}

restart_dusk_node() {
    service rusk restart
    service dusk restart
    tail -f /var/log/dusk.log
}

echo && echo -e " ${Red_font_prefix}dusk_network 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装 dusk 钱包并运行 ${Font_color_suffix}
 ${Green_font_prefix} 2.保存dusk验证者节点公钥cpk文件到windows ${Font_color_suffix}
 ${Green_font_prefix} 3.获取并启动dusk节点 ${Font_color_suffix}
 ${Green_font_prefix} 4.运行dusk钱包(钱包内可进行质押..等操作) ${Font_color_suffix}
 ${Green_font_prefix} 5.重启dusk节点(服务出错或停止时才选择此步，正常搭建请忽略此项) ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程依次执行以上五个步骤，请输入数字 [1-5]:" num
case "$num" in
1)
    install_dusk_wallet_and_run
    ;;
2)
    get_wallet_key_in_windows
    ;;
3)
    get_and_start_dusk_node
    ;;
4)
    start_rusk_wallet
    ;;
5)
    restart_dusk_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
