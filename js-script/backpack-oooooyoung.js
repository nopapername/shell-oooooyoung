// ==UserScript==
// @name         backpack-oooooyoung
// @namespace    http://tampermonkey.net/
// @version      2024-03-25
// @description  oooooyoung's backpack trade script
// @author       oooooyoung
// @match        https://backpack.exchange/trade/SOL_USDC
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// ==/UserScript==

// 请使用在浏览器控制台里

const MIN_WAIT_MS = 100;
const MAX_WAIT_MS = 1000;
const MIN_SWITCH_MS = 500;
const MAX_SWITCH_MS = 3000;

let tradeCount = 0;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const findElementsByText = (text, tag, index) => {
  const elements = document.querySelectorAll(tag);
  return Array.from(elements).filter((div) => div.textContent === text);
};

const clickElementByText = async (text, tag, index) => {
  const [element] = findElementsByText(text, tag, index);
  if (element) {
    element.click();
    await sleep(getRandomWait(MIN_WAIT_MS, MAX_WAIT_MS));
  }
};

const executeTrade = async (type) => {
  await clickElementByText(type, "p", 0);
  await clickElementByText("Market", "div", 0);
  await clickElementByText("Max", "div", 0);
  await clickElementByText(type, "button", 0);
};

const getRandomWait = (min, max) => Math.floor(Math.random() * (max - min + 1) + min);

const performTradeCycle = async () => {
  try {
    tradeCount++;
    console.log(`开始第${tradeCount}次买卖交易`);
    await sleep(getRandomWait(MIN_SWITCH_MS, MAX_SWITCH_MS));
    await executeTrade("Buy");
    await sleep(getRandomWait(MIN_SWITCH_MS, MAX_SWITCH_MS));
    console.log(`开始第${tradeCount}次卖卖交易`);
    await executeTrade("Sell");
  } catch (error) {
    console.error("发生错误:", error);
  }
};

const startTrading = async () => {
  while (true) {
    await performTradeCycle();
  }
};

(function () {
  "use strict";
  startTrading();
})();
