const getCryptoPrice = require('crypto-price-checker-oooooyoung');

(async () => {
  try {
    const tokenPrice = await getCryptoPrice('BTC');
    console.log(tokenPrice);
  } catch (error) {
    console.error(error);
  }
})();