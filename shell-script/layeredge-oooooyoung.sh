#!/bin/bash

# LayerEdge 轻节点安装脚本（带交互式菜单），适用于 Ubuntu 24.04.2 LTS
# 此脚本提供菜单驱动界面，用于安装和管理 LayerEdge 轻节点

# 定义颜色代码，便于阅读
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 变量
HOME_DIR=$HOME
LAYEREDGE_DIR="$HOME_DIR/light-node"
ENV_FILE="$LAYEREDGE_DIR/.env"
LOG_DIR="/var/log/layeredge"

# 输出彩色信息函数
print_message() {
    echo -e "${BLUE}[LayerEdge 安装]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查是否以 root 用户运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 用户或 sudo 权限运行此脚本"
        exit 1
    fi
}

# 创建目录
create_directories() {
    mkdir -p $LOG_DIR
    chmod 755 $LOG_DIR
}

# 更新系统并安装基本依赖
update_system() {
    print_message "正在更新系统并安装基本依赖..."
    apt-get update && apt-get upgrade -y
    apt-get install -y build-essential curl wget git pkg-config libssl-dev jq ufw
    print_success "系统更新完成，依赖已安装"
}

# 安装 Go
install_go() {
    print_message "正在安装 Go 1.18+..."
    wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc
    source ~/.bashrc
    rm go1.22.5.linux-amd64.tar.gz
    print_success "Go 安装成功"
}

# 检查是否已安装 Go
check_go() {
    if ! command -v go &>/dev/null; then
        install_go
    else
        go_version=$(go version | awk '{print $3}' | sed 's/go//')
        if [ "$(echo -e "1.18\n$go_version" | sort -V | head -n1)" != "1.18" ]; then
            print_warning "Go 版本低于 1.18，正在更新..."
            install_go
        else
            print_success "已安装 Go 版本 $go_version"
        fi
    fi
}

# 安装 Rust
install_rust() {
    print_message "正在安装 Rust 1.81.0+..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    print_success "Rust 安装成功"
}

# 检查是否已安装 Rust
check_rust() {
    if ! command -v rustc &>/dev/null; then
        install_rust
    else
        rust_version=$(rustc --version | awk '{print $2}')
        if [ "$(echo -e "1.81.0\n$rust_version" | sort -V | head -n1)" != "1.81.0" ]; then
            print_warning "Rust 版本低于 1.81.0，正在更新..."
            rustup update
        else
            print_success "已安装 Rust 版本 $rust_version"
        fi
    fi
}

# 安装 Risc0 工具链
install_risc0() {
    print_message "正在安装 Risc0 工具链..."
    cd $LAYEREDGE_DIR/risc0-merkle-service
    curl -L https://risczero.com/install | bash
    export PATH="$HOME/.risc0/bin:$PATH"
    source "/root/.bashrc"
    print_success "正在安装 rzup 工具链..."
    rzup install
    print_success "Risc0 工具链安装成功"
}

# 克隆 LayerEdge 轻节点仓库
clone_repo() {
    print_message "正在克隆 LayerEdge 轻节点仓库..."
    cd $HOME_DIR
    if [ -d "$LAYEREDGE_DIR" ]; then
        print_warning "目录 'light-node' 已存在，正在更新..."
        cd $LAYEREDGE_DIR
        git pull
    else
        git clone https://github.com/Layer-Edge/light-node.git
        cd $LAYEREDGE_DIR
    fi
    print_success "仓库克隆成功"
}

# 设置环境变量
setup_env() {
    print_message "正在设置环境变量..."

    # 检查 .env 文件是否存在
    if [ -f "$ENV_FILE" ]; then
        print_warning ".env 文件已存在，是否覆盖？(y/n)"
        read -r overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            print_message "保留现有 .env 文件"
            return
        fi
    fi

    # 创建新的 .env 文件
    cat >$ENV_FILE <<EOF
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
EOF

    # 输入私钥
    read -p "请输入 CLI 节点私钥（去掉 '0x' 前缀，或直接回车稍后设置）： " private_key
    if [ ! -z "$private_key" ]; then
        echo "PRIVATE_KEY=$private_key" >>$ENV_FILE
        print_success "私钥已添加"
    else
        print_warning "未设置私钥，请在 .env 文件中手动设置"
    fi

    # 设置正确的权限
    chmod 644 $ENV_FILE
    print_success "环境变量配置完成"
}

# 编译 Risc0 Merkle 服务
build_merkle() {
    print_message "正在编译 Risc0 Merkle 服务..."
    cd $LAYEREDGE_DIR/risc0-merkle-service
    source $HOME/.cargo/env
    cargo build
    print_success "Merkle 服务编译成功"
}

# 编译轻节点程序
build_node() {
    print_message "正在编译 LayerEdge 轻节点..."
    cd $LAYEREDGE_DIR
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
    source /etc/profile
    go build
    print_success "轻节点编译成功"
}

# 创建 systemd 服务
create_services() {
    print_message "正在创建 Merkle 服务的 systemd 服务..."
    cat >/etc/systemd/system/layeredge-merkle.service <<EOF
[Unit]
Description=LayerEdge Merkle 服务
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$LAYEREDGE_DIR/risc0-merkle-service
ExecStart=$HOME/.cargo/bin/cargo run
Restart=on-failure
RestartSec=10
StandardOutput=append:$LOG_DIR/merkle.log
StandardError=append:$LOG_DIR/merkle-error.log

[Install]
WantedBy=multi-user.target
EOF

    print_message "正在创建轻节点的 systemd 服务..."
    cat >/etc/systemd/system/layeredge-node.service <<EOF
[Unit]
Description=LayerEdge 轻节点
After=layeredge-merkle.service
Requires=layeredge-merkle.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$LAYEREDGE_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$LAYEREDGE_DIR/light-node
Restart=on-failure
RestartSec=10
StandardOutput=append:$LOG_DIR/node.log
StandardError=append:$LOG_DIR/node-error.log

[Install]
WantedBy=multi-user.target
EOF

    # 设置正确权限
    chmod 644 /etc/systemd/system/layeredge-merkle.service
    chmod 644 /etc/systemd/system/layeredge-node.service
    print_success "systemd 服务创建完成"
}

# 配置防火墙
setup_firewall() {
    print_message "正在配置防火墙..."
    ufw allow 22/tcp
    ufw allow 3001/tcp
    ufw allow 8080/tcp
    ufw --force enable
    print_success "防火墙配置完成"
}

# 启用并启动服务
start_services() {
    print_message "正在启用并启动服务..."
    systemctl daemon-reload
    systemctl enable layeredge-merkle.service
    systemctl enable layeredge-node.service
    systemctl start layeredge-merkle.service
    print_message "等待 Merkle 服务初始化（30秒）..."
    sleep 30
    systemctl start layeredge-node.service

    # 检查服务状态
    if systemctl is-active --quiet layeredge-merkle.service; then
        print_success "Merkle 服务正在运行"
    else
        print_error "Merkle 服务启动失败，请使用：journalctl -u layeredge-merkle.service 查看日志"
    fi

    if systemctl is-active --quiet layeredge-node.service; then
        print_success "轻节点正在运行"
    else
        print_error "轻节点启动失败，请使用：journalctl -u layeredge-node.service 查看日志"
    fi
}

# 停止服务
stop_services() {
    print_message "正在停止 LayerEdge 服务..."
    systemctl stop layeredge-node.service
    systemctl stop layeredge-merkle.service
    print_success "服务已停止"
}

# 创建状态检查脚本
create_status_script() {
    print_message "正在创建状态检查脚本..."
    cat >$HOME_DIR/check-layeredge-status.sh <<EOF
#!/bin/bash

echo "===== LayerEdge 服务状态 ====="
systemctl status layeredge-merkle.service | grep "Active:"
systemctl status layeredge-node.service | grep "Active:"

echo -e "\n===== Merkle 日志最近10行 ====="
tail -n 10 $LOG_DIR/merkle.log

echo -e "\n===== 轻节点日志最近10行 ====="
tail -n 10 $LOG_DIR/node.log

echo -e "\n===== 错误日志最近10行 ====="
tail -n 10 $LOG_DIR/merkle-error.log
tail -n 10 $LOG_DIR/node-error.log
EOF

    chmod +x $HOME_DIR/check-layeredge-status.sh
    print_success "状态检查脚本已创建：$HOME_DIR/check-layeredge-status.sh"
}

# 查看日志
view_logs() {
    echo -e "\n${CYAN}可查看的日志文件：${NC}"
    echo "1) Merkle 服务日志"
    echo "2) 轻节点日志"
    echo "3) Merkle 错误日志"
    echo "4) 轻节点错误日志"
    echo "5) 返回主菜单"

    read -p "请选择要查看的日志编号： " log_choice

    case $log_choice in
    1) less $LOG_DIR/merkle.log ;;
    2) less $LOG_DIR/node.log ;;
    3) less $LOG_DIR/merkle-error.log ;;
    4) less $LOG_DIR/node-error.log ;;
    5) return ;;
    *) print_error "无效的选择" ;;
    esac
}

# 检查节点状态
check_status() {
    $HOME_DIR/check-layeredge-status.sh
}

# 查看服务状态
view_service_status() {
    echo -e "\n${CYAN}服务状态：${NC}"
    echo "1) Merkle 服务状态"
    echo "2) 轻节点服务状态"
    echo "3) 返回主菜单"

    read -p "请选择服务编号： " service_choice

    case $service_choice in
    1) systemctl status layeredge-merkle.service ;;
    2) systemctl status layeredge-node.service ;;
    3) return ;;
    *) print_error "无效的选择" ;;
    esac
}

# 更新私钥
update_private_key() {
    read -p "请输入新的 CLI 节点私钥（去掉 '0x' 前缀）： " new_private_key

    if [ -f "$ENV_FILE" ]; then
        # 检查 .env 中是否已存在 PRIVATE_KEY
        if grep -q "PRIVATE_KEY" "$ENV_FILE"; then
            # 替换已存在的 PRIVATE_KEY
            sed -i "s/PRIVATE_KEY=.*/PRIVATE_KEY=$new_private_key/" $ENV_FILE
        else
            # 添加新的 PRIVATE_KEY
            echo "PRIVATE_KEY=$new_private_key" >>$ENV_FILE
        fi
        print_success "私钥更新成功"

        # 重启轻节点服务以应用更改
        print_message "正在重启轻节点服务..."
        systemctl restart layeredge-node.service
    else
        print_error "未找到 .env 文件，请先执行安装设置"
    fi
}

# 仪表盘连接信息
show_dashboard_info() {
    echo -e "\n${CYAN}======= LayerEdge 仪表盘连接信息 =======${NC}"
    echo "1. 访问 dashboard.layeredge.io"
    echo "2. 连接你的钱包"
    echo "3. 绑定你的 CLI 节点公钥"
    echo "4. 查询积分："
    echo "   https://light-node.layeredge.io/api/cli-node/points/{你的钱包地址}"
    echo -e "${CYAN}============================================${NC}"

    read -p "按回车键继续..."
}

# 完整安装流程
install_full() {
    check_root
    create_directories
    update_system
    check_go
    check_rust
    clone_repo
    setup_env
    install_risc0
    build_merkle
    build_node
    create_services
    setup_firewall
    create_status_script
    start_services

    print_message "============================================"
    print_success "LayerEdge 轻节点完整安装已完成！"
    print_message "============================================"
    $LAYEREDGE_DIR/light-node
    read -p "按回车键继续..."
}

# 显示横幅
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║               LayerEdge 轻节点管理器                     ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 主菜单
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}安装选项：${NC}"
        echo "1) 完整安装"
        echo "2) 更新仓库"
        echo "3) 编译/重新编译服务"
        echo ""
        echo -e "${CYAN}服务管理：${NC}"
        echo "4) 启动服务"
        echo "5) 停止服务"
        echo "6) 重启服务"
        echo "7) 查看服务状态"
        echo ""
        echo -e "${CYAN}监控与配置：${NC}"
        echo "8) 检查节点状态"
        echo "9) 查看日志"
        echo "10) 更新私钥"
        echo "11) 仪表盘连接信息"
        echo ""
        echo "12) 退出"
        echo ""
        read -p "请输入选项编号： " choice

        case $choice in
        1) install_full ;;
        2)
            check_root
            clone_repo
            read -p "按回车键继续..."
            ;;
        3)
            check_root
            build_merkle
            build_node
            read -p "按回车键继续..."
            ;;
        4)
            check_root
            start_services
            read -p "按回车键继续..."
            ;;
        5)
            check_root
            stop_services
            read -p "按回车键继续..."
            ;;
        6)
            check_root
            stop_services
            start_services
            read -p "按回车键继续..."
            ;;
        7)
            check_root
            view_service_status
            ;;
        8)
            check_status
            read -p "按回车键继续..."
            ;;
        9)
            view_logs
            ;;
        10)
            check_root
            update_private_key
            read -p "按回车键继续..."
            ;;
        11)
            show_dashboard_info
            ;;
        12)
            echo "正在退出 LayerEdge 轻节点管理器，再见！"
            exit 0
            ;;
        *)
            print_error "无效选项，请重试。"
            read -p "按回车键继续..."
            ;;
        esac
    done
}

# 执行主菜单
main_menu
