//+------------------------------------------------------------------+
//|                                                   MarketSync.mq5 |
//|                                           Copyright 2024, Sajid. |
//|                    https://www.mql5.com/en/users/sajidmahamud835 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Sajid."
#property link      "https://www.mql5.com/en/users/sajidmahamud835"
#property version   "1.00"

// Inputs
input string TradingMode = "moderate";
input string AccessToken = "your_access_token";
input string MaxLoss = "one third of assets";
input string StrategyType = "short term gain";
input string AccountType = "retail user";

string ServerURL = "http://localhost:5000/api";
int UpdateInterval = 3600;
double lotSize = 0.01;
double stopLossPips = 15;
double takeProfitPips = 50;
datetime LastUpdateTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    LastUpdateTime = TimeCurrent();
    SendAccountInfo(); // Send static account information once
    DataSync();        // Send the first update of dynamic data
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if (TimeCurrent() - LastUpdateTime >= UpdateInterval)
    {
        DataSync(); // Send updated data at intervals
        LastUpdateTime = TimeCurrent();
    }

    string strategy = GetStrategyFromServer();
    if (StringLen(strategy) > 0)
    {
        ExecuteStrategy(strategy);
    }
}

//+------------------------------------------------------------------+
//| Send static account information via HTTP POST                    |
//+------------------------------------------------------------------+
void SendAccountInfo()
{
    string url = ServerURL + "/sync";
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    string postData = "access_token=" + AccessToken + 
                      "&trading_mode=" + TradingMode + 
                      "&max_loss=" + MaxLoss + 
                      "&strategy_type=" + StrategyType + 
                      "&account_type=" + AccountType + 
                      "&account_currency=" + AccountInfoString(ACCOUNT_CURRENCY) + 
                      "&account_company=" + AccountInfoString(ACCOUNT_COMPANY) + 
                      "&leverage=" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE)) +
                      "&account_name=" + AccountInfoString(ACCOUNT_NAME) +
                      "&account_number=" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)) +
                      "&trade_allowed=" + IntegerToString((int)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED));

    char data[];
    StringToCharArray(postData, data);
    char result[];
    string responseHeaders;
    int res = WebRequest("POST", url, headers, 5000, data, result, responseHeaders);

    if (res == -1)
    {
        Print("WebRequest failed, error: ", GetLastError());
    }
    else
    {
        Print("Static account information sent successfully.");
    }
}

//+------------------------------------------------------------------+
//| Send frequently updated account information                      |
//+------------------------------------------------------------------+
void DataSync()
{
    string url = ServerURL + "/dataSync"+IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    string postData = "access_token=" + AccessToken + 
                      "&account_number=" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)) +
                      "&balance=" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) +
                      "&equity=" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) +
                      "&margin=" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2) +
                      "&free_margin=" + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2) +
                      "&margin_level=" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2) +
                      "&profit=" + DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT), 2);

    char data[];
    StringToCharArray(postData, data);
    char result[];
    string responseHeaders;
    int res = WebRequest("POST", url, headers, 5000, data, result, responseHeaders);

    if (res == -1)
    {
        Print("WebRequest failed, error: ", GetLastError());
    }
    else
    {
        Print("Dynamic account information sent successfully.");
    }
}

//+------------------------------------------------------------------+
//| Get strategy and settings from the server                        |
//+------------------------------------------------------------------+
string GetStrategyFromServer()
{
    char postData[];
    char result[];
    string responseHeaders;
    string headers = "Authorization: Bearer " + AccessToken + "\r\nContent-Type: application/json";
    int res = WebRequest("GET", ServerURL + "/strategy/" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)), headers, 5000, postData, result, responseHeaders);
    string strategy;
    if (res >= 0)
    {
        string response = CharArrayToString(result);
        
        // Parse the JSON response to get the strategy and other parameters
        strategy = ParseJson(response, "type");
        lotSize = StringToDouble(ParseJson(response, "lotSize", true));
        Print("Lot Size: ", lotSize);
        stopLossPips = StringToDouble(ParseJson(response, "stopLoss", true));
        takeProfitPips = StringToDouble(ParseJson(response, "takeProfit", true));
        
        return strategy;
    }
    else
    {
        Print("Error receiving strategy and settings from server: ", GetLastError());
        return "";
    }
}

//+------------------------------------------------------------------+
//| Execute the trading strategy                                     |
//+------------------------------------------------------------------+
void ExecuteStrategy(string strategy)
{
    if (strategy == "reversal") ApplyReversalTrading();
    else if (strategy == "scalping") ApplyScalping();
    else if (strategy == "breakout") ApplyBreakoutTrading();
    else if (strategy == "momentum") ApplyMomentumTrading();
    else if (strategy == "news") ApplyNewsBasedTrading();
    else Print("Unknown strategy type received.");
}

//+------------------------------------------------------------------+
//| Strategy implementations                                         |
//+------------------------------------------------------------------+
void ApplyReversalTrading() { /* Implementation of Reversal Trading */ }
void ApplyBreakoutTrading() { /* Implementation of Breakout Trading */ }
void ApplyMomentumTrading() { /* Implementation of Momentum Trading */ }
void ApplyNewsBasedTrading() { /* Implementation of News-Based Trading */ }

//+------------------------------------------------------------------+
//| Scalping strategy                                                |
//+------------------------------------------------------------------+
void ApplyScalping()
{
    int magicNumber = 123456;
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double slLevel = ask - (stopLossPips * _Point);
    double tpLevel = ask + (takeProfitPips * _Point);

    MqlTradeRequest request;
    MqlTradeResult result;
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = lotSize;
    request.deviation = 10;
    request.magic = magicNumber;

    if (IsTrendingUp())
    {
        request.type = ORDER_TYPE_BUY;
        request.price = ask;
        request.sl = slLevel;
        request.tp = tpLevel;
        if (!OrderSend(request, result))
            Print("Error placing Scalping Buy Order: ", GetLastError());
    }
    else if (IsTrendingDown())
    {
        request.type = ORDER_TYPE_SELL;
        request.price = bid;
        request.sl = bid + (stopLossPips * _Point);
        request.tp = bid - (takeProfitPips * _Point);
        if (!OrderSend(request, result))
            Print("Error placing Scalping Sell Order: ", GetLastError());
    }
}

string ParseJson(const string &json, const string &key, bool isNumeric = false)
{
    int keyIndex = StringFind(json, "\"" + key + "\":");
    if (keyIndex == -1) return "";

    int valueStart = keyIndex + StringLen(key) + 3;
    
    if (!isNumeric)
    {
        if (StringGetCharacter(json, valueStart) == '\"')
        {
            valueStart++;
            int valueEnd = StringFind(json, "\"", valueStart);
            if (valueEnd == -1) return "";
            return StringSubstr(json, valueStart, valueEnd - valueStart);
        }
    }
    else
    {
        int valueEnd = StringFind(json, ",", valueStart);
        if (valueEnd == -1) valueEnd = StringFind(json, "}", valueStart);
        if (valueEnd == -1) return "";

        return StringSubstr(json, valueStart, valueEnd - valueStart);
    }

    return "";
}


//+------------------------------------------------------------------+
//| Determine if the market is trending up                           |
//+------------------------------------------------------------------+
bool IsTrendingUp()
{
    int handleShort = iMA(Symbol(), PERIOD_M1, 10, 0, MODE_EMA, PRICE_CLOSE);
    int handleLong = iMA(Symbol(), PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
    if (handleShort == INVALID_HANDLE || handleLong == INVALID_HANDLE)
    {
        Print("Failed to create EMA indicator handle");
        return false;
    }

    double shortEMA[], longEMA[];
    CopyBuffer(handleShort, 0, 0, 1, shortEMA);
    CopyBuffer(handleLong, 0, 0, 1, longEMA);
    IndicatorRelease(handleShort);
    IndicatorRelease(handleLong);

    return shortEMA[0] > longEMA[0];
}

//+------------------------------------------------------------------+
//| Determine if the market is trending down                         |
//+------------------------------------------------------------------+
bool IsTrendingDown()
{
    int handleShort = iMA(Symbol(), PERIOD_M1, 10, 0, MODE_EMA, PRICE_CLOSE);
    int handleLong = iMA(Symbol(), PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
    if (handleShort == INVALID_HANDLE || handleLong == INVALID_HANDLE)
    {
        Print("Failed to create EMA indicator handle");
        return false;
    }

    double shortEMA[], longEMA[];
    CopyBuffer(handleShort, 0, 0, 1, shortEMA);
    CopyBuffer(handleLong, 0, 0, 1, longEMA);
    IndicatorRelease(handleShort);
    IndicatorRelease(handleLong);

    return shortEMA[0] < longEMA[0];
}
