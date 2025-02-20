#!/bin/bash

set -e  # Exit script if any command fails

echo "🔄 更新系统版本..."
# Install needrestart if not installed
sudo apt-get install -y needrestart

# Disable needrestart notifications
sudo sed -i 's/#\$nrconf{restart} =.*/$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf

export NEEDRESTART_MODE=a  # Skip restart service prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y

echo "📦 安装必要的环境依赖..."
sudo apt-get install -y screen curl libssl-dev pkg-config build-essential git-all protobuf-compiler unzip

# Install Protobuf (protoc)
PROTOC_VERSION=29.3
PROTOC_ZIP="protoc-${PROTOC_VERSION}-linux-x86_64.zip"

echo "⬇️ 下载并安装 protoc ${PROTOC_VERSION}..."
cd /usr/local
sudo wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}
sudo unzip -o ${PROTOC_ZIP}
sudo chmod +x /usr/local/bin/protoc

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo "❌ Error: protoc 安装失败, 请检查或自行安装!"
    exit 1
else
    echo "✅ protoc 安装成功，可输入查看版本: $(protoc --version)"
fi

# Install Rust
echo "🦀 安装 Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Add Rust target for riscv32i-unknown-none-elf
echo "🔧 添加 Rust Target: riscv32i-unknown-none-elf"
cd /root/.nexus/network-api/clients/cli && rustup target add riscv32i-unknown-none-elf

echo "✅ 安装完成, 请输入 'screen -S nexus' 启动后台运行"