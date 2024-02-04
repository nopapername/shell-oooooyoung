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
    read -e -p "请输入你的节点名称: " node_name
    
    install_go
    ufw allow 255656
    ufw allow 255657
    ufw allow 16456

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

    source $HOME/.bash_profile
    babylond init $node_name --chain-id $CHAIN_ID
    wget https://github.com/babylonchain/networks/raw/main/$CHAIN_ID/genesis.tar.bz2
    tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
    mv genesis.json ~/.babylond/config/genesis.json

    PEERS="48b70b9119e163eeffa0e13bf5f16c00f2c4cc6c@43.153.7.211:16456,97483fca7392b9e5286a79c2f15bbc6cd8078c51@89.116.26.9:16456,59f28e3c87ba3ab7803a328304adebfc07cfe3e2@154.42.7.86:26656,b19b98d8be060a8979b68413c5af19e1a735178f@154.42.7.126:26656,572c75ad920c0c2634e1ba9c5e5b0e11310a8189@38.242.157.234:16456,34ce32c340ee34fb1dce5bf6db3f6bd7bbfe9e74@89.117.58.67:26656,0123d9c8840ef3c9f8b966525bf9ab48012fd29d@65.108.129.239:40656,9330158f5529919c6755789a49289106c0906044@142.93.111.103:31156,36777fb6c115526b9f93c3ed8b12924edef4ed5a@144.91.122.16:31156,9b8a98bf62eacc17d81af574b17762f7212b504e@38.242.239.200:16456,47758f2d0098336450fb469bdddbd28d33ef55ef@164.68.109.193:26656,08f8da861fcf6e21d6f04d6b21e3486c0d406521@84.247.176.34:16456,118a68dbb190bec1b9882ef27c0edb5af79a052e@104.248.198.47:31156,d28a7d985792c8da159e4c7f7780599b5a49e26e@37.60.226.181:39656,2581815dc03b24493d8fa782b103053ff0c101cf@109.205.183.92:16456,39b8c9adc8801d5c2b444fe7145860eb04bbc9ec@65.108.59.77:31156,eef91e5162efc7741a1befa580c38e7c2beed646@173.212.242.247:16456,8cf202322b60fdf8aa2d4dc4ba6e7c1b965767af@37.60.233.90:16456,16f033e6a8ee599948f2ab9349899ef2bbded61a@65.109.70.45:27656,530fdeb6dabd3973d2a6c292281508a145a66514@164.92.147.45:31156,948793178a6a1ed76ede26d0d0b20d28c2987f1b@62.171.144.190:16456,67cc3790dc79b5b20db33e082d7baa1c3283b29f@37.27.55.100:24656,d0eee59ce53bdd6d82d01281f36819d9b94e7a34@46.4.57.161:16456,84b6e369a271ddf70b7e0922abfe603809769b8b@35.188.47.245:16456,a5e599c3aab6e8dbb24b059881ae1e4c678c8b0b@173.212.224.231:16456,c9c67bb3a27642a4c4486394f281fc7262c2b91a@65.109.27.66:16456,05b82c341f2b4a38ad818ee008a7ff7e6989a0f3@2.59.156.143:16456,f03de36968bffdd85d39f967790a9a5407ffa6a0@158.220.111.115:16456,f82d5e03c398427c73b56e7269c3036401494c68@217.76.51.234:16456,51923798728a76dfa02692e736110589619dcff9@37.60.233.146:16456,d1e004e1893b909a80ace534aae551f6612d70a7@144.91.111.63:16456,c79ce6ef899eb45b10e7a281be33f20b16fd4dab@161.97.77.253:16456,32f630b3f1968f6414c0ea5eaad95e02f0363e52@80.65.211.25:26656,0145f790c613115eab414a88f49af52c21513137@185.187.170.244:26656,40847bca6a8ce81505be286c89d8a77ec8e16855@62.171.170.251:16456,5a5a641151f96d2ebcae7a0c82e1019f83cb08f3@158.220.111.116:16456,86aee180d53d7511da6447d579604648dcd0d0d5@62.171.140.23:16456,64265d363a59786d00079019bd01f44256154c50@37.60.241.42:16456,899c8c04812b245114b9e41f30d1d39c0ec8b5aa@45.94.209.251:16456,0b036129ab350352fb420e366c57c62137f6ccbd@207.180.242.155:16456,50e73c636d2003b429443dc95d38e0df51a64ada@109.123.241.165:16456,5aab12afc44f6e7aa483db25edcef911f3d23265@38.242.216.136:16456,894e1db27292893cc3bc28a812002f6c5a3c5ee5@89.116.30.4:16456,0f8fbe7f95140f201532af60f95f11e382917706@5.78.115.108:26656,2acab2ec47cf74c08837e80397385fda71aeac2c@109.205.180.179:16456,b5b958b9436232fea079f8e360d305e0426d0210@38.242.253.213:16456,c5740321ed9c88ae1f68756bcfae6ce72c7496aa@158.220.117.40:16456,0b358f935a308e92ac65ec73164bfee664546cf7@95.111.240.243:16456,e385f4a8d1ec856be009184e69a330001bd5bac3@31.220.81.18:16456,e0a500684bda510d8f135e5a7cee16f13fd0be03@45.84.138.177:16456,5385dede6e35968e25079ccaa3ea2f2c0d6081fb@217.76.55.142:16456,475cd560ed1b70f91a77359fd13d2b75dd40e0ba@82.208.22.179:16456,ea6e8374c3ff2603d535d2648d963b76bd4fd314@109.123.242.32:26656,e2adf7d3f26eb2d6eb79401e8c5baf7d20e29332@37.60.239.42:16456,030bc7c0258bed9a3a7f351086e63b5f5a1239b1@64.23.152.172:16456,0dc7db2998653f0100d6a78976d67334c22e793b@207.180.227.245:16456,41c49af20914f90cf6470df840937a8fda8e938b@74.48.96.73:31156,dc59f8b0e56d6a202f8971626549f4c873f55fcd@161.97.101.213:16456,3768787187f3d8e7d40a5f447d88eaf2c1868fa0@167.86.124.216:16456,d406e755b67d692502c9d4aac38900fe50f0eb9f@194.163.173.205:16456,e9504655fb196e5a590d3de61de1c8dabae37154@194.163.147.249:16456,214d64d4e131a83a8617b74b06ef47b3b12fe289@162.55.232.19:16456,a2d1338f7d97a5e2cdd5292852fbb42ef6e078d7@161.97.117.23:16456,56278f82c1ceb4c51675e5ab1b0cce4bb67e6cb1@185.202.223.139:16456,51314f182689b204c314f9c0fda2e82a7daa6666@95.111.238.104:16456,710cdbf8963dde662900e0569adb5a831822d682@217.76.52.187:16456,5fc87fd93fe205247b35fd19440fb7f3d4234f44@84.247.174.173:31656,a8a37b3969c7282f76e68280407335e051d75d63@185.217.197.15:16456,5404edff89d93e97832ab294a88c91bcb8b0e594@54.238.212.246:26656,c08fe104825dc3ce6ee5f2582f00e497aa8a1c37@75.119.141.16:16456,2fb643493b8ebe450df69758b48c9ff0024e8acc@184.174.34.61:16456,e7a7a643c04bea89eeb9ab064f8585bcf51daec5@38.242.139.145:16456,279eb15f3a9cc7f90f6a025c66e0b16b6ef58597@185.241.151.110:16456,badbfa1b9fb9077f2a5380e1d59fa6253bf1561f@38.242.234.159:16456,09ad2c93fe84ebf93ce28e43b290fa3b9f3bbf24@161.97.72.103:16456,1d6f92199ea41f386ea07bb48372eaf411a2612f@62.171.133.146:16456,a24220688be9fd8391a59fac064a202a54f5d2ad@84.247.169.225:16456,cc427314669628fe685b57f5045f1d5e68654cd0@37.60.225.111:16456,e8a1ee75decc9c77774c8d13d53d4994c368bff0@161.97.140.251:16456,36a93fae1cf2343e6497822366b48cbc8de5f322@84.247.185.173:26656,406c79ca6ea705447b252c7cbffb550d58719a76@84.247.184.25:26656,d4f92d416b2865efefc16f71d9b30622aca484bd@185.197.251.44:16456,c87c234a8b09eebf82b94241f60cbbe1b9609381@109.123.255.196:31156,7af999f6b522d75222f919da358bc04390232048@5.189.144.235:26656,073b932d05cc86c537e1471211a47f8c7e24b3f7@37.60.235.158:16456,1fc80e5c6b55e5ccb9e1c8f01a13a14ca04e6e78@37.60.237.28:16456,073f6f5bc17bc093a204478256c6946aef584f28@135.181.39.253:16456,1953aedc99fbe5e2704e3a308eaccdeb4aec7c6f@194.163.149.73:16456,df911edd6a5cccbabb13caaec8df88794ab0bd68@147.45.42.201:16456,97c208a8b0ddbb99526a6921d9e145d80ea27e9a@43.153.117.223:16456,a3a74e48d972accc2d909de701593812e1429ee9@37.60.224.93:16456,7b0be9c509f35253fa1038bbb21cd6f60f747c23@149.102.146.181:16456,eefc21a98adfd6267a2c7a28542286fa61b75060@165.227.46.22:16456,7fe3c3006093bcfbfc8b428d5a027f72a00512b3@161.97.106.204:16456,9f733a49467d1ece48a58310e345ced8cb2c076d@222.106.187.14:53900,8bf79448eeafcdcf54c0cae63475bed9b9726ad7@37.60.235.216:16456,e37a883d7e1175096dba08a268e7cbe0066476e7@109.123.244.160:16456,67b31015271e75cb9c3762462467fa1b4d1ffa8b@173.212.242.100:16456,4ae77d528d8b376ea4da85497b76bd2e9cd06aea@84.46.242.198:16456,ed48c57c13c8ba54e29635b640ac3217e315118d@194.163.176.216:16456"
    
    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.babylond/config/config.toml
    sed -i.bak -e "s/^seeds *=.*/seeds = \"$PEERS\"/" $HOME/.babylond/config/config.toml

    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

    mkdir -p ~/.babylond/cosmovisor
    mkdir -p ~/.babylond/cosmovisor/genesis
    mkdir -p ~/.babylond/cosmovisor/genesis/bin
    mkdir -p ~/.babylond/cosmovisor/upgrades

    cp $HOME/go/bin/babylond ~/.babylond/cosmovisor/genesis/bin/babylond
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

    sudo -S systemctl daemon-reload
    sudo -S systemctl enable babylond
    echo -e "\n"
    echo -e "下面开始创建babylon钱包，会让你创建一个钱包密码..."
    babylond keys add wallet
    sed -i -e "s|^key-name *=.*|key-name = \"wallet\"|" ~/.babylond/config/app.toml
    sed -i -e "s|^timeout_commit *=.*|timeout_commit = \"10s\"|" ~/.babylond/config/config.toml
    echo -e "\n"
    echo -e "请保存上面创建好的钱包地址、私钥、助记词等信息..."
}

start_babylon_node() {
    source $HOME/.bash_profile
    sudo systemctl restart babylond
    sudo journalctl -u babylond -f --no-hostname -o cat
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
