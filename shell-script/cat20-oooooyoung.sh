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

install_env_and_full_node() {
    check_root
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make docker.io postgresql-client -y
    VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
    DESTINATION=/usr/local/bin/docker-compose
    sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
    sudo chmod 755 $DESTINATION

    sudo apt-get install npm -y
    sudo npm install n -g
    sudo n stable
    sudo npm i -g yarn

    git clone https://github.com/CATProtocol/cat-token-box
    cd cat-token-box
    sudo yarn install
    sudo yarn build

    MAX_CPUS=$(nproc)
    MAX_MEMORY=$(free -m | awk '/Mem:/ {print int($2*0.8)"M"}')

    cd ./packages/tracker/
    sudo chmod 777 docker/data
    sudo chmod 777 docker/pgdata
    sudo docker-compose up -d

    cd ../../
    sudo docker build -t tracker:latest .
    BASE_URL="http://88.99.70.27:41187/"
    FILES=$(curl -s $BASE_URL | grep -oP 'dump_file_\d+\.sql')
    LATEST_FILE=$(echo "$FILES" | sort -V | tail -n 1)
    echo "Downloading the latest file: $LATEST_FILE"
    curl -O "$BASE_URL$LATEST_FILE"
    export PGPASSWORD='postgres'
    psql -h 127.0.0.1 -U postgres -d postgres -f "$LATEST_FILE"
    unset PGPASSWORD

    sudo docker run -d \
        --name tracker \
        --cpus="$MAX_CPUS" \
        --memory="$MAX_MEMORY" \
        --add-host="host.docker.internal:host-gateway" \
        -e DATABASE_HOST="host.docker.internal" \
        -e RPC_HOST="host.docker.internal" \
        -p 3000:3000 \
        tracker:latest
    echo '{
      "network": "fractal-mainnet",
      "tracker": "http://127.0.0.1:3000",
      "dataDir": ".",
      "maxFeeRate": 30,
      "rpc": {
          "url": "http://127.0.0.1:8332",
          "username": "bitcoin",
          "password": "opcatAwesome"
      }
    }' > ~/cat-token-box/packages/cli/config.json
}

create_wallet() {
  echo -e "\n"
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet create
  echo -e "\n"
  sudo yarn cli wallet address
  echo -e "请保存上面创建好的钱包地址、助记词"
}

start_mint_cat() {
  # Prompt for token ID
  read -p "请输入要 mint 的 tokenId: " tokenId

  # Prompt for gas (maxFeeRate)
  read -p "请设定要 mint 的 gas: " newMaxFeeRate
  sed -i "s/\"maxFeeRate\": [0-9]*/\"maxFeeRate\": $newMaxFeeRate/" ~/cat-token-box/packages/cli/config.json

  # Prompt for amount to mint
  read -p "请输入要 mint 的数量: " amount

  cd ~/cat-token-box/packages/cli

  # Update the mint command with tokenId and amount
  command="sudo yarn cli mint -i $tokenId $amount"

  # Run the minting loop
  while true; do
      $command

      if [ $? -ne 0 ]; then
          echo "命令执行失败，退出循环"
          exit 1
      fi

      sleep 1
  done
}

check_node_log() {
  docker logs -f --tail 100 tracker
}

check_wallet_balance() {
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet balances
}

send_token() {
  read -p "请输入tokenId (不是代币名字): " tokenId
  read -p "请输入接收地址: " receiver
  read -p "请输入转账数量: " amount
  cd ~/cat-token-box/packages/cli
  sudo yarn cli send -i $tokenId $receiver $amount
  if [ $? -eq 0 ]; then
      echo -e "${Info} 转账成功"
  else
      echo -e "${Error} 转账失败，请检查信息后重试"
  fi
}


echo && echo -e " ${Red_font_prefix}dusk_network 一键安装脚本${Font_color_suffix} by \033[1;35moooooyoung\033[0m
此脚本完全免费开源, 由推特用户 ${Green_font_prefix}@ouyoung11开发${Font_color_suffix}, 
欢迎关注, 如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装依赖环境和全节点 ${Font_color_suffix}
 ${Green_font_prefix} 2.创建钱包 ${Font_color_suffix}
 ${Green_font_prefix} 3.查看钱包余额情况 ${Font_color_suffix}
 ${Green_font_prefix} 4.开始 mint cat20 代币 ${Font_color_suffix}
 ${Green_font_prefix} 5.查看节点同步日志 ${Font_color_suffix}
 ${Green_font_prefix} 6.转账 cat20 代币 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请参照上面的步骤，请输入数字:" num
case "$num" in
1)
    install_env_and_full_node
    ;;
2)
    create_wallet
    ;;
3)
    check_wallet_balance
    ;;
4)
    start_mint_cat
    ;;
5)
    check_node_log
    ;;
6)
    send_token
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
