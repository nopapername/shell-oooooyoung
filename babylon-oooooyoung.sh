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
    install_go

    # Clone project repository
    cd && rm -rf babylon
    git clone https://github.com/babylonchain/babylon
    cd babylon
    git checkout v0.8.3

    # Build binary
    make install

    # Set node CLI configuration
    babylond config chain-id $CHAIN_ID

    # Initialize the node
    babylond init "$node_name" --chain-id $CHAIN_ID

    # Download genesis
    wget https://github.com/babylonchain/networks/raw/main/bbn-test-3/genesis.tar.bz2
    tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
    mv genesis.json ~/.babylond/config/genesis.json

    # Set seeds
    sed -i -e 's|^seeds *=.*|seeds = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,5463943178cdb57a02d6d20964e4061dfcf0afb4@142.132.154.53:20656,3774fb9996de16c2f2280cb2d938db7af88d50be@162.62.52.147:26656,9d840ebd61005b1b1b1794c0cf11ef253faf9a84@43.157.95.203:26656,0ccb869ba63cf7730017c357189d01b20e4eb277@185.84.224.125:20656,3f5fcc3c8638f0af476e37658e76984d6025038b@134.209.203.147:26656,163ba24f7ef8f1a4393d7a12f11f62da4370f494@89.117.57.201:10656,1bdc05708ad36cd25b3696e67ac455b00d480656@37.60.243.219:26656,59df4b3832446cd0f9c369da01f2aa5fe9647248@65.109.97.139:26656,e3b214c693b386d118ea4fd9d56ea0600739d910@65.108.195.152:26656,c0ee3e7f140b2de189ce853cfccb9fb2d922eb66@95.217.203.226:26656,e46f38454d4fb889f5bae202350930410a23b986@65.21.205.113:26656,35abd10cba77f9d2b9b575dfa0c7c8c329bf4da3@104.196.182.128:26656,6f3f691d39876095009c223bf881ccad7bd77c13@176.227.202.20:56756,1ecc4a9d703ad52d16bf30a592597c948c115176@165.154.244.14:26656,0c9f976c92bcffeab19944b83b056d06ea44e124@5.78.110.19:26656,c3e82156a0e2f3d5373d5c35f7879678f29eaaad@144.76.28.163:46656,b82b321380d1d949d1eed6da03696b1b2ef987ba@148.251.176.236:3000,eee116a6a816ca0eb2d0a635f0a1b3dd4f895638@84.46.251.131:26656,894d56d58448a158ed150b384e2e57dd7895c253@164.92.216.48:26656,ddd6f401792e0e35f5a04789d4db7dc386efc499@135.181.182.162:26656,326fee158e9e24a208e53f6703c076e1465e739d@193.34.212.39:26659,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,fad3a0485745a49a6f95a9d61cda0615dcc6beff@89.58.62.213:26501,ce1caddb401d530cc2039b219de07994fc333dcf@162.19.97.200:26656,66045f11c610b6041458aa8553ffd5d0241fd11e@103.50.32.134:56756,82191d0763999d30e3ddf96cc366b78694d8cee1@162.19.169.211:26656"|' $HOME/.babylond/config/config.toml
    sed -i -e 's|^persistent_peers *=.*|persistent_peers = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,5463943178cdb57a02d6d20964e4061dfcf0afb4@142.132.154.53:20656,3774fb9996de16c2f2280cb2d938db7af88d50be@162.62.52.147:26656,9d840ebd61005b1b1b1794c0cf11ef253faf9a84@43.157.95.203:26656,0ccb869ba63cf7730017c357189d01b20e4eb277@185.84.224.125:20656,3f5fcc3c8638f0af476e37658e76984d6025038b@134.209.203.147:26656,163ba24f7ef8f1a4393d7a12f11f62da4370f494@89.117.57.201:10656,1bdc05708ad36cd25b3696e67ac455b00d480656@37.60.243.219:26656,59df4b3832446cd0f9c369da01f2aa5fe9647248@65.109.97.139:26656,e3b214c693b386d118ea4fd9d56ea0600739d910@65.108.195.152:26656,c0ee3e7f140b2de189ce853cfccb9fb2d922eb66@95.217.203.226:26656,e46f38454d4fb889f5bae202350930410a23b986@65.21.205.113:26656,35abd10cba77f9d2b9b575dfa0c7c8c329bf4da3@104.196.182.128:26656,6f3f691d39876095009c223bf881ccad7bd77c13@176.227.202.20:56756,1ecc4a9d703ad52d16bf30a592597c948c115176@165.154.244.14:26656,0c9f976c92bcffeab19944b83b056d06ea44e124@5.78.110.19:26656,c3e82156a0e2f3d5373d5c35f7879678f29eaaad@144.76.28.163:46656,b82b321380d1d949d1eed6da03696b1b2ef987ba@148.251.176.236:3000,eee116a6a816ca0eb2d0a635f0a1b3dd4f895638@84.46.251.131:26656,894d56d58448a158ed150b384e2e57dd7895c253@164.92.216.48:26656,ddd6f401792e0e35f5a04789d4db7dc386efc499@135.181.182.162:26656,326fee158e9e24a208e53f6703c076e1465e739d@193.34.212.39:26659,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,fad3a0485745a49a6f95a9d61cda0615dcc6beff@89.58.62.213:26501,ce1caddb401d530cc2039b219de07994fc333dcf@162.19.97.200:26656,66045f11c610b6041458aa8553ffd5d0241fd11e@103.50.32.134:56756,82191d0763999d30e3ddf96cc366b78694d8cee1@162.19.169.211:26656"|' $HOME/.babylond/config/config.toml
    

    # Set minimum gas price
    sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.00001ubbn"|' $HOME/.babylond/config/app.toml

    # Set additional configs
    sed -i 's|^network *=.*|network = "signet"|g' $HOME/.babylond/config/app.toml

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
    sudo systemctl restart babylond.service
    sudo journalctl -u babylond.service -f --no-hostname -o cat
}

check_node_status_and_height() {
    systemctl status babylond
}

get_log() {
    sudo journalctl -u babylond.service -f --no-hostname -o cat
}

start_validator_node() {
    read -e -p "请输入你的验证者名称: " validator_name
    pubkey=$(babylond tendermint show-validator)
    cat > ~/validator.json <<EOF
{
  "pubkey": $pubkey,
  "amount": "1000000ubbn",
  "moniker": "$validator_name",
  "details": "$validator_name validator node",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
    babylond tx checkpointing create-validator ~/validator.json --from=wallet --chain-id="$CHAIN_ID" --gas="auto" --gas-adjustment="1.5" --gas-prices="0.025ubbn" --keyring-backend=test --from="wallet"
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
