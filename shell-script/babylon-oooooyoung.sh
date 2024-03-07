Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"

CHAIN_ID="bbn-test-3"

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_go() {
    check_root
    # Install dependencies for building from source
    sudo apt update
    sudo apt install -y curl git jq lz4 build-essential

    # Install Go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    source .bash_profile
}

install_babylon_env() {
    read -e -p "请输入你的节点名称: " node_name
    sudo ufw allow 9100
    sudo ufw allow 26656
    install_go

    # Clone project repository
    cd && rm -rf babylon
    git clone https://github.com/babylonchain/babylon
    cd babylon
    git checkout v0.8.4

    # Build binary
    make install

    # Set node CLI configuration
    babylond config set client chain-id bbn-test-3
    babylond config set client keyring-backend test
    babylond config set client node tcp://localhost:20657

    # Initialize the node
    babylond init $node_name --chain-id $CHAIN_ID

    # Download genesis and addrbook files
    curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/genesis.json > $HOME/.babylond/config/genesis.json
    curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

    # Set seeds
    sed -i -e 's|^seeds *=.*|seeds = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,d66d4275cc6592ee3f51bf940f9d4a7b79431c0f@185.215.167.27:26656,04a7f5517d24383a36ce2b51a43a0d4f482fef29@84.247.189.41:26656,b00808ac8951f831d057a9e2bf04227e3fdf7464@37.60.237.230:26656,e810a17b116de8a288ec32ad60f261254be8cdeb@31.220.82.89:26656,f32fb74f8c0e12d478449ef3de04981a95581519@84.247.186.148:26656,f0d7cbf3d77f0eae2d3f83db8371e6ceda70a39f@89.117.55.59:26656,d509c94b73559d846ff89b638a7e42e7a25193b5@37.60.252.50:26656,98f285fca723700622b3918ddac0f627c7e63d76@161.97.94.87:26656,360c627efaa3e5dac16f6ba3d43fff7f0ec5c266@176.57.188.179:26656,4b456bbafe3ff6a28f6e7d0edb20668683c966cd@38.242.222.32:26656,fe923e35845fd14d4415b6fd2f073c52d0880a05@109.199.116.232:26656,66af16cf6b888ef0c631cc293d26f3cb06a04b4a@194.163.177.76:26656,063a8473f2327e9c39bb50196e11f969f02a1a71@82.208.20.172:26656,8c78c9a2acfc9e36459565f1d6c9ce35f87f3911@156.225.129.62:26656,136f4877771a86c7072b53ec86d0afddcdc1502b@84.247.172.135:26656,bcdda9e5c162d307e8126668f9e1edffacb8b9c0@85.239.235.144:26656,a3b57c4a5f06ae5876abf8d4294de4a320fb5e0f@194.163.166.144:26656,ac63a0965ab674db6d7b2bdc1d488a88fa5ad3da@93.185.166.236:26656,cc28a8a19d0cd8ea03e20c5313796c702bd815c4@62.171.176.205:26656,29c5f973b66c6f2c3cd9bd8335f92afd5ed7aeec@109.199.117.124:26656"|' $HOME/.babylond/config/config.toml
    PEERS="49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,d66d4275cc6592ee3f51bf940f9d4a7b79431c0f@185.215.167.27:26656,04a7f5517d24383a36ce2b51a43a0d4f482fef29@84.247.189.41:26656,b00808ac8951f831d057a9e2bf04227e3fdf7464@37.60.237.230:26656,e810a17b116de8a288ec32ad60f261254be8cdeb@31.220.82.89:26656,f32fb74f8c0e12d478449ef3de04981a95581519@84.247.186.148:26656,f0d7cbf3d77f0eae2d3f83db8371e6ceda70a39f@89.117.55.59:26656,d509c94b73559d846ff89b638a7e42e7a25193b5@37.60.252.50:26656,98f285fca723700622b3918ddac0f627c7e63d76@161.97.94.87:26656,360c627efaa3e5dac16f6ba3d43fff7f0ec5c266@176.57.188.179:26656,4b456bbafe3ff6a28f6e7d0edb20668683c966cd@38.242.222.32:26656,fe923e35845fd14d4415b6fd2f073c52d0880a05@109.199.116.232:26656,66af16cf6b888ef0c631cc293d26f3cb06a04b4a@194.163.177.76:26656,063a8473f2327e9c39bb50196e11f969f02a1a71@82.208.20.172:26656,8c78c9a2acfc9e36459565f1d6c9ce35f87f3911@156.225.129.62:26656,136f4877771a86c7072b53ec86d0afddcdc1502b@84.247.172.135:26656,bcdda9e5c162d307e8126668f9e1edffacb8b9c0@85.239.235.144:26656,a3b57c4a5f06ae5876abf8d4294de4a320fb5e0f@194.163.166.144:26656,ac63a0965ab674db6d7b2bdc1d488a88fa5ad3da@93.185.166.236:26656,cc28a8a19d0cd8ea03e20c5313796c702bd815c4@62.171.176.205:26656,29c5f973b66c6f2c3cd9bd8335f92afd5ed7aeec@109.199.117.124:26656"
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml

    # Set minimum gas price
    sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.00001ubbn"|' $HOME/.babylond/config/app.toml

    # Set pruning
    sed -i \
    -e 's|^pruning *=.*|pruning = "custom"|' \
    -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
    -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
    $HOME/.babylond/config/app.toml

    # Set additional configs
    sed -i 's|^network *=.*|network = "signet"|g' $HOME/.babylond/config/app.toml

    # Change ports
    sed -i -e "s%:1317%:20617%; s%:8080%:20680%; s%:9090%:20690%; s%:9091%:20691%; s%:8545%:20645%; s%:8546%:20646%; s%:6065%:20665%" $HOME/.babylond/config/app.toml
    sed -i -e "s%:26658%:20658%; s%:26657%:20657%; s%:6060%:20660%; s%:26656%:20656%; s%:26660%:20661%" $HOME/.babylond/config/config.toml

    # Download latest chain data snapshot
    curl "https://snapshots-testnet.nodejumper.io/babylon-testnet/babylon-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.babylond"

    # Create a service
    # Create a service
    sudo tee /etc/systemd/system/babylond.service > /dev/null << EOF
[Unit]
Description=Babylon node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which babylond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
    
    echo -e "\n"
    echo -e "下面开始创建babylon钱包，会让你创建一个钱包密码..."
    babylond --keyring-backend test keys add wallet
    sed -i -e "s|^key-name *=.*|key-name = \"wallet\"|" ~/.babylond/config/app.toml
    sed -i -e "s|^timeout_commit *=.*|timeout_commit = \"30s\"|" ~/.babylond/config/config.toml
    babylond create-bls-key $(babylond keys show wallet -a)
    cat $HOME/.babylond/config/priv_validator_key.json
    echo -e "\n"
    echo -e "请保存上面创建好的钱包地址、私钥、助记词等信息..."

    sudo systemctl daemon-reload
    sudo systemctl enable babylond.service
}

start_babylon_node() {
    # Start the service and check the logs
    sudo systemctl start babylond.service
    sudo journalctl -u babylond.service -f --no-hostname -o cat
}

check_node_status_and_height() {
    babylond status | jq
    systemctl status babylond
}

get_log() {
    sudo journalctl -u babylond.service -f --no-hostname -o cat
}

start_validator_node() {
    read -e -p "请输入你的验证者名称: " validator_name
    sudo tee ~/validator.json > /dev/null <<EOF
{
  "pubkey": $(babylond tendermint show-validator),
  "amount": "50000ubbn",
  "moniker": "$validator_name",
  "details": "$validator_name validator node",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
    babylond tx checkpointing create-validator ~/validator.json \
    --chain-id=$CHAIN_ID \
    --gas="auto" \
    --gas-adjustment="1.5" \
    --gas-prices="0.025ubbn" \
    --from=wallet
}

echo && echo -e " ${Red_font_prefix}babylon节点 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装babylon节点环境 ${Font_color_suffix}
 ${Green_font_prefix} 2.运行babylon节点 ${Font_color_suffix}
 ${Green_font_prefix} 3.检查节点状态 ${Font_color_suffix}
 ${Green_font_prefix} 4.显示同步日志 ${Font_color_suffix}
 ${Green_font_prefix} 5.成为验证者（需要等节点同步到最新区块） ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程执行以上步骤，请输入数字 [1-5]:" num
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
    get_log
    ;;
5)
    start_validator_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
