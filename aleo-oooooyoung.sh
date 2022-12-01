Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
AleoFile="/root/aleo.txt"
check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限),无法继续操作,请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_aleo() {
    check_root
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    git clone https://github.com/AleoHQ/snarkOS.git --depth 1 /root/snarkOS
    cd /root/snarkOS
    bash /root/snarkOS/build_ubuntu.sh
    cargo install --path /root/snarkOS
    if [ -f ${AleoFile} ]; then
        echo "address exist"
    else
        snarkos account new >/root/aleo.txt
    fi
    cat /root/aleo.txt
    PrivateKey=$(cat /root/aleo.txt | grep Private | awk '{print $3}')
    echo export PROVER_PRIVATE_KEY=$PrivateKey >>/etc/profile
    source /etc/profile
}

run_aleo_client() {
    source $HOME/.cargo/env
    source /etc/profile
    cd /root/snarkOS
    nohup ./run-client.sh >run-client.log 2>&1 &
    tail -f /root/snarkOS/run-client.log
}

run_aleo_prover() {
    source $HOME/.cargo/env
    source /etc/profile
    cd /root/snarkOS
    nohup ./run-prover.sh >run-prover.log 2>&1 &
    tail -f /root/snarkOS/run-prover.log
}

run_beacon() {
    cargo run --release -- start --nodisplay --dev 0 --beacon ""
}

read_aleo_address() {
    cat /root/aleo.txt
}

echo && echo -e " ${Red_font_prefix}aleo testnet3二阶段pover节点激励测试 一键运行
此脚本完全免费开源, 由推特用户${Green_font_prefix}@ouyoung11修改${Font_color_suffix},脚本${Font_color_suffix} fork by \033[1;35m@Daniel\033[0m
欢迎关注,如有收费请勿上当受骗.
 ———————————————————————
 ${Green_font_prefix} 1.安装或更新 aleo 环境包${Font_color_suffix}
 ${Green_font_prefix} 2.运行 aleo_client ${Font_color_suffix}
 ${Green_font_prefix} 3.运行 aleo_prover ${Font_color_suffix}
 ${Green_font_prefix} 4.运行信标 beacon ${Font_color_suffix}
 ${Green_font_prefix} 5.读取 aleo 地址私钥 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请输入数字 [1-4]:" num
case "$num" in
1)
    install_aleo
    ;;
2)
    run_aleo_client
    ;;
3)
    run_aleo_prover
    ;;
4)
    run_beacon
    ;;
5)
    read_aleo_address
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
