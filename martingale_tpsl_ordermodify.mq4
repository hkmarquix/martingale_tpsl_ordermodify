//+------------------------------------------------------------------+
//|                                               synceatoserver.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "config.mqh"
#include "TradeInclude\writelog.mqh"
#include "TradeInclude\tradefunction.mqh"
#include "TradeInclude\orderfunction.mqh"
#include "TradeInclude\martingale_ordermodify_controller.mqh"

bool keepsilence = false;

int processOrders = 0;

string curlist_arr[];
int magicnumber_arr[];

int lastprocess_second = -1;

string cache_curmemoryindex[];
string cache_curticketmemory[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
    initCurPair();
    initCurCacheMemory();

   if (IsTesting())
    keepsilence = true;
//---
   return(INIT_SUCCEEDED);
  }
  
  void initCurPair()
  {
      StringSplit(curlist, StringGetCharacter(",", 0), curlist_arr);
      Print(curlist);
      string magicnumber_str_arr[];
      StringSplit(magicnumberlist, StringGetCharacter(",", 0), magicnumber_str_arr);
      Print(magicnumberlist);
      ArrayResize(magicnumber_arr, ArraySize(magicnumber_str_arr), 0);
      for (int i = 0; i < ArraySize(magicnumber_str_arr); i++)
      {
        int tmn = StrToInteger(magicnumber_str_arr[i]);
        magicnumber_arr[i] = tmn;
      }
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    ObjectsDeleteAll();
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    int csec = TimeSeconds(TimeCurrent());
    if (csec == lastprocess_second)
      return;
    if (csec % martingale_check_interval != 0)
      return;
    //Print("Checking...");
    lastprocess_second = csec;

    if (processOrders == 1)
      return;
    processOrders = 1;
    for (int i = 0; i < ArraySize(curlist_arr); i++)
      {
         string cur = curlist_arr[i];
         martingale_order_modify_controller_processcurpair(cur, magicnumber_arr);
      }
    
    processOrders = 0;

  }

void initCurCacheMemory()
{
  int tsize = ArraySize(curlist_arr) * ArraySize(magicnumber_arr) * 2;
  ArrayResize(cache_curmemoryindex, tsize, 0);
  ArrayResize(cache_curticketmemory, tsize, 0);
  Print("Set cache size to : " + tsize);
  int indexi = 0;
  for (int i = 0; i < ArraySize(curlist_arr); i++)
  {
    for (int im = 0; im < ArraySize(magicnumber_arr); im++) {
      string indexkey = martingale_ordermodify_getindexkey(curlist_arr[i], magicnumber_arr[im], OP_BUY);
      cache_curmemoryindex[indexi] = indexkey;
      cache_curticketmemory[indexi] = "";
      indexi++;
      Print("Init " + indexkey);
      indexkey = martingale_ordermodify_getindexkey(curlist_arr[i], magicnumber_arr[im], OP_SELL);
      cache_curmemoryindex[indexi] = indexkey;
      cache_curticketmemory[indexi] = "";
      Print("Init " + indexkey);
      indexi++;
    }
  }
}