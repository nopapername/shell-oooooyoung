// Importing dependencies using 'import' syntax
import got from 'got';
import { HttpsProxyAgent } from 'https-proxy-agent';
import fs from 'fs';
import path from 'path';

// Your existing code...
const concurrency = 5; // 控制并发请求数量
const proxyUrl = ''; // 如果需要代理，设置代理 URL

const baseURL = 'https://api.twitter.com/2/';
const headers = {
    Authorization: 'Bearer AAAAAAAAAAAAAAAAAAAAAFXzAwAAAAAAMHCxpeSDG1gLNLghVe8d74hl6k4%3DRUMF4xAQLsbeBhTSRrCiQpJtxoGWeyHrDb5te2jpGskWDFW82F',
    'User-Agent': 'TwitterAndroid/10.10.0',
};

const accounts = [];

async function generateOne() {
    return new Promise(async (resolve) => {
        const timeout = setTimeout(() => {
            console.log('生成账户超时，继续执行...');
            resolve();
        }, 30000);

        const agent = {
            https: proxyUrl && new HttpsProxyAgent(proxyUrl),
        };

        try {
            const response = await got.post(`${baseURL}oauth2/authorize`, {
                headers,
                agent,
                timeout: {
                    request: 20000,
                },
            });

            const authToken = JSON.parse(response.body).data.token;

            const flowResponse = await got.post(`${baseURL}users/me`, {
                json: {
                    token: authToken,
                },
                headers,
                agent,
                timeout: {
                    request: 20000,
                },
            });

            const userInfo = JSON.parse(flowResponse.body).data;

            if (userInfo) {
                accounts.push({
                    t: userInfo.oauth_token,
                    s: userInfo.oauth_token_secret,
                });
            } else {
                console.log('账户生成失败，无账户信息');
            }
        } catch (error) {
            console.log(`生成账户失败，继续... ${error}`);
        }

        clearTimeout(timeout);
        resolve();
    });
}

(async () => {
    const oldAccounts = fs.readFileSync('/d/develop_tools/dev_project/shell-oooooyoung/js-script/accounts.txt');
    const tokens = oldAccounts.toString().split('\n')[0].split('=')[1].split(',');
    const secrets = oldAccounts.toString().split('\n')[1].split('=')[1].split(',');

    for (let i = 0; i < tokens.length; i++) {
        accounts.push({
            t: tokens[i],
            s: secrets[i],
        });
    }

    for (let i = 0; i < 1000; i++) {
        console.log(`正在生成账户 ${i * concurrency} - ${(i + 1) * concurrency - 1}，总账户数 ${accounts.length}`);

        await Promise.all(Array.from({ length: concurrency }, () => generateOne()));

        fs.writeFileSync(path.join('/d/develop_tools/dev_project/shell-oooooyoung/js-script/accounts.txt'), [
            `TWITTER_OAUTH_TOKEN=${accounts.map((account) => account.t).join(',')}`,
            `TWITTER_OAUTH_TOKEN_SECRET=${accounts.map((account) => account.s).join(',')}`
        ].join('\n'));
    }
})();
