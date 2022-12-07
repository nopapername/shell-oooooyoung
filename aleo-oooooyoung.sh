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
AleoPoolFile="/root/aleo-pool-prover"

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限),无法继续操作,请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_aleo() {
    check_root
    apt install git
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    git clone https://github.com/AleoHQ/snarkOS.git --depth 1 /root/snarkOS
    cd /root/snarkOS
    /root/snarkOS/build_ubuntu.sh
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

read_aleo_address() {
    cat /root/aleo.txt
}


install_aleo_pool_cpu_and_run() {
    check_root
    if [ -f ${AleoPoolFile} ]; then
        echo " "
    else
        apt install wget
        cd ~ && wget -O /root/aleo-pool-prover https://nd-valid-data-bintest1.oss-cn-hangzhou.aliyuncs.com/aleo/aleo-pool-prover_ubuntu_2004_cpu && chmod +x aleo-pool-prover
        ufw allow 30009
    fi

    echo -e "\n"
    read -e -p "请输入你的aleo pool矿池帐号名称: " ALEO_POOL_NAME
    read -e -p "请输入你的设备名称（可随便取，便于区分多台设备）: " ALEO_POOL_SERVER_NAME
    /root/aleo-pool-prover --account_name $ALEO_POOL_NAME --miner_name $ALEO_POOL_SERVER_NAME
}

install_aleo_pool_gpu() {
    check_root
    sudo apt update
    sudo apt-get remove --purge nvidia*
    sudo apt-get install wget make gcc-7 g++-7 ubuntu-drivers-common -y
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 9
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 1
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 9
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 1
    sudo update-alternatives --display g++

    sudo ubuntu-drivers autoinstall

    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    sudo apt-get update
    sudo apt-get -y install cuda

    echo "export PATH=/usr/local/cuda-11.8/bin\${PATH:+:\${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ~/.bashrc
    source ~/.bashrc

    cd ~ && wget -O /root/aleo-pool-prover-gpu https://nd-valid-data-bintest1.oss-cn-hangzhou.aliyuncs.com/aleo/aleo-pool-prover_ubuntu_2004_gpu && chmod +x aleo-pool-prover-gpu

    sudo reboot
}

run_aleo_pool_gpu() {
    read -e -p "请输入你的aleo pool矿池帐号名称: " ALEO_POOL_NAME
    read -e -p "请输入你的设备名称（可随便取，便于区分多台设备）: " ALEO_POOL_SERVER_NAME
    /root/aleo-pool-prover-gpu --account_name $ALEO_POOL_NAME --miner_name $ALEO_POOL_SERVER_NAME
}


echo && echo -e " ${Red_font_prefix}aleo testnet3二阶段pover节点激励测试 一键运行
此脚本完全免费开源, 由推特用户${Green_font_prefix}@ouyoung11修改${Font_color_suffix},脚本${Font_color_suffix} fork by \033[1;35m@Daniel\033[0m
欢迎关注,如有收费请勿上当受骗.
 ———————————————————————
 ${Green_font_prefix} 1.安装或更新 aleo 环境包${Font_color_suffix}
 ${Green_font_prefix} 2.运行 aleo_client ${Font_color_suffix}
 ${Green_font_prefix} 3.运行 aleo_prover ${Font_color_suffix}
 ${Green_font_prefix} 4.读取 aleo 地址私钥 ${Font_color_suffix}
 --------------(以下为aleo矿池CPU版本，请勿和上面3步混用)----------------
 ${Green_font_prefix} 5.安装aleo pool的CPU版本 ${Font_color_suffix}
 --------------(以下为aleo矿池GPU版本，请勿和上面混用)----------------
 ${Green_font_prefix} 6.安装aleo pool的GPU版本并重启系统应用(如果系统已有显卡驱动和cuda，请不要执行此步) ${Font_color_suffix}
 ${Green_font_prefix} 7.启动aleo pool的GPU挖矿（如若启动出错请手动安装对应显卡驱动版本及cuda） ${Font_color_suffix}

 ———————————————————————" && echo
read -e -p " 请输入数字 [1-7]:" num
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
    read_aleo_address
    ;;
5)
    install_aleo_pool_cpu_and_run
    ;;
6)
    install_aleo_pool_gpu
    ;;
7)
    run_aleo_pool_gpu
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
