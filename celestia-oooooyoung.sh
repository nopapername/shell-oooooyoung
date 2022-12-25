Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"

LIGHT_RPC_ADDRESS="https://limani.celestia-devops.dev"
FULL_RPC_ADDRESS="https://rpc-1.celestia.nodes.guru"

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_celestia_node() {
    check_root
    ufw allow 9090
    ufw allow 26659
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu -y
    ver="1.19.1"
    cd $HOME
    wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
    source $HOME/.bash_profile

    cd $HOME
    rm -rf celestia-app
    git clone https://github.com/celestiaorg/celestia-app.git
    cd celestia-app/
    APP_VERSION=$(curl -s \
    https://api.github.com/repos/celestiaorg/celestia-app/releases/latest \
    | jq -r ".tag_name")
    git checkout tags/$APP_VERSION -b $APP_VERSION
    make install
    
    cd $HOME
    rm -rf celestia-node
    git clone https://github.com/celestiaorg/celestia-node.git
    NODE_VERSION=$(curl -s \
    https://api.github.com/repos/celestiaorg/celestia-node/releases/latest \
    | jq -r ".tag_name")
    cd celestia-node/
    git checkout tags/$NODE_VERSION -b $NODE_VERSION
    make install
    make cel-key
}

create_wallet_run_light_node() {
    cd ~
    celestia light init --p2p.network arabica
    echo -e "\n"
    read -e -p "请输入钱包名称创建你的轻节点钱包: " WALLET_NAME
    celestia-node/cel-key add $WALLET_NAME --keyring-backend test --node.type light
    echo -e "\n"
    read -e -p "请保存上面创建好的轻节点钱包地址、私钥、助记词，然后按回车键继续..."
    celestia light start --keyring.accname $WALLET_NAME --core.ip $LIGHT_RPC_ADDRESS --core.grpc.port 9090 --gateway --gateway.addr 0.0.0.0 --gateway.port 26659 --p2p.network arabica
}

create_wallet_run_full_node() {
    cd ~
    celestia full init --p2p.network arabica
    echo -e "\n"
    read -e -p "请输入钱包名称创建你的全存储节点钱包: " WALLET_NAME
    celestia-node/cel-key add $WALLET_NAME --keyring-backend test --node.type full
    echo -e "\n"
    read -e -p "请保存上面创建好的全存储节点钱包地址、私钥、助记词，然后按回车键继续..."
    celestia full start --core.ip $FULL_RPC_ADDRESS --core.grpc.port 9090 --keyring.accname $WALLET_NAME --p2p.network arabica
}

run_light_node() {
    cd ~
    celestia light init --p2p.network arabica
    echo -e "\n"
    read -e -p "请输入你的轻节点钱包名称: " WALLET_NAME
    celestia light start --keyring.accname $WALLET_NAME --core.ip $LIGHT_RPC_ADDRESS --core.grpc.port 9090 --gateway --gateway.addr 0.0.0.0 --gateway.port 26659 --p2p.network arabica
}

run_full_node() {
    cd ~
    celestia full init --p2p.network arabica
    echo -e "\n"
    read -e -p "请输入你的全存储节点钱包名称: " WALLET_NAME
    celestia full start --core.ip $FULL_RPC_ADDRESS --core.grpc.port 9090 --keyring.accname $WALLET_NAME --p2p.network arabica
}

wallet_recover_account() {
    read -e -p "请输入你的celestia节点钱包名称: " WALLET_NAME
    source $HOME/.bash_profile
    cd ~/celestia-app/
    celestia-appd config keyring-backend test
    celestia-appd keys add $WALLET_NAME --recover
}

wallet_staking() {
    read -e -p "请输入你的celestia节点钱包名称: " WALLET_NAME
    read -e -p "请输入质押数量: " STAKING_COUNT
    STAKING_COUNT_UTIA="${STAKING_COUNT}000000utia"
    source $HOME/.bash_profile
    cd ~/celestia-app/
    celestia-appd tx staking delegate \
    celestiavaloper1q3v5cugc8cdpud87u4zwy0a74uxkk6u4q4gx4p $STAKING_COUNT_UTIA \
    --from=$WALLET_NAME --chain-id=mamaki --node https://rpc-mamaki.pops.one:443
}

echo && echo -e " ${Red_font_prefix}dusk_network 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装依赖环境和工具包 ${Font_color_suffix}
 ${Green_font_prefix} 2.创建轻节点钱包并运行轻节点 ${Font_color_suffix}
 ${Green_font_prefix} 3.创建全存储节点钱包并运行全存储节点 ${Font_color_suffix}
 ${Green_font_prefix} 4.重新运行轻节点 ${Font_color_suffix}
 ${Green_font_prefix} 5.重新运行全存储节点 ${Font_color_suffix}
 ${Green_font_prefix} 6.导入之前创建的celestia钱包 ${Font_color_suffix}
 ${Green_font_prefix} 7.质押测试代币 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照上面的步骤，请输入数字 [1-7]:" num
case "$num" in
1)
    install_celestia_node
    ;;
2)
    create_wallet_run_light_node
    ;;
3)
    create_wallet_run_full_node
    ;;
4)
    run_light_node
    ;;
5)
    run_full_node
    ;;
6)
    wallet_recover_account
    ;;
7)
    wallet_staking
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
