// https://docs.analog.one/documentation/developers/analog-watch/developers-guide/utilities/session-key-generator
import "dotenv/config.js";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { build_apikey, new_cert } from "@analog-labs/timegraph-wasm"; // SKG package
import { keygen } from "@analog-labs/timegraph-js"; // Watch Client
import { Keyring } from "@polkadot/keyring";
import { hexToU8a } from "@polkadot/util";
import { waitReady } from "@polkadot/wasm-crypto";

// wallet address must be polkadot/substrate supported. role can be user or developer
const [certificate, secret] = new_cert(
  process.env.WALLET_SUBSTRATE_ADDRESS ??
    "", // 填写波卡地址
  "developer", // role name
);
const keyring = new Keyring({ type: "sr25519" });

waitReady()
  .then(async () => {
    const keypair = keyring.addFromMnemonic(
      process.env.WALLET_SEED ?? "", // 填写analog波卡钱包私钥
    );
    // pass signer and address to get keygen instance
    const _keygen = new keygen({
      signer: keypair.sign,
      address: keypair.address,
    });
    const signedData = keypair.sign(certificate);

    // generate API keys by signing the user certificate with the substrate wallet signer
    // only supported signed data format is U8a
    const data = build_apikey(secret, certificate, signedData);
    // generate session key
    const sessionKey = await _keygen.createSessionkey(30000000000); // one year is 30000000000 ms
    const pathKey = path.join("./.apikeys");
    const appendData = [
      JSON.stringify(data, null, 2),
      JSON.stringify(sessionKey, null, 2),
    ];
    fs.appendFile(pathKey, appendData.join("\n"), function (err) {
      if (err) throw err;
      console.log("success");
    });
  })
  .catch((error) => {
    console.log("error", error);
  });