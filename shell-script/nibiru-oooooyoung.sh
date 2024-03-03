Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"

NETWORK=nibiru-itn-1

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限), 无法继续操作, 请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_nibiru_node_and_run() {
    check_root
    sudo apt install -y curl git wget
    sudo apt update && sudo apt upgrade --yes
    curl -s https://get.nibiru.fi/@v0.19.2! | bash
    read -e -p "请输入你的验证者名称：" MONIKER_NAME
    nibid init $MONIKER_NAME --chain-id=$NETWORK --home $HOME/.nibid
    nibid keys add "$MONIKER_NAME-key"
    echo -e '请存储上面的地址及私钥后按回车继续启动节点...\n'
    curl -s https://networks.itn.nibiru.fi/$NETWORK/genesis > $HOME/.nibid/config/genesis.json
    sed -i 's|seeds =.*|seeds = "'$(curl -s https://networks.itn.nibiru.fi/$NETWORK/seeds)'"|g' $HOME/.nibid/config/config.toml
    sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.025unibi"/g' $HOME/.nibid/config/app.toml
    sed -i 's|enable =.*|enable = true|g' $HOME/.nibid/config/config.toml
    sed -i 's|rpc_servers =.*|rpc_servers = "'$(curl -s https://networks.itn.nibiru.fi/$NETWORK/rpc_servers)'"|g' $HOME/.nibid/config/config.toml
    sed -i 's|trust_height =.*|trust_height = "'$(curl -s https://networks.itn.nibiru.fi/$NETWORK/trust_height)'"|g' $HOME/.nibid/config/config.toml
    sed -i 's|trust_hash =.*|trust_hash = "'$(curl -s https://networks.itn.nibiru.fi/$NETWORK/trust_hash)'"|g' $HOME/.nibid/config/config.toml
    nibid config chain-id nibiru-itn-1
    nohup nibid start >> /root/.nibid/nibid.log 2>&1 &
    tail -f /root/.nibid/nibid.log
}

request_faucet_nibi() {
    read -e -p "请输入你的nibi钱包地址：" WALLET_ADDRESS
    FAUCET_URL="https://faucet.itn-1.nibiru.fi/"
    curl -X POST -d '{"address": "'"$ADDR"'", "coins": ["11000000unibi","100000000unusd","100000000uusdt"]}' $FAUCET_URL
}

create_validator_staking() {
    read -e -p "请输入你之前设置的验证者名称：" MONIKER_NAME
    nibid tx staking create-validator \
    --amount 9500000unibi \
    --commission-max-change-rate "0.1" \
    --commission-max-rate "0.20" \
    --commission-rate "0.1" \
    --min-self-delegation "1" \
    --details "$MONIKER_NAME validator" \
    --pubkey=$(nibid tendermint show-validator) \
    --moniker $MONIKER_NAME \
    --chain-id nibiru-itn-1 \
    --gas-prices 0.025unibi \
    --from "$MONIKER_NAME-key"

}

staking_more_nibi() {
    read -e -p "请输入你的nibi钱包地址：" WALLET_ADDRESS
    nibid tx staking delegate $WALLET_ADDRESS 9800000unibi --chain-id=nibiru-itn-1 --from wallet --fees 5000unibi
}

restart_nibiru_node() {
    nohup nibid start >> /root/.nibid/nibid.log 2>&1 &
    tail -f /root/.nibid/nibid.log
}

echo && echo -e " ${Red_font_prefix}NibiruChain 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装nibiru测试网环境并启动节点 ${Font_color_suffix}
 ${Green_font_prefix} 2.从Faucet获取测试NIBI代币${Font_color_suffix}
 ${Green_font_prefix} 3.创建验证者质押并验证交易${Font_color_suffix}
 ${Green_font_prefix} 4.质押nibiru代币（除开第一次启动节点，之后每次从Faucet获取测试NIBI代币后可以执行一次） ${Font_color_suffix}
 ${Green_font_prefix} 5.重启nibiru节点 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照教程执行以上步骤，请输入数字 [1-5]:" num
case "$num" in
1)
    install_nibiru_node_and_run
    ;;
2)
    request_faucet_nibi
    ;;
3)
    create_validator_staking
    ;;
4)
    staking_more_nibi
    ;;
5)
    restart_nibiru_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
