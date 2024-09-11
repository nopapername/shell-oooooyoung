const {
  Connection,
  Keypair,
  PublicKey,
  Transaction,
  sendAndConfirmTransaction,
} = require('@solana/web3.js');
const {
  getOrCreateAssociatedTokenAccount,
  createTransferInstruction,
} = require('@solana/spl-token');
const bip39 = require('bip39');
const bs58 = require('bs58');
const { derivePath } = require('ed25519-hd-key');

async function main() {
  // Define the cluster you are connecting to
  const connection = new Connection('https://devnet.sonic.game', 'confirmed');

  // Define the mnemonic
  const mnemonic = "coffee length calm problem divide work viable bubble clock believe camera spy";  // Replace with your actual mnemonic

  // Derive the seed from the mnemonic
  const seed = await bip39.mnemonicToSeed(mnemonic);
  
  // Derive the keypair from the seed
  const derivedSeed = derivePath("m/44'/501'/0'/0'", seed.toString('hex')).key;
  const fromWallet = Keypair.fromSeed(derivedSeed);

  // Define the token you want to transfer
  const tokenPublicKey = new PublicKey('So11111111111111111111111111111111111111112');

  // Define the recipient address
  const toAddress = new PublicKey('4xXqpd1qNU5hdZ3VBv3yhfkbtf3JCLGPGemjJwC7Vi5i');

  // Get or create the associated token account of the sender
  const fromTokenAccount = await getOrCreateAssociatedTokenAccount(
    connection,
    fromWallet,
    tokenPublicKey,
    fromWallet.publicKey
  );

  // Get or create the associated token account of the recipient
  const toTokenAccount = await getOrCreateAssociatedTokenAccount(
    connection,
    fromWallet,
    tokenPublicKey,
    toAddress
  );

  // Amount to transfer (in token's smallest unit, e.g., lamports)
  const amount = 1000000; // Change this to the desired amount

  // Number of times to transfer
  const numTransfers = 100;

  for (let i = 0; i < numTransfers; i++) {
    try {
      // Create the transfer transaction
      const transaction = new Transaction().add(
        createTransferInstruction(
          fromTokenAccount.address,
          toTokenAccount.address,
          fromWallet.publicKey,
          amount
        )
      );

      // Send and confirm the transaction
      const signature = await sendAndConfirmTransaction(
        connection,
        transaction,
        [fromWallet]
      );

      console.log(`Transfer ${i + 1}/${numTransfers} confirmed with signature:`, signature);
    } catch (error) {
      console.error(`Transfer ${i + 1} failed:`, error);
    }

    // Delay before the next transfer (optional, adjust as needed)
    await new Promise(resolve => setTimeout(resolve, 60000)); // 60 seconds delay
  }
}

main().catch(err => {
  console.error(err);
});
