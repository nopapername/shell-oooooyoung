// ==UserScript==
// @name         backpack-oooooyoung
// @namespace    http://tampermonkey.net/
// @version      v1.1
// @description  oooooyoung's backpack trade script
// @author       oooooyoung
// @match        https://backpack.exchange/trade/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// @license MIT
// ==/UserScript==

// 请使用在浏览器控制台里

const MIN_WAIT_MS = 300;
const MAX_WAIT_MS = 1000;
const MIN_SWITCH_MS = 500;
const MAX_SWITCH_MS = 3000;

let tradeCount = 0;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const findElementsByText = (text, tag) => {
  const elements = document.querySelectorAll(tag);
  return Array.from(elements).filter((div) => div.textContent === text);
};

const clickElementByText = async (text, tag) => {
  const [element] = findElementsByText(text, tag);
  if (!element) {
    const [cnElement] = findElementsByText(getChineseText(text), tag);
    if (cnElement) {
      cnElement.click();
      await sleep(getRandomWait(MIN_WAIT_MS, MAX_WAIT_MS));
    }
  } else {
    element.click();
    await sleep(getRandomWait(MIN_WAIT_MS, MAX_WAIT_MS));
  }
};

const executeTrade = async (type) => {
  await clickElementByText(type, "p");
  await clickElementByText("Market", "div");
  await clickElementByText("Max", "div");
  await clickElementByText(type, "button");
};

const getRandomWait = (min, max) => Math.floor(Math.random() * max + min);

const performTradeCycle = async () => {
  try {
    tradeCount++;
    console.log(`开始第${tradeCount}次买`);
    await executeTrade("Buy");
    await sleep(getRandomWait(MIN_SWITCH_MS, MAX_SWITCH_MS));
    console.log(`开始第${tradeCount}次卖`);
    await executeTrade("Sell");
    await sleep(getRandomWait(MIN_SWITCH_MS, MAX_SWITCH_MS));
  } catch (error) {
    console.error("发生错误:", error);
  }
};

const startTrading = async () => {
  await sleep(3000);
  while (true) {
    await performTradeCycle();
  }
};

(function () {
  "use strict";
  startTrading();
})();

function getChineseText(text) {
  switch (text) {
    case "Market":
      return "市场";
    case "Max":
      return "最大";
    case "Buy":
      return "购买";
    case "Sell":
      return "出售";
    default:
      return text;
  }
}