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

install_damominer_env() {
    check_root
    sudo apt install -y wget
    wget -P /root/damominer_folder https://github.com/damomine/aleominer/releases/download/v2.3.1/damominer_linux_v2.3.1.tar
    tar -xvf /root/damominer_folder/damominer_linux_v2.3.1.tar -C /root/damominer_folder/
    chmod +x /root/damominer_folder/damominer
    chmod +x /root/damominer_folder/run_gpu.sh
}

run_damominer() {
    read -e -p "请输入你的aleo address: " ALEO_ADDRESS
    if ps aux | grep 'damominer' | grep -q 'proxy'; then
        echo "DamoMiner already running."
        exit 1
    else
        nohup /root/damominer_folder/damominer --address $ALEO_ADDRESS --proxy aleo2.damominer.hk:9090 >> aleo.log 2>&1 &
    fi
}

schedule_run_prover_for_address() {
    read -e -p "请设定每几小时跑一个地址：" TIME_DURATION
    current_line=1
    address_line=`wc -l /root/aleo_address.txt | awk '{print $1}'`
    while ((current_line <= address_line))
    do
        current_address=`head -${current_line} /root/aleo_address.txt | tail -n 1`
        if ps aux | grep 'damominer'; then
            killall damominer
        fi
        nohup /root/damominer_folder/damominer --address ${current_address} --proxy asiahk.damominer.hk:9090 >> aleo.log 2>&1 &
        echo "当前正在执行aleo_address.txt里第${current_line}行：${current_address}"
        sleep ${TIME_DURATION}h
        ((current_line += 1))
    done
    echo "地址全部执行结束..."
}

echo && echo -e "脚本由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装damominer工具包 ${Font_color_suffix}
 ${Green_font_prefix} 2.运行damominer gpu挖矿程序 ${Font_color_suffix}
 ${Green_font_prefix} 3.定时执行gpu挖矿（请确保aleo_address.txt存在于/root目录下，且文件内容里每个地址需换行） ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请输入数字 [1-3]:" num
case "$num" in
1)
    install_damominer_env
    ;;
2)
    run_damominer
    ;;
3)
    schedule_run_prover_for_address
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
