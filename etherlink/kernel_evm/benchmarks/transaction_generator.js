const { sign } = require("./scripts/lib/signature");
const ethers = require("ethers");
const fs = require("fs");
const external = require("./scripts/lib/external");
const CHUNKER = external.bin("./octez-evm-node");
const { execSync } = require("child_process");
const yaml = require("js-yaml");

function gen_accounts(n) {
    let accounts = [];
    for (var i = 0; i < n; i++) {
        let wallet = ethers.Wallet.createRandom();
        accounts.push({ address: wallet.address, privateKey: wallet.privateKey });
    }
    return accounts;
}

function readJsonFile(filename) {
    return new Promise((resolve, reject) => {
        fs.readFile(filename, "utf8", (err, data) => {
            if (err) {
                reject(err);
                return;
            }

            const jsonData = JSON.parse(data);
            resolve(jsonData);
        });
    });
}

async function sendOracleTxs(endpoint, oraclePrivateKey, accountsFile) {
    console.log(
        "endpoint",
        endpoint,
        "with pk",
        oraclePrivateKey,
        "and account file",
        accountsFile,
    );
    const provider = new ethers.providers.JsonRpcProvider(endpoint);
    const faucetWallet = new ethers.Wallet(oraclePrivateKey, provider);
    let faucetNonce = 0;
    console.log("Faucet is", faucetWallet.address, "with nonce", faucetNonce);
    let accounts = await readJsonFile(accountsFile);
    //     const gasPrice = (await provider.getGasPrice())._hex;
    const gasPrice = 0x5208;
    let transactionPromises = accounts.map(async (account) => {
        let tx = {
            to: account.address,
            value: 1,
            chainId: 1337,
            nonce: faucetNonce,
            gasPrice,
        };
        const signedTx = await faucetWallet.signTransaction(tx);
        faucetNonce++;
        return provider.sendTransaction(signedTx);
    });

    try {
        const transactionResponses = await Promise.allSettled(transactionPromises);

        transactionResponses.forEach((result, index) => {
            if (result.status === "fulfilled") {
            } else {
                const reason = result.reason;
                console.error(
                    `Transaction ${index + 1} failed with error: ${reason.message}`,
                );
            }
        });
    } catch (error) {
        console.error("Error sending transactions:", error.message);
    }
}

async function sendTxs(endpoint, accountsFile, nonce, to) {
    const provider = new ethers.providers.JsonRpcProvider(endpoint);
    //     const gasPrice = (await provider.getGasPrice())._hex;
    const gasPrice = 0x5208;
    let accounts = await readJsonFile(accountsFile);
    let transactionPromises = accounts.map(async (account) => {
        const wallet = new ethers.Wallet(account.privateKey, provider);
        let tx = {
            to,
            value: 1,
            chainId: 1337,
            nonce,
            gasPrice,
        };
        const signedTx = await wallet.signTransaction(tx);
        return provider.sendTransaction(signedTx);
    });

    try {
        const transactionResponses = await Promise.allSettled(transactionPromises);

        transactionResponses.forEach((result, index) => {
            if (result.status === "fulfilled") {
                const response = result.value;
            } else {
                const reason = result.reason;
                console.error(
                    `Transaction ${index + 1} failed with error: ${reason.message}`,
                );
            }
        });
    } catch (error) {
        console.error("Error sending transactions:", error.message);
    }
}

var args = process.argv.slice(2);

if (args[0] == "gen_accounts") {
    let n = args[1];
    let output = args[2];
    let accounts = gen_accounts(n);
    fs.writeFile(output, JSON.stringify(accounts), (err) => {
        if (err) {
            console.error(err);
            return;
        }
        console.log("Accounts written to " + output);
    });
} else if (args[0] == "gen_transactions") {
    let accountsFile = args[1];
    let sr1 = args[2];
    let nonce = args[3];
    let to =
        args.length < 4 ? "0x6ce4d79d4E77402e1ef3417Fdda433aA744C6e1c" : args[4];
    readJsonFile(accountsFile).then((accounts) => {
        let transactions = [];
        accounts.forEach((account) => {
            let tx = {
                nonce: parseInt(nonce).toString(16),
                gasPrice: 100,
                gasLimit: 21000,
                to: to,
                value: 1,
                data: "",
                chainId: 1337,
                v: 1,
                r: 0,
                s: 0,
            };
            let rawTx = sign(tx, account.privateKey);
            run_chunker_command = `${CHUNKER} chunk data "${rawTx.rawTx}" --rollup-address ${sr1}`;
            chunked_message = new Buffer.from(
                execSync(run_chunker_command),
            ).toString();
            transactions.push(chunked_message.split("\n").slice(1, -1));
        });
        console.log(transactions.flat());
    });
} else if (args[0] == "spam_transactions") {
    const endpoint = args[1];
    let accountsFile = args[2];
    let nonce = args[3];
    let to = "0x6ce4d79d4E77402e1ef3417Fdda433aA744C6e1c";
    sendTxs(endpoint, accountsFile, parseInt(nonce), to);
} else if (args[0] == "spam_oracle_transactions") {
    const endpoint = args[1];
    const oraclePrivateKey = args[2];
    let accountsFile = args[3];
    sendOracleTxs(endpoint, oraclePrivateKey, accountsFile);
} else if (args[0] == "gen_config") {
    let accountsFile = args[1];
    let output = args[2];
    readJsonFile(accountsFile).then((accounts) => {
        let instrs = [];
        accounts.forEach((account) => {
            let addr = account.address.toLowerCase().slice(2);
            instrs.push({
                set: {
                    value:
                        "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
                    to: `/evm/eth_accounts/${addr}/balance`,
                },
            });
        });
        let config = { instructions: instrs };

        fs.writeFile(output, yaml.dump(config), (err) => {
            if (err) {
                console.error(err);
                return;
            }
            console.log("Config written to " + output);
        });
    });
} else {
    console.log(`command inexistant`);
}
