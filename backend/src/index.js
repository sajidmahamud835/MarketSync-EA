const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true }));

let accountData = [];

async function getStrategyDetailsFromChatGPT(accountDataReceived) {
    const strategies = ["reversal", "scalping", "breakout", "momentum", "news"];
    const strategy = strategies[Math.floor(Math.random() * strategies.length)];
    const messages = [
        {
            role: "system",
            content: "You are an AI assistant that provides trading strategies based on predefined parameters. Respond only in the specified JSON format."
        },
        {
            role: "user",
            content: `
                {
                    "strategy_type": "${strategy}",
                    "account_number": "${accountDataReceived.account_number}",
                    "trading_mode": "${accountDataReceived.trading_mode}",
                    "max_loss": ${accountDataReceived.max_loss},
                    "account_type": "${accountDataReceived.account_type}",
                    "account_currency": "${accountDataReceived.account_currency}",
                    "account_company": "${accountDataReceived.account_company}",
                    "leverage": ${accountDataReceived.leverage},
                    "account_name": "${accountDataReceived.account_name}",
                    "trade_allowed": ${accountDataReceived.trade_allowed}
                }

                Please respond in the following JSON format:
                {
                    "creationTimestamp": "string (ISO 8601 format)",
                    "type": "string",
                    "validity": "number (seconds)",
                    "expiryDate": "string (ISO 8601 format)",
                    "targetProfit": "number",
                    "maxLoss": "number",
                    "maxPing": "number (milliseconds)",
                    "maxSlippage": "number (points)",
                    "lotSize": "number",
                    "stopLoss": "number (pips)",
                    "takeProfit": "number (pips)"
                }
            `
        }
    ];

    try {
        const response = await tradeGPT({
            model: "trade-gpt",
            messages,
            temperature: 0.7,
            max_tokens: 150,
            top_p: 1.0,
            frequency_penalty: 0.0,
            presence_penalty: 0.0
        });

        return response.choices[0].message.content;

    } catch (error) {
        console.error('Error fetching strategy details from ChatGPT:', error);
        throw new Error('Failed to retrieve strategy details');
    }
}

app.post('/api/sync', async (req, res) => {
    const accountDataReceived = req.body;

    if (!accountDataReceived?.account_number || typeof accountDataReceived.account_number !== 'string' ||
        !accountDataReceived?.strategy_type || typeof accountDataReceived.strategy_type !== 'string') {
        return res.status(400).json({ error: 'Invalid data received' });
    }

    let accountEntry = accountData.find(entry => entry.account_number === accountDataReceived.account_number);
    if (!accountEntry) {
        accountEntry = {
            account_number: accountDataReceived.account_number,
            access_token: accountDataReceived.access_token,
            trading_mode: accountDataReceived.trading_mode,
            max_loss: accountDataReceived.max_loss,
            strategy_type: accountDataReceived.strategy_type,
            account_type: accountDataReceived.account_type,
            account_currency: accountDataReceived.account_currency,
            account_company: accountDataReceived.account_company,
            leverage: accountDataReceived.leverage,
            account_name: accountDataReceived.account_name,
            trade_allowed: accountDataReceived.trade_allowed,
            account_updates: [],
            strategies: []
        };
        accountData.push(accountEntry);
    } else {
        Object.assign(accountEntry, accountDataReceived);
    }

    try {
        const strategyDetails = await getStrategyDetailsFromChatGPT(accountDataReceived);
        accountEntry.strategies.push(JSON.parse(strategyDetails));

        return res.json({ strategy: JSON.parse(strategyDetails) });

    } catch (error) {
        return res.status(500).json({ error: 'Failed to retrieve strategy details' });
    }
});

app.post('/api/dataSync/:accountNumber', async (req, res) => {
    const accountNumber = req.params.accountNumber;
    const dynamicDataReceived = req.body;
    const receivedTime = new Date().toISOString();

    if (!dynamicDataReceived?.balance || !dynamicDataReceived?.equity ||
        !dynamicDataReceived?.margin || !dynamicDataReceived?.free_margin ||
        !dynamicDataReceived?.margin_level || !dynamicDataReceived?.profit) {
        return res.status(400).json({ error: 'Invalid dynamic data received' });
    }

    let accountEntry = accountData.find(entry => entry.account_number === accountNumber);

    if (accountEntry) {
        accountEntry.account_updates.push({
            time: receivedTime,
            balance: dynamicDataReceived.balance,
            equity: dynamicDataReceived.equity,
            margin: dynamicDataReceived.margin,
            free_margin: dynamicDataReceived.free_margin,
            margin_level: dynamicDataReceived.margin_level,
            profit: dynamicDataReceived.profit
        });


        const strategyDetails = await getStrategyDetailsFromChatGPT(accountDataReceived);
        accountEntry.strategies.push(JSON.parse(strategyDetails));

        return res.json({ message: 'Dynamic data received successfully' });
    } else {
        return res.status(404).json({ error: 'Account not found' });
    }
});

app.get('/api/strategy/:accountNumber', (req, res) => {
    const accountNumber = req.params.accountNumber;

    const accountEntry = accountData.find(entry => entry.account_number === accountNumber);

    if (accountEntry && accountEntry.strategies.length > 0) {
        const lastStrategy = accountEntry.strategies[accountEntry.strategies.length - 1];
        return res.json({ strategyType: accountEntry.strategy_type, lastStrategy });
    } else {
        return res.status(404).json({ error: 'Account not found or no strategy available' });
    }
});

app.get('/api/accounts', (req, res) => {
    return res.json({ count: accountData.length, accounts: accountData });
});

app.listen(5000, () => {
    console.log('Server is running on port 5000');
});

async function tradeGPT({ model, messages, temperature, max_tokens, top_p, frequency_penalty, presence_penalty }) {
    const strategyTypeMatch = messages.find(msg => msg.role === "user").content.match(/"strategy_type": "(.*?)"/);
    const strategyType = strategyTypeMatch ? strategyTypeMatch[1] : "scalping";

    const equityOrBalance = 10000;
    let lotSize = 0.1;

    let mockResponse = {
        creationTimestamp: new Date().toISOString(),
        type: strategyType,
        validity: 3600,
        expiryDate: new Date(Date.now() + 3600000).toISOString()
    };

    switch (strategyType) {
        case "reversal":
            mockResponse.targetProfit = Math.random() * 0.05 * equityOrBalance + 0.01 * equityOrBalance;
            mockResponse.maxLoss = Math.random() * 0.03 * equityOrBalance + 0.01 * equityOrBalance;
            mockResponse.stopLoss = Math.floor(Math.random() * 40 + 20);
            mockResponse.takeProfit = Math.floor(Math.random() * 100 + 50);
            lotSize = 0.02;
            break;
        case "scalping":
            mockResponse.targetProfit = Math.random() * 0.01 * equityOrBalance + 0.005 * equityOrBalance;
            mockResponse.maxLoss = Math.random() * 0.01 * equityOrBalance + 0.002 * equityOrBalance;
            mockResponse.stopLoss = Math.floor(Math.random() * 20 + 10);
            mockResponse.takeProfit = Math.floor(Math.random() * 30 + 15);
            lotSize = 0.05;
            break;
        case "breakout":
            mockResponse.targetProfit = Math.random() * 0.10 * equityOrBalance + 0.03 * equityOrBalance;
            mockResponse.maxLoss = Math.random() * 0.05 * equityOrBalance + 0.02 * equityOrBalance;
            mockResponse.stopLoss = Math.floor(Math.random() * 60 + 30);
            mockResponse.takeProfit = Math.floor(Math.random() * 120 + 60);
            lotSize = 0.1;
            break;
        case "momentum":
            mockResponse.targetProfit = Math.random() * 0.07 * equityOrBalance + 0.02 * equityOrBalance;
            mockResponse.maxLoss = Math.random() * 0.04 * equityOrBalance + 0.01 * equityOrBalance;
            mockResponse.stopLoss = Math.floor(Math.random() * 50 + 25);
            mockResponse.takeProfit = Math.floor(Math.random() * 100 + 50);
            lotSize = 0.07;
            break;
        case "news":
            mockResponse.targetProfit = Math.random() * 0.15 * equityOrBalance + 0.05 * equityOrBalance;
            mockResponse.maxLoss = Math.random() * 0.08 * equityOrBalance + 0.03 * equityOrBalance;
            mockResponse.stopLoss = Math.floor(Math.random() * 70 + 35);
            mockResponse.takeProfit = Math.floor(Math.random() * 140 + 70);
            lotSize = 0.15;
            break;
        default:
            mockResponse.targetProfit = Math.random() * 1000 + 500;
            mockResponse.maxLoss = Math.random() * 500 + 100;
            mockResponse.stopLoss = Math.floor(Math.random() * 40 + 20);
            mockResponse.takeProfit = Math.floor(Math.random() * 100 + 50);
            break;
    }

    mockResponse.lotSize = lotSize;
    mockResponse.maxPing = Math.floor(Math.random() * 200 + 100);
    mockResponse.maxSlippage = Math.floor(Math.random() * 10 + 5);

    return { choices: [{ message: { content: JSON.stringify(mockResponse) } }] };
}
