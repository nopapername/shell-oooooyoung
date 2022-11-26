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

install_validator_software() {
    check_root
    sudo apt install curl
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL repo.chainflip.io/keys/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/chainflip.gpg
    gpg --show-keys /etc/apt/keyrings/chainflip.gpg
    echo "deb [signed-by=/etc/apt/keyrings/chainflip.gpg] https://repo.chainflip.io/perseverance/ focal main" | sudo tee /etc/apt/sources.list.d/chainflip.list

    sudo apt update
    sudo apt install -y chainflip-cli chainflip-node chainflip-engine
}

get_generating_keys() {
    read -e -p "请粘贴验证钱包的私钥private key: " YOUR_VALIDATOR_WALLET_PRIVATE_KEY
    sudo mkdir -p /etc/chainflip/keys
    echo -n "请确认您输入的private key为:"
    echo -n "$YOUR_VALIDATOR_WALLET_PRIVATE_KEY" | sudo tee /etc/chainflip/keys/ethereum_key_file
    echo -e "\n请保存好以下的私钥及各种地址------"
    chainflip-node key generate 2>&1 | tee user_save_key
    pattern=`cat user_save_key | grep "Secret seed:"`
    secret_seed=${pattern#*:}
    secret_seed=${secret_seed// /}
    echo -e -n "\nsigning_key_file:"
    echo -n "${secret_seed:2}" | sudo tee /etc/chainflip/keys/signing_key_file
    echo -e -n "\nchainflip_key:"
    sudo chainflip-node key generate-node-key --file /etc/chainflip/keys/node_key_file
    echo -e -n "node_key_file:"
    cat /etc/chainflip/keys/node_key_file
    echo -e "\n"
}

start_chainflip_node() {
    read -e -p "请输入你的服务器ip: " IP_ADDRESS_OF_YOUR_NODE
    read -e -p "请输入你的alchemy RPC WEBSOCKETS地址: " WSS_ENDPOINT_FROM_ETHEREUM_CLIENT
    read -e -p "请输入你的alchemy RPC HTTPS地址: " HTTPS_ENDPOINT_FROM_ETHEREUM_CLIENT
    sudo mkdir -p /etc/chainflip/config
    echo "# Default configurations for the CFE
[node_p2p]
node_key_file = \"/etc/chainflip/keys/node_key_file\"
ip_address=\"$IP_ADDRESS_OF_YOUR_NODE\"
port = \"8078\"

[state_chain]
ws_endpoint = \"ws://127.0.0.1:9944\"
signing_key_file = \"/etc/chainflip/keys/signing_key_file\"

[eth]
# Ethereum RPC endpoints (websocket and http for redundancy).
ws_node_endpoint = \"$WSS_ENDPOINT_FROM_ETHEREUM_CLIENT\"
http_node_endpoint = \"$HTTPS_ENDPOINT_FROM_ETHEREUM_CLIENT\"

# Ethereum private key file path. This file should contain a hex-encoded private key.
private_key_file = \"/etc/chainflip/keys/ethereum_key_file\"

[signing]
db_file = \"/etc/chainflip/data.db\"" > /etc/chainflip/config/Default.toml
    sudo systemctl start chainflip-node
    tail -f /var/log/chainflip-node.log
}

start_chainflip_engine() {
    sudo systemctl start chainflip-engine
    sudo systemctl enable chainflip-node
    sudo systemctl enable chainflip-engine
    tail -f /var/log/chainflip-engine.log
}

registering_validator_keys() {
    read -e -p "请取一个Staking页面中验证者的别名: " validator_nickname
    sudo systemctl restart chainflip-engine
    sudo chainflip-cli \
      --config-path /etc/chainflip/config/Default.toml \
      register-account-role Validator

    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml \
    activate

    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml rotate

    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml \
    vanity-name $validator_nickname
}

restart_node_and_engine() {
    sudo systemctl restart chainflip-node
    sudo systemctl restart chainflip-engine
    tail -f /var/log/chainflip-engine.log
}

out_staking() {
    read -e -p "输入接收tflip的主钱包ETH地址：" ETH_ADDRESS
    read -e -p "输入解除质押的tflip数量：" FLIP_AMOUNT
    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml \
    retire

    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml \
    claim $FLIP_AMOUNT $ETH_ADDRESS
}

echo && echo -e " ${Red_font_prefix}Chainflip 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装 chainflip validator software ${Font_color_suffix}
 ${Green_font_prefix} 2.获取节点的秘钥及地址 ${Font_color_suffix}
 ${Green_font_prefix} 3.启动Chainflip node ${Font_color_suffix}
 ${Green_font_prefix} 4.启动Chainflip engine ${Font_color_suffix}
 ${Green_font_prefix} 5.注册Chainflip Stake验证者帐号 ${Font_color_suffix}
 ${Green_font_prefix} 6.重启Chainflip node和engine(服务出错或停止时才选择此步，正常搭建请忽略此项) ${Font_color_suffix}
 ${Green_font_prefix} 7.解除质押tflip ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程依次执行前面五个步骤（后面两步按需使用），请输入数字 [1-7]:" num
case "$num" in
1)
    install_validator_software
    ;;
2)
    get_generating_keys
    ;;
3)
    start_chainflip_node
    ;;
4)
    start_chainflip_engine
    ;;
5)
    registering_validator_keys
    ;;
6)
    restart_node_and_engine
    ;;
7)
    out_staking
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
