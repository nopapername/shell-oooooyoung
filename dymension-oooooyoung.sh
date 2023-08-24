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

# doc: https://docs.dymension.xyz/validate/dymension-hub/build-dymd

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_go() {
    check_root
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu unzip zip -y
    ver="1.21.0"
    cd $HOME
    wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
    source $HOME/.bash_profile
}

install_dymension_env_and_generate_wallet() {
    check_root
    ufw allow 26656
    ufw allow 20556
    ufw allow 26657
    install_go
    rm -rf ~/dymension
    rm -rf ~/.dymension
    rm ~/account.txt
    git clone https://github.com/dymensionxyz/dymension.git --branch v1.0.2-beta
    cd ~/dymension
    make install
    dymd config chain-id froopyland_100-1
    dymd config keyring-backend test
    read -e -p "请输入你的节点名称: " MONIKER_NAME
    read -e -p "请输入你的钱包名称以生成钱包: " WALLET_NAME
    dymd init $MONIKER_NAME --chain-id froopyland_100-1
    sed -i 's/minimum-gas-prices = "0udym"/minimum-gas-prices = "0.25udym"/' ~/.dymension/config/app.toml
    sed -i -e 's/external_address = \"\"/external_address = \"'$(curl httpbin.org/ip | jq -r .origin)':26656\"/g' ~/.dymension/config/config.toml
    sed -i 's/seed_mode = false/seed_mode = true/' ~/.dymension/config/config.toml
    sed -i 's/seeds = \"\"/seeds = \"284313184f63d9f06b218a67a0e2de126b64258d@seeds.silknodes.io:26157\"/' ~/.dymension/config/config.toml
    sed -i 's/persistent_peers = \"\"/persistent_peers = \"e7857b8ed09bd0101af72e30425555efa8f4a242@148.251.177.108:20556,cb120ed9625771d57e06f8d449cb10ab99a58225@57.128.114.155:26656\"/' ~/.dymension/config/config.toml

    dymd tendermint unsafe-reset-all --home $HOME/.dymension --keep-addr-book
    curl -L https://snapshots.kjnodes.com/dymension-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.dymension

    # download genesis and addrbook
    wget -O $HOME/.dymension/config/genesis.json "https://raw.githubusercontent.com/dymensionxyz/testnets/main/dymension-hub/froopyland/genesis.json"
    wget -O $HOME/.dymension/config/addrbook.json "https://share101.utsa.tech/dymension/addrbook.json"
    echo "moniker: $MONIKER_NAME" >> ~/account.txt
    dymd keys add $WALLET_NAME >> ~/account.txt
    WALLET_ADDRESS=$(grep -oP '(?<=address: ).*' ~/account.txt)
    WALLET_NAME=$(grep -oP '(?<=name: ).*' ~/account.txt)
    dymd add-genesis-account $WALLET_ADDRESS 600000000000udym
    dymd gentx $WALLET_NAME 500000000000udym --chain-id=froopyland_100-1
    dymd collect-gentxs
    echo -e "\n"
    echo -e "\n"
    cat ~/account.txt
    echo -e "\n请保存好上面的钱包账号信息..."
}

start_dymension_full_node() {
    cd ~/dymension
    source $HOME/.bash_profile
    dymd start
}

start_dymension_validator_node() {
    cd ~/dymension
    source $HOME/.bash_profile

    MONIKER_NAME=$(grep -oP '(?<=moniker: ).*' ~/account.txt)
    WALLET_ADDRESS=$(grep -oP '(?<=address: ).*' ~/account.txt)
    WALLET_NAME=$(grep -oP '(?<=name: ).*' ~/account.txt)
    dymd tx staking create-validator \
    --amount=1000000udym \
    --pubkey=$(dymd tendermint show-validator) \
    --moniker="$MONIKER_NAME" \
    --chain-id=froopyland_100-1 \
    --from=$WALLET_NAME \
    --commission-rate="0.10" \
    --commission-max-rate="0.20" \
    --commission-max-change-rate="0.01" \
    --min-self-delegation="1" \
    -y
}

echo && echo -e " ${Red_font_prefix}Dymension节点 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装Dymension节点环境并生成钱包私钥导出 ${Font_color_suffix}
 ${Green_font_prefix} 2.运行Dymension全节点 ${Font_color_suffix}
 ${Green_font_prefix} 3.运行Dymension验证者节点 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程执行以上步骤，请输入数字 [1-3]:" num
case "$num" in
1)
    install_dymension_env_and_generate_wallet
    ;;
2)
    start_dymension_full_node
    ;;
3)
    start_dymension_validator_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
