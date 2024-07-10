from web3 import Web3
from web3.middleware import geth_poa_middleware
from eth_account import Account
import threading
import time
import random
from colorama import init, Fore

# 启用未经审计的 HD 钱包功能（可选，根据您的使用情况）
Account.enable_unaudited_hdwallet_features()

# 检查发送者余额的函数
def check_balance(address):
    balance = web3.eth.get_balance(address)
    return balance

# 初始化 Web3 和其他组件
rpc_url = ""
web3 = Web3(Web3.HTTPProvider(rpc_url))
web3.middleware_onion.inject(geth_poa_middleware, layer=0)

# 从文件中读取私钥
private_key = ""

try:
    # 根据私钥创建账户对象
    sender_account = Account.from_key(private_key)
    sender_address = sender_account.address

    # 初始化交易计数
    transaction_count = 0

    # 显示带颜色的积分和捐赠消息
    print(Fore.GREEN + "===================================================")
    print(Fore.GREEN + "                BOT Pioneer Particle")
    print(Fore.GREEN + "===================================================")
    print(Fore.YELLOW + " 开发者: JerryM")
    print(Fore.YELLOW + " 支持者: WIMIX")
    print(Fore.GREEN + "===================================================")
    print(Fore.CYAN + f" 捐赠:{Fore.WHITE}0x6Fc6Ea113f38b7c90FF735A9e70AE24674E75D54")
    print(Fore.GREEN + "===================================================")
    print()

    # 开始交易前检查发送者的余额
    sender_balance = check_balance(sender_address)

    # 如果余额为零或小于交易成本，则通知并退出
    if sender_balance <= 0:
        print(Fore.RED + "BOT 停止。余额不足或无法执行交易。")
    else:
        # 启动线程实时打印余额
        def print_sender_balance():
            while True:
                sender_balance = check_balance(sender_address)
                if sender_balance <= 0:
                    print(Fore.RED + "余额不足或无法执行交易。")
                    break
                time.sleep(5)  # 每5秒更新一次

        balance_thread = threading.Thread(target=print_sender_balance, daemon=True)
        balance_thread.start()

        # 循环发送100笔交易
        for i in range(1, 101):
            # 获取发送者地址的最新nonce
            nonce = web3.eth.get_transaction_count(sender_address)

            # 生成一个新的随机接收者账户
            receiver_address = "0x973a13e8566E8f12835cc033Ff3B52EA4D152c95"

            # 发送的以太币金额（随机在0.00001和0.0001 ETH之间）
            amount_to_send = random.uniform(0.00001, 0.0001)

            # 将金额转换为wei并保留正确的精度
            amount_to_send_wei = int(web3.to_wei(amount_to_send, 'ether'))

            # gas价格以gwei为单位（随机在9到15之间）
            gas_price_gwei = random.uniform(9, 15)
            gas_price_wei = web3.to_wei(gas_price_gwei, 'gwei')

            # 准备交易
            transaction = {
                'nonce': nonce,
                'to': receiver_address,
                'value': amount_to_send_wei,
                'gas': 21000,  # 常规交易的燃气限制
                'gasPrice': gas_price_wei,
                'chainId': 11155111  # 主网链ID
            }

            # 使用发送者的私钥对交易进行签名
            signed_txn = web3.eth.account.sign_transaction(transaction, private_key)

            # 发送交易
            tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)

            # 发送后立即打印交易详情
            print(Fore.WHITE + "交易哈希:", Fore.WHITE + web3.to_hex(tx_hash))
            print(Fore.WHITE + "发送者地址:", Fore.GREEN + sender_address)
            print(Fore.WHITE + "接收者地址:", receiver_address)

            # 增加交易计数
            transaction_count += 1

            # 等待15秒后再检查交易状态
            time.sleep(15)

            # 如果未找到交易收据，则重试5次，每次间隔10秒
            retry_count = 0
            while retry_count < 5:
                try:
                    tx_receipt = web3.eth.get_transaction_receipt(tx_hash)
                    if tx_receipt is not None:
                        if tx_receipt['status'] == 1:
                            print(Fore.GREEN + "交易成功")
                            break
                        else:
                            print(Fore.RED + "交易失败")
                            break
                    else:
                        print(Fore.YELLOW + "交易仍在等待中。正在重试...")
                        retry_count += 1
                        time.sleep(10)
                except Exception as e:
                    print(Fore.RED + f"检查交易状态时出错: {str(e)}")
                    retry_count += 1
                    time.sleep(10)

            print()  # 打印空行进行分隔

            # 如果已发送101笔交易，则退出循环
            if transaction_count >= 101:
                break

    # 完成发送交易或因余额不足停止
    print(Fore.GREEN + "结束。")
    print(Fore.WHITE + "发送者地址:", Fore.GREEN + sender_address)

except ValueError:
    print(Fore.RED + "输入的私钥无效。请确保私钥格式正确：0x.......")
