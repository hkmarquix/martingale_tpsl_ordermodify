//+------------------------------------------------------------------+
//|                                               synceatoserver.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


void martingale_order_modify_controller_processcurpair(string _cur, int &magicnumber_arr[])
{
    for (int i = 0; i < ArraySize(magicnumber_arr); i++)
    {
      int tmagicnumber = magicnumber_arr[i];
      martingale_order_modify_controller_processcurpair(_cur, tmagicnumber, OP_BUY);
      martingale_order_modify_controller_processcurpair(_cur, tmagicnumber, OP_SELL);
    }
}

void martingale_order_modify_controller_processcurpair(string _cur, int _magicnumber, int _ordertype)
{
  if (enable_profit_trailing == 1)
  {
    martingale_order_modify_calTrailingProfitOnAllOrders(_cur, _magicnumber, _ordertype);
  }
  else {
    martingale_order_modify_checkCacheandCalTakeProfitonallOrders(_cur, _magicnumber, _ordertype);
  }
}

void martingale_order_modify_checkCacheandCalTakeProfitonallOrders(string _cur, int _magicnumber, int _ordertype)
{
   string indexkey = martingale_ordermodify_getindexkey(_cur, _magicnumber, _ordertype);
    //Print("Start order modify method for " + indexkey);
    string ncachememory = martingale_ordermodify_buildindex(_cur, _magicnumber, _ordertype);
    int loci = martingale_order_modify_findcachelocation(indexkey);
    if (loci > -1)
    {
      string oldmemory = cache_curticketmemory[loci];
      if (oldmemory == ncachememory)
        return;
    }
    cache_curticketmemory[loci] = ncachememory;
    martingale_order_modify_calTakeProfitOnAllOrders(_cur, _magicnumber, _ordertype);
}

string martingale_ordermodify_getindexkey(string _cur, int _magicnumber, int _ordertype)
{
  string indexkey = StringFormat("%s_%d_%d_%f_", _cur, _magicnumber, _ordertype, martingale_takeProfitAveragePips);
  return indexkey;
}

string martingale_ordermodify_buildindex(string _cur, int _magicnumber, int _ordertype)
{
  string cachememory = martingale_ordermodify_getindexkey(_cur, _magicnumber, _ordertype);
  for (int i = 0; i < OrdersTotal(); i++)
  {
    OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
    if (OrderSymbol() != _cur)
      continue;
    if (OrderMagicNumber() != _magicnumber)
      continue;
    if (OrderType() != _ordertype)
      continue;

    cachememory += OrderTicket();
  }
  return cachememory;
}

int martingale_order_modify_findcachelocation(string indexkey)
{
  for (int i = 0; i < ArraySize(cache_curmemoryindex); i++)
  {
    string tcache = cache_curmemoryindex[i];
    if (tcache == indexkey) {
      return i;
    }
  }
  return -1;
}

void martingale_order_modify_calTakeProfitOnAllOrders(string _symbol, int _magicnumber, int _ordertype)
{
    if (martingale_takeProfitAveragePips <= 0)
        return;
    if (!of_selectlastorder(_symbol, _magicnumber, _ordertype))
        return;
    //martingale_targetProfitTotalPips
    double averageopenprice = tf_averageOpenPrice(_symbol, _magicnumber, _ordertype);
    if (averageopenprice == 0)
    {
        Print("Invalid average open price");
        return;
    }
    double closeprice = 0;
    double newprice = 0;
    if (OrderType() == OP_BUY)
    {
        closeprice = MarketInfo(_symbol, MODE_BID);
        newprice = averageopenprice + martingale_takeProfitAveragePips * 10 / (double)tf_getCurrencryMultipier(_symbol);
    }
    else if (OrderType() == OP_SELL)
    {
        closeprice = MarketInfo(_symbol, MODE_ASK);
        newprice = averageopenprice - martingale_takeProfitAveragePips * 10 / (double)tf_getCurrencryMultipier(_symbol);
    }

    tf_setTakeProfitStopLoss(_symbol, _ordertype, _magicnumber, 0, newprice);
    Print("Order modified..." + OrderTicket());
}


void martingale_order_modify_calTrailingProfitOnAllOrders(string _symbol, int _magicnumber, int _ordertype)
{
    if (martingale_takeProfitAveragePips <= 0)
        return;
    if (!of_selectlastorder(_symbol, _magicnumber, _ordertype))
        return;
    if (OrderProfit() < 0) {
      martingale_order_modify_calTakeProfitOnAllOrders(_symbol, _magicnumber, _ordertype);
      return;
    }
    double averageopenprice = tf_averageOpenPrice(_symbol, _magicnumber, _ordertype);
    if (averageopenprice == 0)
    {
        Print("Invalid average open price");
        return;
    }
    double closeprice = 0;
    double newprice = 0;
    double trailingstoploss = 0;
    if (OrderType() == OP_BUY)
    {
        closeprice = MarketInfo(_symbol, MODE_BID);
        newprice = averageopenprice + martingale_startTrailingAveragePips * 10 / (double)tf_getCurrencryMultipier(_symbol);

        if (closeprice > newprice)
        {
          trailingstoploss = closeprice - martingale_stoplossTrailingPips * 10 / (double)tf_getCurrencryMultipier(_symbol);
        }
    }
    else if (OrderType() == OP_SELL)
    {
        closeprice = MarketInfo(_symbol, MODE_ASK);
        newprice = averageopenprice - martingale_startTrailingAveragePips * 10 / (double)tf_getCurrencryMultipier(_symbol);

        if (closeprice < newprice)
        {
          trailingstoploss = closeprice + martingale_stoplossTrailingPips * 10 / (double)tf_getCurrencryMultipier(_symbol);
        }
    }

    if (trailingstoploss > 0)
      tf_setTakeProfitStopLoss(_symbol, _ordertype, _magicnumber, trailingstoploss, 0);
    else
      martingale_order_modify_checkCacheandCalTakeProfitonallOrders(_symbol, _magicnumber, _ordertype);

}
