extern double martingale_takeProfitAveragePips = 25; // TakeProfitPips, 0 means disbale ::: << this will set TP for each order
extern double martingale_startTrailingAveragePips = 15; // pips for trigger trailing mechanism, 0 means disbale ::: << this will set TP for each order
extern double martingale_stoplossTrailingPips = 5; // StopLossPips, 0 means disbale ::: << this will set SL for each order

extern int martingale_check_interval = 1; // checking interval, 1 means check all orders every 1 second
extern int enable_profit_trailing = 1; // enable profit trailing? 0 means disable, 1 means enable

string EA_NAME = "martin_tpsl_om";

extern string curlist = "EURUSD,XAUUSD"; // it can be :  XAUUSD,EURUSD,USDJPY
extern string magicnumberlist = "18291,0";

double lastbuystoploss = 0;
double lastsellstoploss = 0;