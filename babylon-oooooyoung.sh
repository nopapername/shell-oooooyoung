Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"

CHAIN_ID="bbn-test-2"

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_go() {
    check_root
    sudo apt update && sudo apt upgrade --yes
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu unzip zip --yes
    ver="1.21.6"
    cd $HOME
    wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
    source $HOME/.bash_profile
}

install_babylon_env() {
    install_go
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

    cd $HOME
    source $HOME/.bash_profile
    rm -rf babylon
    git clone https://github.com/babylonchain/babylon.git
    cd babylon/
    APP_VERSION=$(curl -s \
    https://api.github.com/repos/babylonchain/babylon/releases/latest \
    | jq -r ".tag_name")
    git checkout tags/$APP_VERSION -b $APP_VERSION
    make install

    read -e -p "请输入你的节点名称: " node_name
    babylond init $node_name --chain-id $CHAIN_ID
    wget https://github.com/babylonchain/networks/raw/main/$CHAIN_ID/genesis.tar.bz2
    tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
    mv genesis.json $HOME/.babylond/config/genesis.json

    PEERS="8da45f9ff83b4f8dd45bbcb4f850999637fbfe3b@seed0.testnet.babylonchain.io:26656,4b1f8a774220ba1073a4e9f4881de218b8a49c99@seed1.testnet.babylonchain.io:26656,67d0c70c8ee2ce22638081f60fbf76ea5d3dd9af@genesis-validator4.testnet.babylonchain.io:26656,03ce5e1b5be3c9a81517d415f65378943996c864@18.207.168.204:26656,a5fabac19c732bf7d814cf22e7ffc23113dc9606@34.238.169.221:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656,b79270829412972d4561fddd7b0b19d0ff86e7cb@154.42.7.136:26656,ba3a508f05deb21729f9c4e4a4288ffc60ceb01e@154.42.7.38:26656,cc01114366a5520eb9883bfa0e070f0c7b6888dc@154.42.7.183:26656,ac52edf166ce9eb361fbfd3503233a8a2b7e777d@165.227.96.16:26656,4a13ce7ce1ceaa527310ffae4fa0b5e9e09d703d@154.42.7.198:26656,4a4f42f81fcf721e197aa0aef075914dcbdc4528@154.42.7.187:26656,0b926256faabb143a03e88a270fa5f618983c167@154.42.7.35:26656,66886aae0323cee9467a5b2bd6dec33899a7ef1c@154.42.7.36:26656,debea867ba3b70c384eb3e529f4e1ea018cf6d46@154.42.7.37:26656,3412554180ddb0f5ad92c3e33dbb12081ecb3b73@154.42.7.39:26656,c5d027f654739450e5845442dcf0ffb94b399938@154.42.7.80:26656,ea5ef5c5336e86d4376728aa4e0698546eac6b8f@154.42.7.145:26656,7ffaacf1ea89b2aa74a554851c96dcf178f243dd@154.42.7.113:26656"

    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.babylond/config/config.toml
    sed -i.bak -e "s/^seeds *=.*/seeds = \"$PEERS\"/" $HOME/.babylond/config/config.toml

    mkdir -p $HOME/.babylond/cosmovisor
    mkdir -p $HOME/.babylond/cosmovisor/genesis
    mkdir -p $HOME/.babylond/cosmovisor/genesis/bin
    mkdir -p $HOME/.babylond/cosmovisor/upgrades

    cp $HOME/go/bin/babylond $HOME/.babylond/cosmovisor/genesis/bin/babylond
    sudo tee /etc/systemd/system/babylond.service > /dev/null <<EOF
[Unit]
Description=Babylon daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --x-crisis-skip-assert-invariants
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_NAME=babylond"
Environment="DAEMON_HOME=${HOME}/.babylond"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n"
    echo -e "下面开始创建babylon钱包，会让你创建一个钱包密码..."
    babylond keys add wallet > $HOME/account.txt
    sed -i -e "s|^key-name *=.*|key-name = \"wallet\"|" $HOME/.babylond/config/app.toml
    sed -i -e "s|^timeout_commit *=.*|timeout_commit = \"10s\"|" $HOME/.babylond/config/config.toml
    echo -e "\n"
    echo -e "请保存上面创建好的钱包地址、私钥、助记词等信息..."
}

start_babylon_node() {
    source $HOME/.bash_profile
    sudo -S systemctl daemon-reload
    sudo -S systemctl enable babylond
    sudo -S systemctl start babylond
    journalctl -u babylond -f --no-hostname -o cat
}

check_node_status_and_height() {
    source $HOME/.bash_profile
    babylond status | jq .SyncInfo
    systemctl status babylond
}

start_validator_node() {
    source $HOME/.bash_profile
    read -e -p "请输入你的验证者名称: " validator_name
    babylond tx checkpointing create-validator \
        --amount=1000000ubbn \
        --pubkey=$(babylond tendermint show-validator) \
        --moniker=$validator_name \
        --chain-id=$CHAIN_ID \
        --gas="auto" \
        --gas-adjustment=1.2 \
        --gas-prices="0.0025ubbn" \
        --from="wallet" \
        --commission-rate="0.10" \
        --commission-max-rate="0.20" \
        --commission-max-change-rate="0.01" \
        --min-self-delegation="1"\
        -y
}

echo && echo -e " ${Red_font_prefix}babylon节点 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装babylon节点环境 ${Font_color_suffix}
 ${Green_font_prefix} 2.运行babylon节点 ${Font_color_suffix}
 ${Green_font_prefix} 3.检查节点同步高度及状态 ${Font_color_suffix}
 ${Green_font_prefix} 4.成为验证者（需要等节点同步到最新区块） ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程执行以上步骤，请输入数字 [1-3]:" num
case "$num" in
1)
    install_babylon_env
    ;;
2)
    start_babylon_node
    ;;
3)
    check_node_status_and_height
    ;;
4)
    start_validator_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
