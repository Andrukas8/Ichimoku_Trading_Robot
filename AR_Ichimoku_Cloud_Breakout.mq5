//+------------------------------------------------------------------+
//|                                   AR_Ichimoku_Cloud_Breakout.mq5 |
//|                                                               AR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "AR Ichimoku, uses ATR filter, TK/KT cross for position close and SenkanspanB for SL"
#property link      ""
#property version   "1.00"

#include <Trade/Trade.mqh>

// Trade inputs
input double PercentRisk = 2;
input double MinSLPoints = 50;
input double RiskToReward = 1.5;
input bool Close_Pos_Kijunsen = true;
input bool Close_Pos_TK_Cross = true;

input bool UseKumoFilter = true;

// ATR
input bool UseAtrFilter = true;
input int AtrMaPeriod = 10;
input int AtrFilterLength = 8;

// ADX
input bool UseAdxFilter = true;
input int AdxMAPeriod = 14;
input int AdxThreshhold = 25;


// Ichimoku inputs
input int Tenkansen = 9;
input int Kijunsen = 26;
input int SenkouspanB = 52;

bool BuySignal_1 = false;
bool BuySignal_2 = false;
bool BuySignal_3 = false;
bool BuySignal_4 = false;
bool BuySignal_GO = false;


bool SellSignal_1 = false;
bool SellSignal_2 = false;
bool SellSignal_3 = false;
bool SellSignal_4 = false;
bool SellSignal_GO = false;

CTrade trade;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---


  }

//+------------------------------------------------------------------+
//| Closing All Positions which are now open                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllPositions()
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong positionticket = PositionGetTicket(i);
      trade.PositionClose(positionticket,-1);
      Print("eliminando posición ",positionticket);

     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   static datetime timeStamp;

   datetime time = iTime(_Symbol,PERIOD_CURRENT,0);

   if(timeStamp != time)
     {
      timeStamp = time;

      static int handleIchimoku = iIchimoku(_Symbol,PERIOD_CURRENT,Tenkansen,Kijunsen,SenkouspanB);

      double TenkansenArr[];
      double KijunsenArr[];
      double SenkouspanAArr[];
      double SenkouspanBArr[];

      double ShiftedSenkouspanAArr[];
      double ShiftedSenkouspanBArr[];

      double ChikouspanArr[];

      CopyBuffer(handleIchimoku,0,0,2,TenkansenArr);
      CopyBuffer(handleIchimoku,1,0,2,KijunsenArr);
      CopyBuffer(handleIchimoku,2,0,2,SenkouspanAArr);
      CopyBuffer(handleIchimoku,3,0,2,SenkouspanBArr);

      CopyBuffer(handleIchimoku,2,-Kijunsen,3,ShiftedSenkouspanAArr);
      CopyBuffer(handleIchimoku,3,-Kijunsen,3,ShiftedSenkouspanBArr);

      CopyBuffer(handleIchimoku,4,Kijunsen,1,ChikouspanArr);

      Comment("\nTenkansen = ",TenkansenArr[0],"\nKijunsen = ",KijunsenArr[0],"\nShiftedSenkouspanA = ",ShiftedSenkouspanAArr[0],"\nSenkouspanB = ",SenkouspanBArr[0],"\nChikouspan = ", ChikouspanArr[0]);

      //--- obtain spread from the symbol properties  --- not used in program
      bool spreadfloat=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD_FLOAT);
      string comm=StringFormat("Spread %s = %I64d points\r\n",
                               spreadfloat?"floating":"fixed",
                               SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));

      //---

      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double last = SymbolInfoDouble(_Symbol,SYMBOL_LAST);


      double sl = SenkouspanBArr[0];
      double ask_tp = ask + RiskToReward * (ask - sl);
      double bid_tp = bid - RiskToReward * (sl - bid);

      int SlPoints = (int)MathCeil(NormalizeDouble(MathAbs(last - sl),_Digits) / _Point);



      if(SlPoints < MinSLPoints)
        {
         Print("Achtung! === Calculated Stop Loss Points Less Then MinSLPoints === ");
        }


      //   Print("SlPoints = ",SlPoints);
      //   Print("sl = ",sl);
      //  Print("SenkouspanAArr[0] = ", SenkouspanAArr[0]);
      //    Print("MathAbs(last - sl) = ",MathAbs(last - sl));
      //   Print("NormalizeDouble(MathAbs(last - sl),_Digits) = ",NormalizeDouble(MathAbs(last - sl),_Digits));
      //  Print("NormalizeDouble(MathAbs(last - sl),_Digits * _Point = ",NormalizeDouble(MathAbs(last - sl),_Digits) / _Point);
      // Print("_Point = ",_Point);


      // % Risk Position Size

      double AccountBalance = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
      double AmountToRisk = NormalizeDouble(AccountBalance*PercentRisk/100,2);
      double ValuePp = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
      double Lots = NormalizeDouble(AmountToRisk/(SlPoints)/ValuePp,2);

      double ValueAtr[];

      Print("SlPoints = ",SlPoints);
      Print("sl = ",sl);
      Print("SenkouspanAArr[0] = ", SenkouspanAArr[0]);

      Print("AccountBalance = ",AccountBalance," AmountToRisk = ",AmountToRisk," ValuePp = ",ValuePp," Lots= ",Lots);


      // Indicator Signals

      double Bar26High = iHigh(_Symbol,PERIOD_CURRENT,Kijunsen);
      double Bar26Low = iLow(_Symbol,PERIOD_CURRENT,Kijunsen);

      double CurrentHigh = iHigh(_Symbol,PERIOD_CURRENT,0);
      double CurrentLow = iLow(_Symbol,PERIOD_CURRENT,0);

      //  Print("Bar26High = ",Bar26High, "\nBar26Low = ", Bar26Low);


      // ATR trend filter
      bool Trend = true;

      bool TrendAtr = true;

      if(UseAtrFilter)
         TrendAtr = false;
        {
         static int handleATR = iATR(_Symbol,PERIOD_CURRENT,AtrMaPeriod);
         CopyBuffer(handleATR,0,0,AtrFilterLength,ValueAtr);
         if((ValueAtr[0] - ValueAtr[AtrFilterLength - 1]) >= 0)
           {
            TrendAtr = true;
           }
         else
           {
            TrendAtr = false;
           }

        }




      // ADX trend filter
      bool TrendAdx = true;
      double ValueAdx[];
      double DIPlus = 0;
      double DIMinus = 0;



      static int handleADX = iADX(_Symbol,PERIOD_CURRENT,AdxMAPeriod);

      CopyBuffer(handleADX,0,0,3,ValueAdx);
      DIPlus = ValueAdx[1];
      DIMinus = ValueAdx[2];


      if(UseAdxFilter)
        {
         TrendAdx = false;
         if((ValueAdx[0] >= AdxThreshhold) && (ValueAdx[0] > ValueAdx[1]))
           {
            TrendAdx = true;
           }
        }


      // Kumo Filter
      bool TrendKumo = true;

      if(UseKumoFilter)
        {
         TrendKumo = false;
         if((MathAbs((ShiftedSenkouspanAArr[0] - ShiftedSenkouspanBArr[0])) > MathAbs((ShiftedSenkouspanAArr[2] - ShiftedSenkouspanBArr[2]))))
           {
            TrendKumo = true;
           }
        }

      // All Trend Filters
      if(TrendAtr && TrendAdx && TrendKumo)
        {
         Trend = true;
        }
      else
        {
         Trend = false;
        }

      Print("TrendAtr = ", TrendAtr," TrendAdx = ", TrendAdx," Trend |====> ", Trend);


      int Number_of_Positions =  PositionsTotal();

      Print("Bar26High = ",Bar26High);

      // Close Position on Kijunsen Cross

      if(
         (
            (Close_Pos_Kijunsen == true) &&
            (last > KijunsenArr[0]) &&
            (SellSignal_1 == true)
         ) ||
         (
            (Close_Pos_Kijunsen == true) &&
            (last < KijunsenArr[0]) &&
            (BuySignal_1 == true))
      )

        {
         Print("Closing Position on Kijunsen = ",Close_Pos_Kijunsen);
         closeAllPositions();
         return;
        }

      // BUY Trades

      // Buy Signal

      if((TenkansenArr[0] > KijunsenArr[0]))
        {
         Print("Buy Cross");
         BuySignal_1 = true; // TK Cross


         if(Close_Pos_TK_Cross && (Number_of_Positions > 0 && SellSignal_1 == true))
           {
            Print("Closing Position on TK/KT Cross = ",Close_Pos_TK_Cross);
            closeAllPositions();
           }

         SellSignal_1 = false; // cancelling sell signal

        }

      if(ChikouspanArr[0] > Bar26High)
        {
         BuySignal_2 = true;
         SellSignal_2 = false;
        }
      else
        {
         BuySignal_2 = false;
        }

      if((ShiftedSenkouspanAArr[0] > ShiftedSenkouspanBArr[0]) && (SenkouspanAArr[0] > SenkouspanBArr[0]))
        {
         BuySignal_3 = true;
         SellSignal_3 = false;
        }

      if(BuySignal_1 && BuySignal_2 && BuySignal_3 && (CurrentHigh > SenkouspanBArr[0]) && (Number_of_Positions == 0))
        {
         BuySignal_GO = true;
         SellSignal_GO = false;
        }

      if(BuySignal_GO && Trend && (SlPoints > MinSLPoints))
        {
         BuySignal_1 = BuySignal_2 = BuySignal_3 = BuySignal_GO = false;
         SellSignal_1 = SellSignal_2 = SellSignal_3 = SellSignal_GO = false;

         Print(__FUNCTION__," > Buy signal ",BuySignal_GO," ATR Trend = ",TrendAtr);
         Print(BuySignal_1," ",BuySignal_2," ",SellSignal_1," ",SellSignal_2);

         trade.Buy(Lots,_Symbol,ask,sl,ask_tp,"This is a BUY trade");

         Print("KUKU - Buy");

        }

      // SELL trades

      if((TenkansenArr[0] < KijunsenArr[0]))
        {
         Print("Sell Cross");
         SellSignal_1 = true; // KT Cross

         if(Close_Pos_TK_Cross && (Number_of_Positions > 0 && BuySignal_1 == true))
           {
            Print("Closing Position on TK/KT Cross = ",Close_Pos_TK_Cross);
            closeAllPositions();
           }

         BuySignal_1 = false; // cancelling buy signal
        }

      if(ChikouspanArr[0] < Bar26Low)
        {
         SellSignal_2 = true;
         BuySignal_2 = false;
        }
      else
        {
         SellSignal_2 = false;
        }

      if((ShiftedSenkouspanAArr[0] < ShiftedSenkouspanBArr[0]) && (SenkouspanAArr[0] < SenkouspanBArr[0]))
        {
         SellSignal_3 = true;
         BuySignal_3 = false;
        }

      if(SellSignal_1 && SellSignal_2 && SellSignal_3 && (CurrentLow < SenkouspanBArr[0]) && (Number_of_Positions == 0))
        {
         SellSignal_GO = true;
         BuySignal_GO = false;
        }

      if(SellSignal_GO && Trend && (SlPoints > MinSLPoints))
        {
         SellSignal_1 = SellSignal_2 = SellSignal_3 = SellSignal_GO = false;
         BuySignal_1 = BuySignal_2 = BuySignal_3 = BuySignal_GO = false;
         Print(__FUNCTION__," > Sell signal ",SellSignal_GO, " ATR Trend = ",TrendAtr);
         Print(BuySignal_1," ",BuySignal_2," ",SellSignal_1," ",SellSignal_2);
         trade.Sell(Lots,_Symbol,bid,sl,bid_tp,"This is a SELL trade");
        }
      Print(BuySignal_1," ",BuySignal_2," ",BuySignal_3," ",BuySignal_4," ",BuySignal_GO,"\n",SellSignal_1," ",SellSignal_2," ",SellSignal_3," ",SellSignal_4," ",SellSignal_GO,"\nNumber of Positions = ",Number_of_Positions);

     }

  }
//+------------------------------------------------------------------+
