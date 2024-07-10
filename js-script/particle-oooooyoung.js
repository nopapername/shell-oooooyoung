const { Web3 } = require('web3');
const crypto = require('crypto');

const rpcUrl = "";
const web3 = new Web3(new Web3.providers.HttpProvider(rpcUrl));

const privateKey = "";
const account = web3.eth.accounts.privateKeyToAccount(privateKey);
const accountAddress = account.address;

const sendTransaction = async () => {
  for (let i = 1; i <= 100; i++) {
    const nonce = await web3.eth.getTransactionCount(accountAddress);

    const lines = ['0x973a13e8566E8f12835cc033Ff3B52EA4D152c95'] //可以多加几个转账的地址
    const receiverAddress = lines[crypto.randomInt(0, lines.length)].trim();

    const sum = (Math.random() * (0.0001 - 0.00001) + 0.00001).toFixed(4);
    const amountToSend = web3.utils.toWei(sum.toString(), 'ether');
    const gasPrice = web3.utils.toWei(crypto.randomInt(9, 15).toString(), 'gwei');

    const transaction = {
     nonce: nonce,
     to: receiverAddress,
     value: amountToSend,
     gas: 30000,
     gasPrice: gasPrice,
     chainId: 11155111
    };

    const signedTxn = await web3.eth.accounts.signTransaction(transaction, privateKey);
    const txHash = await web3.eth.sendSignedTransaction(signedTxn.rawTransaction);

    console.log(`交易编号: ${i}`, "交易已发送. 交易哈希:", txHash);

    while (true) {
      await new Promise(resolve => setTimeout(resolve, 5000));
      const txReceipt = await web3.eth.getTransactionReceipt(txHash);
      if (txReceipt) {
        if (txReceipt.status) {
          console.log("交易成功！");
          break;
        } else {
          console.log("交易失败。");
          break;
        }
      } else {
        console.log("交易尚未被包含在区块中。");
      }
    }
  }
};

sendTransaction().catch(console.error);
