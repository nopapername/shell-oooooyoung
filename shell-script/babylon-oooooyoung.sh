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
    make build

    # Prepare directories
    mkdir -p ~/.babylond
    mkdir -p ~/.babylond/cosmovisor
    mkdir -p ~/.babylond/cosmovisor/genesis
    mkdir -p ~/.babylond/cosmovisor/genesis/bin
    mkdir -p ~/.babylond/cosmovisor/upgrades

    # Install Cosmovisor
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

    # Move BabylonD file to Cosmovisor directory
    mv build/babylond $HOME/.babylond/cosmovisor/genesis/bin/
    rm -rf build

    # Create application symlinks
    sudo ln -s $HOME/.babylond/cosmovisor/genesis $HOME/.babylond/cosmovisor/current -f
    sudo ln -s $HOME/.babylond/cosmovisor/current/bin/babylond /usr/local/bin/babylond -f

    # Initialize the node
    babylond init $node_name --chain-id $CHAIN_ID

    # Download genesis
    wget https://github.com/babylonchain/networks/raw/main/bbn-test-3/genesis.tar.bz2
    tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
    mv genesis.json ~/.babylond/config/genesis.json

    # Add seeds
    sed -i -e 's|^seeds *=.*|seeds = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656"|' $HOME/.babylond/config/config.toml

    # Change network to signet:
    sed -i -e "s|^\(network = \).*|\1\"signet\"|" $HOME/.babylond/config/app.toml

    # Set minimum gas price:
    sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00001ubbn\"|" $HOME/.babylond/config/app.toml

    # Set peers:
    PEERS="3774fb9996de16c2f2280cb2d938db7af88d50be@162.62.52.147:26656,b82b321380d1d949d1eed6da03696b1b2ef987ba@148.251.176.236:3000,3fb6251a235480e81c8f964ff25304b2b4e7a071@43.128.69.178:26501,c0ee3e7f140b2de189ce853cfccb9fb2d922eb66@95.217.203.226:26656,e46f38454d4fb889f5bae202350930410a23b986@65.21.205.113:26656,25abb614b96fa606fb5514fcf711635e8e861d8f@217.72.207.107:26656,670d3cc0b1b4d008db95110557190b1d51c3cc87@43.156.24.202:26501,8e4e408a2e157e7ed3fce000525ff8ba22e8f6a8@135.181.58.31:26656,c3e82156a0e2f3d5373d5c35f7879678f29eaaad@144.76.28.163:46656,82191d0763999d30e3ddf96cc366b78694d8cee1@162.19.169.211:26656,26acaa8356468376abcfbbafb92e45fcb9fb14c7@65.109.64.179:26656,bb60df4fc43fd4915e16a779611e919fda4a57cb@95.216.187.89:26656,73d0b886307757aa7e0778ca272851c1d24c2e7d@135.181.246.250:3400,35abd10cba77f9d2b9b575dfa0c7c8c329bf4da3@104.196.182.128:26656,26cb133489436035829b6920e89105046eccc841@178.63.95.125:26656,2b9433ec17f98c902ce6bf0031342f20fb6e9cf8@80.64.208.1:26656,9d840ebd61005b1b1b1794c0cf11ef253faf9a84@43.157.95.203:26656,59b484e1370f211ba74f5b8e1316a0752a55d090@65.108.75.197:26656,fd837edb83d1ad175041b9a72ae6b0f5874d1df7@3.136.250.177:26656,564af85d70a1f7227146b1840f467015f8e9af5a@141.95.110.70:26656,a1a0ec58bf2be5ba114a648f84e53e776f5e4902@3.139.218.231:26656,868730197ee267db3c772414ec1cd2085cc036d4@148.251.235.130:17656,ce1caddb401d530cc2039b219de07994fc333dcf@162.19.97.200:26656,79973384380cb9135411bd6d79c7159f51373b18@133.242.221.45:26656,94039e66a22103ce28c85852c594cacabc6decd1@37.27.54.184:27656,e2a105f8da7a3653fe8149471d84ca1e39d51e53@161.97.131.159:20656,163ba24f7ef8f1a4393d7a12f11f62da4370f494@89.117.57.201:10656,ac65cb7c09f9b0f8aaf2605a9cf9d5684cda87d9@3.129.218.47:26656,2cc3d19c8126a3cecdb95401a525d6a2832a76b8@121.78.247.252:33656,11a40047f142b07119b29262da9f7800640b0699@88.217.142.242:16456,4d992a77957f6937a275a7966ad906f9c3e2f0be@114.203.200.187:26656,09ecb5c2c5c039b35e87be56b43263d1b1552208@109.199.114.30:26656,3bd2dbed00eab2bdf777ecb012ceff403659f8ef@18.171.248.222:26656,be1ff98cfdad3b765d3ef0ebd44ead182a020d23@95.217.35.179:26656,1bdc05708ad36cd25b3696e67ac455b00d480656@37.60.243.219:26656,26240e4061426d22d5594f91f2754a28a80494bc@109.199.96.75:26656,7720914dd724043a1cd5950fad726f67e155fb15@88.198.54.190:43656,ddd6f401792e0e35f5a04789d4db7dc386efc499@135.181.182.162:26656,5afce223a3b96954d0fbbac00c22318600c7b6b9@173.249.44.69:26656,798836777efb5555cfb940129e2073b44f9117e5@141.94.143.203:55706,21d9dd05fa924cbcdaf501b92b74bf106af29c95@89.58.32.218:25000,8566da036cb96a50b011f7a04eb796748f71a71e@51.89.40.26:26656,90eac330252ff51bf461602e7b8df054ce8583ae@65.109.64.57:26656,d43f2ed7961c199dc304e3e34d03247f0aa0615e@51.158.77.69:26656,424325d33fcc86c1cfc085cf412b105348ac2fcd@65.109.85.221:2050,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,5b197ab8f05c0140d622b258f0734a3bb7c4128d@88.198.8.79:2050,326fee158e9e24a208e53f6703c076e1465e739d@193.34.212.39:26659,259e9bdb6aabf01f42cdd5367f69aab5996afea4@37.27.59.71:20656,5463943178cdb57a02d6d20964e4061dfcf0afb4@142.132.154.53:20656,b9aaacb74ff31b304c294bdfc7d59c616e8b811a@213.202.212.75:26656,179a498904d880587cc37d07ebd1e01ff81a02fe@3.139.215.161:26656,a25c37941e272b5ed0ea40e8f39e95c0d9c55083@178.63.105.185:26656,05ec92459362ea3969a8980ec87e64df49cf8826@65.108.236.43:21156,e3b214c693b386d118ea4fd9d56ea0600739d910@65.108.195.152:26656,f7c9542e9d9af79f37d1698839787a86f7f8aef0@37.60.234.51:26656,59df4b3832446cd0f9c369da01f2aa5fe9647248@65.109.97.139:26656,5e02bb2c9a644afae6109bf2c264d356fad27618@15.165.166.210:26656,49b15e202497c231ebe7b2a56bb46cfc60eff78c@135.181.134.151:46656,6990fd085c9e2e8c9256f144799d18df51f74022@141.94.195.144:26656,118d4b1b0f58d9c038fafc18085808a593539e7a@78.46.71.227:26656,6359d70612b9abf7d4d458dc1938ec06f2a21652@129.226.152.250:26501,b4215706647068b234d8b72da1736b0e460e5cf1@65.21.228.25:26656,e27df9014fd0d37d917fb33f2d9de7500a8fab70@35.91.9.184:26656,5145171795b9929c41374ce02feef8d11228c33b@160.202.128.199:55706,1eb7b2585cf32255abc0371cd07624cba0706e29@103.35.191.186:26656,2abdfe743b995a8d86fa32f8a38127f1e36a628d@207.180.204.34:26656,4e893ae5671ac29b90229ec69528f731b5e359bb@36.153.240.230:26656,197d15d24b7f83bff06ef6e8ecc6120c5a14a556@37.60.227.81:26656,5b124ed79f5f0c02ffca4bfb8a73469265f46de1@3.132.112.231:26656,f887f4a18019563bcf3fc23079eb68b86931a766@37.60.226.84:16456,f0043c64dff1f95d356107b9f31ace39b4154990@38.242.253.112:26656,bcc5bd089b30bc8c96095a5cd4a8cd45e8c197a0@112.213.190.1:26656,bdd106eaa1b0ecb5ea13e03344147f34d1f457a1@65.108.43.51:26656,89a4dbf6593caa6d337cf02b049cab245ceb6ede@128.140.73.180:26656,7138083f9a513a33d3fd4d477d28436ff368367a@84.247.133.117:26656,0c9f976c92bcffeab19944b83b056d06ea44e124@5.78.110.19:26656,8f618f4f40d1c27e27b760ca10246b8b113e94be@18.222.121.72:26656,10b483d706782dd53834eca77562e081e52b16dd@3.137.160.91:26656,b1783b0d95ffeeac6c81be47ff8552bbc27bc054@18.191.27.217:26656,6460741d8b2701f6d733e0c5a9a52a9d5a924c9f@217.76.63.213:26656,94a6b8d058bc3db464ab8ec0b824cd40c09a2385@3.131.193.119:26656,9f7fd2aebea04d099eb9a60c8483a5b88a5b1db6@161.97.123.142:26656,d9b3f259aa6271351485e75c1adfc949a6c8919d@38.242.253.115:26656,73c9f1a0eba78497adadfd3a23b6391219eae29d@43.128.123.8:26501,d06147e71166c7e5fdf97378aa32ba5ef2a2be2f@43.134.176.53:26501,dbceef939143cdbf7131d9a185314c4849c81a98@202.61.199.52:26656,395af7ddf487e3adb1600adfdf276e9410d2bc39@36.189.234.219:26656,fad3a0485745a49a6f95a9d61cda0615dcc6beff@89.58.62.213:26501,f90d6a73190698aaec5554839229cad20693e04a@37.27.14.222:26656,9e36d595b69c75f94771d9dee791f822578e14da@173.212.244.215:26656,be95de5f28496fe8b7e93ce5ccbeec9db271520b@162.19.95.240:14656,e8f550ed3fea54eda7fa3f8ed3d6b17cb222fedf@95.111.239.100:26656,36123e2b3e3612c6a4abf6c81b71546168f7688d@109.199.114.26:26656,6c14e076d92f715b0a1f7b03b09af8c28f0d9469@65.108.153.90:26656,a31b620c076899133e44d195eae0d6308283230d@57.128.19.189:26656,4dbf5157b735de59fb84be26f2bd40a16cee056c@54.238.212.246:26656,1ecc4a9d703ad52d16bf30a592597c948c115176@165.154.244.14:26656,6e96d1fa4ff9cc573b3c41c3f722aa9b373d886e@154.91.1.78:26656,b5bbe6054b46055242aa72e71614c5b14527dce3@150.109.95.158:26501,37d27ecded8181952f99648628ff2c8d85286432@62.195.206.235:26656,ac0b5e230dfdc573f74642c48898e1398a1e5050@65.108.78.101:26656,0ccb869ba63cf7730017c357189d01b20e4eb277@185.84.224.125:20656,86eecc48c181a2e508852f6f3a170b99a09cae87@74.208.197.25:26656,e9913c53da2a7a1432ee65e17f8b90b072ff3ee6@109.199.113.189:26656,1a0b3386617587ad7e678e0ea522c79f1fe4113a@65.109.88.254:38656,07d1b69e4dc56d46dabe8f5eb277fcde0c6c9d1e@23.88.5.169:17656,fb5ea45358d13679518f43d995f42442a79b161f@185.246.87.105:56656,b80b2fb6002557b468add907074d0bf2ef4f911e@158.220.84.179:29656,ef83feb0f03af81e65a9fa511f7a99401308a99a@43.156.182.164:26501,3deaff1478542cf7f28123ad33be50d4bc08b728@2.56.97.152:26656,40662747f0e01678dbdf1e50879f40a68139d7aa@35.163.58.204:26656,b08f08b8f10103ce97f3b5cbd274795687ce4866@164.68.96.90:26656,68de398f1d36546c002086b91f6018ed5c6105f2@5.189.136.136:26656,34807baef8c02bc202fb14035f7d375a6a5ff30e@95.217.193.182:21656,69c1b7e1eb114703733c3000baa6c008ebc70073@65.109.113.233:20656"
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml
    
    # Create a service
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
    babylond keys add wallet
    sed -i -e "s|^key-name *=.*|key-name = \"wallet\"|" ~/.babylond/config/app.toml
    sed -i -e "s|^timeout_commit *=.*|timeout_commit = \"30s\"|" ~/.babylond/config/config.toml
    babylond create-bls-key $(babylond keys show wallet -a)
    cat $HOME/.babylond/config/priv_validator_key.json
    echo -e "\n"
    echo -e "请保存上面创建好的钱包地址、私钥、助记词等信息..."

    sudo -S systemctl daemon-reload
    sudo -S systemctl enable babylond
}

start_babylon_node() {
    # Start the service and check the logs
    sudo -S systemctl restart babylond
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
