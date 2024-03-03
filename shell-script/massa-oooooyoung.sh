Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
NODE_WALLET_PASSWORD="123456"


check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_massa_node_and_start() {
    check_root
    sudo apt install screen pkg-config curl git build-essential libssl-dev libclang-dev -y
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup toolchain install nightly-2022-11-14
    rustup default nightly-2022-11-14
    git clone --branch testnet https://github.com/massalabs/massa.git --depth 1 /root/massa
    ufw allow 33034
    ufw allow 33035
    ufw allow 31244
    ufw allow 31245

    read -e -p "请输入你的服务器公网ip地址: " IP_ADDRESS
    echo "[network]
routable_ip = \"$IP_ADDRESS\"" >/root/massa/massa-node/config/config.toml

    sudo apt update && sudo apt upgrade -y
    cd /root/massa/massa-node/
    RUST_BACKTRACE=full cargo run --release -- -p $NODE_WALLET_PASSWORD |& tee logs.txt
}

start_massa_wallet_client() {
    cd /root/massa/massa-client/
    cargo run --release -- -p $NODE_WALLET_PASSWORD
}

restart_massa_node() {
    cd /root/massa/massa-node/
    cargo run --release -- -p $NODE_WALLET_PASSWORD |& tee logs.txt
}

echo && echo -e " ${Red_font_prefix}massa 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装massa环境并运行节点 ${Font_color_suffix}
 ${Green_font_prefix} 2.运行massa客户端 ${Font_color_suffix}
 ${Green_font_prefix} 3.重新运行massa节点（请在节点运行有问题时再执行此步） ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程执行以上三个步骤，请输入数字 [1-3]:" num
case "$num" in
1)
    install_massa_node_and_start
    ;;
2)
    start_massa_wallet_client
    ;;
3)
    restart_massa_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
