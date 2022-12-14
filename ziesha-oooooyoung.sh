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

install_ziesha_bazuka_and_run() {
    check_root
    sudo apt-get update && sudo apt-get upgrade
    sudo apt install -y build-essential libssl-dev cmake curl git cargo
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    git clone https://github.com/ziesha-network/bazuka
    source "$HOME/.cargo/env"
    cd bazuka
    cargo install --path .
    bazuka init --network groth-6 --bootstrap 65.108.193.133:8765
    echo -e "\n"
    read -e -p "请保存上面创建好的钱包助记词私钥，然后输入你的discord帐号：" DISCORD_ACCOUNT
    bazuka node start --discord-handle "$DISCORD_ACCOUNT"
}

update_ziesha_bazuka_and_run() {
    rm -rf ~/.bazuka
    cd ~
    cd bazuka
    git pull origin master
    cargo update
    cargo install --path .
    read -e -p "请输入你的discord帐号：" DISCORD_ACCOUNT
    bazuka node start --discord-handle "$DISCORD_ACCOUNT"
}

echo && echo -e " ${Red_font_prefix}ziesha_network 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装Ziesha节点且生成钱包并运行 ${Font_color_suffix}
 ${Green_font_prefix} 2.更新Ziesha节点版本并重新运行 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程执行以上步骤，请输入数字 [1-2]:" num
case "$num" in
1)
    install_ziesha_bazuka_and_run
    ;;
2)
    update_ziesha_bazuka_and_run
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
