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
input string AccessToken = "";
string MaxLoss = "one third of assets";
string StrategyType = "short term gain";
string AccountType = "retail user";

// Strategy Parameters
double lotSize = 0.05;
double stopLossPips = 2;
double takeProfitPips = 7;
int UpdateInterval = 3600;

string ServerURL = "http://localhost:5000/api";
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
    string url = ServerURL + "/dataSync" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
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
        strategy = ParseJson(response, "type", false);
        lotSize = StringToDouble(ParseJson(response, "lotSize", true));
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
    else Print("Unknown strategy type received." + strategy);
}

//+------------------------------------------------------------------+
//| Reversal Trading Strategy                                        |
//+------------------------------------------------------------------+
void ApplyReversalTrading()
{
    int magicNumber = 234567;
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    // Use indicators for signal generation
    int rsiHandle = iRSI(Symbol(), PERIOD_M15, 14, PRICE_CLOSE);
    double rsiValue[];
    CopyBuffer(rsiHandle, 0, 0, 1, rsiValue);
    IndicatorRelease(rsiHandle);

    int macdHandle = iMACD(Symbol(), PERIOD_M15, 12, 26, 9, PRICE_CLOSE);
    double macdMain[], macdSignal[];
    CopyBuffer(macdHandle, 0, 0, 1, macdMain);
    CopyBuffer(macdHandle, 1, 0, 1, macdSignal);
    IndicatorRelease(macdHandle);

    // Logic for Buy/Sell Signals based on Reversal
    if (rsiValue[0] < 30 && macdMain[0] > macdSignal[0])
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_BUY;
        request.price = ask;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = bid - stopLossPips * _Point;
        request.tp = ask + takeProfitPips * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Reversal Buy Order: ", GetLastError());
    }
    else if (rsiValue[0] > 70 && macdMain[0] < macdSignal[0])
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_SELL;
        request.price = bid;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = ask + stopLossPips * _Point;
        request.tp = bid - takeProfitPips * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Reversal Sell Order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Apply Scalping Strategy                                          |
//+------------------------------------------------------------------+
void ApplyScalping()
{
    int magicNumber = 345678;
    double upperBand[], lowerBand[];
    int bandsHandle = iBands(Symbol(), PERIOD_M15, 20, 2, 0, PRICE_CLOSE);
    
    CopyBuffer(bandsHandle, 1, 0, 1, upperBand); // Upper band
    CopyBuffer(bandsHandle, 2, 0, 1, lowerBand); // Lower band
    
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    if (ask > upperBand[0])
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_BUY;
        request.price = ask;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = ask - stopLossPips * _Point;
        request.tp = ask + takeProfitPips * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Scalping Buy Order: ", GetLastError());
    }
    else if (bid < lowerBand[0])
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_SELL;
        request.price = bid;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = bid + stopLossPips * _Point;
        request.tp = bid - takeProfitPips * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Scalping Sell Order: ", GetLastError());
    }

    IndicatorRelease(bandsHandle); // Release the indicator handle
}

//+------------------------------------------------------------------+
//| Apply Breakout Trading Strategy                                  |
//+------------------------------------------------------------------+
void ApplyBreakoutTrading()
{
    int magicNumber = 456789;
    double upperBand[], lowerBand[];
    int bandsHandle = iBands(Symbol(), PERIOD_M15, 20, 2, 0, PRICE_CLOSE);
    
    CopyBuffer(bandsHandle, 1, 0, 1, upperBand); // Upper band
    CopyBuffer(bandsHandle, 2, 0, 1, lowerBand); // Lower band
    
    double atr = iATR(Symbol(), PERIOD_M15, 14);

    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    if (ask > upperBand[0])
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_BUY;
        request.price = ask;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = ask - atr * _Point;
        request.tp = ask + atr * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Breakout Buy Order: ", GetLastError());
    }
    else if (bid < lowerBand[0])
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_SELL;
        request.price = bid;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = bid + atr * _Point;
        request.tp = bid - atr * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Breakout Sell Order: ", GetLastError());
    }

    IndicatorRelease(bandsHandle); // Release the indicator handle
}

//+------------------------------------------------------------------+
//| Apply Momentum Trading Strategy                                  |
//+------------------------------------------------------------------+
void ApplyMomentumTrading()
{
    int magicNumber = 567890;
    double macdMain[], macdSignal[];
    int macdHandle = iMACD(Symbol(), PERIOD_M15, 12, 26, 9, PRICE_CLOSE);
    
    CopyBuffer(macdHandle, 0, 0, 1, macdMain); // MACD main line
    CopyBuffer(macdHandle, 1, 0, 1, macdSignal); // MACD signal line
    IndicatorRelease(macdHandle);

    double rsiValue[];
    int rsiHandle = iRSI(Symbol(), PERIOD_M15, 14, PRICE_CLOSE);
    CopyBuffer(rsiHandle, 0, 0, 1, rsiValue);
    IndicatorRelease(rsiHandle);

    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    if (macdMain[0] > macdSignal[0] && rsiValue[0] > 50)
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_BUY;
        request.price = ask;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = bid - stopLossPips * _Point;
        request.tp = ask + takeProfitPips * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Momentum Buy Order: ", GetLastError());
    }
    else if (macdMain[0] < macdSignal[0] && rsiValue[0] < 50)
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.type = ORDER_TYPE_SELL;
        request.price = bid;
        request.deviation = 10;
        request.magic = magicNumber;
        request.sl = ask + stopLossPips * _Point;
        request.tp = bid - takeProfitPips * _Point;

        if (!OrderSend(request, result))
            Print("Error placing Momentum Sell Order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Apply News-Based Trading Strategy                                |
//+------------------------------------------------------------------+
void ApplyNewsBasedTrading()
{
    int magicNumber = 678901;
    string newsEvent = GetNewsEvent();
    double atr = iATR(Symbol(), PERIOD_M15, 14);

    if (StringLen(newsEvent) > 0)
    {
        double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

        if (newsEvent == "positive")
        {
            MqlTradeRequest request;
            MqlTradeResult result;
            request.action = TRADE_ACTION_DEAL;
            request.symbol = Symbol();
            request.volume = lotSize;
            request.type = ORDER_TYPE_BUY;
            request.price = ask;
            request.deviation = 10;
            request.magic = magicNumber;
            request.sl = ask - atr * _Point;
            request.tp = ask + atr * _Point;

            if (!OrderSend(request, result))
                Print("Error placing News-Based Buy Order: ", GetLastError());
        }
        else if (newsEvent == "negative")
        {
            MqlTradeRequest request;
            MqlTradeResult result;
            request.action = TRADE_ACTION_DEAL;
            request.symbol = Symbol();
            request.volume = lotSize;
            request.type = ORDER_TYPE_SELL;
            request.price = bid;
            request.deviation = 10;
            request.magic = magicNumber;
            request.sl = bid + atr * _Point;
            request.tp = bid - atr * _Point;

            if (!OrderSend(request, result))
                Print("Error placing News-Based Sell Order: ", GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| Determine if the market is trending up using EMA                |
//+------------------------------------------------------------------+
bool IsTrendingUp()
{
    double ema20 = iMA(Symbol(), PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
    double ema50 = iMA(Symbol(), PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
    return ema20 > ema50;
}

//+------------------------------------------------------------------+
//| Determine if the market is trending down using EMA              |
//+------------------------------------------------------------------+
bool IsTrendingDown()
{
    double ema20 = iMA(Symbol(), PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
    double ema50 = iMA(Symbol(), PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
    return ema20 < ema50;
}

//+------------------------------------------------------------------+
//| Get the latest news event from the MetaTrader economic calendar |
//+------------------------------------------------------------------+
string GetNewsEvent()
{
    // Example code: Assume you have a function that fetches news event types
    // Here we'll just simulate it with random choice
    return (MathRand() % 2 == 0) ? "positive" : "negative";
}


//+------------------------------------------------------------------+
//| Parse JSON response                                               |
//+------------------------------------------------------------------+
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
