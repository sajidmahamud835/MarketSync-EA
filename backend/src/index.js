const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true }));

// Storage for account data
let accountData = [];

// Function to determine strategy details
function determineStrategyDetails(strategyType) {
    switch (strategyType) {
        case "short term gain":
            return {
                creationTimestamp: new Date().toISOString(),
                type: 'scalping',
                validity: 3600, // Validity in seconds (1 hour)
                expiryDate: new Date(Date.now() + 3600 * 1000).toISOString(), // Current date + validity
                targetProfit: 1000, // Example value
                maxLoss: 500, // Example value
                maxPing: 100, // Example value (milliseconds)
                maxSlippage: 10, // Example value (points)
                stopLoss: 15, // Example value (pips)
                takeProfit: 50 // Example value (pips)
            };
        case "long term gain":
            return {
                creationTimestamp: new Date().toISOString(),
                type: 'scalping',
                validity: 86400 * 30, // Validity in seconds (30 days)
                expiryDate: new Date(Date.now() + 86400 * 30 * 1000).toISOString(), // Current date + validity
                targetProfit: 5000, // Example value
                maxLoss: 2000, // Example value
                maxPing: 200, // Example value (milliseconds)
                maxSlippage: 20, // Example value (points)
                stopLoss: 30, // Example value (pips)
                takeProfit: 100 // Example value (pips)
            };
        default:
            return {
                creationTimestamp: new Date().toISOString(),
                type: 'scalping',
                validity: 86400 * 30, // Validity in seconds (30 days)
                expiryDate: new Date(Date.now() + 86400 * 30 * 1000).toISOString(), // Current date + validity
                targetProfit: 500, // Example value
                maxLoss: 200, // Example value
                maxPing: 150, // Example value (milliseconds)
                maxSlippage: 15, // Example value (points)
                stopLoss: 10, // Example value (pips)
                takeProfit: 25 // Example value (pips)
            };
    }
}

// Handle sync endpoint for static account data
app.post('/api/sync', (req, res) => {
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
            account_updates: [], // Initialize empty array for dynamic updates
            strategies: [] // Initialize empty array for strategies
        };
        accountData.push(accountEntry);
    } else {
        accountEntry.access_token = accountDataReceived.access_token;
        accountEntry.trading_mode = accountDataReceived.trading_mode;
        accountEntry.max_loss = accountDataReceived.max_loss;
        accountEntry.strategy_type = accountDataReceived.strategy_type;
        accountEntry.account_type = accountDataReceived.account_type;
        accountEntry.account_currency = accountDataReceived.account_currency;
        accountEntry.account_company = accountDataReceived.account_company;
        accountEntry.leverage = accountDataReceived.leverage;
        accountEntry.account_name = accountDataReceived.account_name;
        accountEntry.trade_allowed = accountDataReceived.trade_allowed;
    }

    const strategyDetails = determineStrategyDetails(accountDataReceived.strategy_type);
    accountEntry.strategies.push(strategyDetails);

    return res.json({ strategy: strategyDetails });
});

// Handle sync endpoint for dynamic account data
app.post('/api/sync/:accountNumber', (req, res) => {
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

        return res.json({ message: 'Dynamic data received successfully' });
    } else {
        return res.status(404).json({ error: 'Account not found' });
    }
});

// Handle strategy retrieval endpoint
app.get('/api/strategy/:accountNumber', (req, res) => {
    const accountNumber = req.params.accountNumber;

    const accountEntry = accountData.find(entry => entry.account_number === accountNumber);

    if (accountEntry && accountEntry.strategies.length > 0) {
        const lastStrategy = accountEntry.strategies[accountEntry.strategies.length - 1];
        return res.json({
            strategyType: accountEntry.strategy_type,
            lastStrategy
        });
    } else {
        return res.status(404).json({ error: 'Account not found or no strategy available' });
    }
});

// Handle endpoint for retrieving all account data
app.get('/api/accounts', (req, res) => {
    return res.json({
        count: accountData.length,
        accounts: accountData
    });
});

// Start the server
app.listen(5000, () => {
    console.log('Server is running on port 5000');
});
