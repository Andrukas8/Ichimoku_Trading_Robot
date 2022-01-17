//+------------------------------------------------------------------+
//|                                   AR_Ichimoku_Cloud_Breakout.mq5 |
//|                                                               AR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "AR Ichimoku, uses ATR for SL and TP, has ATR filter"
#property link      ""
#property version   "1.00"

#include <Trade/Trade.mqh>

// Trade inputs
input bool UsePercentRM = true;
input double PercentRisk = 2;

input double FixedLots = 0.1;
input int InpSlPoints = 100;
input int InpTpPoints = 150;

// ATR
input bool UseAtrSlTp = true;
input int AtrMaPeriod = 10;
input double TimesAtr = 1.5;
input double AtrSlTpRRR = 1.5;
input bool UseAtrFilter = true;

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

      CopyBuffer(handleIchimoku,2,-Kijunsen,2,ShiftedSenkouspanAArr);
      CopyBuffer(handleIchimoku,3,-Kijunsen,2,ShiftedSenkouspanBArr);

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

      // % Risk Position Size

      int SlPoints = InpSlPoints;
      int TpPoints = InpTpPoints;

      // % Risk Position Size
      double Lots = FixedLots;

      if(UsePercentRM)
        {
         double AccountBalance = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
         double AmountToRisk = NormalizeDouble(AccountBalance*PercentRisk/100,2);
         double ValuePp = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
         Lots = NormalizeDouble(AmountToRisk/(SlPoints)/ValuePp,2);
         //    Print("Position size in Lots = ",PercentRisk,"% of ",AccountBalance," = ",AmountToRisk," = ",Lots);
        }

      double ValueAtr[];

      // ATR SL TP
      if(UseAtrSlTp)
        {
         static int handleATR = iATR(_Symbol,PERIOD_CURRENT,AtrMaPeriod);

         CopyBuffer(handleATR,0,0,9,ValueAtr);

         int AtrPoints = (int)(ValueAtr[0]/_Point);
         SlPoints = (int)(AtrPoints * TimesAtr);
         TpPoints = (int)(SlPoints * AtrSlTpRRR);
         //Print("UseAtrSlTp = ",UseAtrSlTp,"\nValueAtr[0] = ",ValueAtr[0],"\nAtrPoints = ",AtrPoints,"\nSlPoints = ",SlPoints,"\nTpPoints = ",TpPoints);
        }


      // Indicator Signals

      double Bar26High = iHigh(_Symbol,PERIOD_CURRENT,Kijunsen);
      double Bar26Low = iLow(_Symbol,PERIOD_CURRENT,Kijunsen);

      double CurrentHigh = iHigh(_Symbol,PERIOD_CURRENT,0);
      double CurrentLow = iLow(_Symbol,PERIOD_CURRENT,0);

      Print("\nBar26High = ",Bar26High, "\nBar26Low = ", Bar26Low);


      // ATR trend filter
      bool TrendAtr = true;

      if(UseAtrFilter)
        {
         if((ValueAtr[1] - ValueAtr[8]) >= 0)
           {
            TrendAtr = true;
           }
         else
           {
            TrendAtr = false;
           }
        }


      int Number_of_Positions =  PositionsTotal();

      Print("Bar26High = ",Bar26High);


      // BUY Trades


      // Buy Signal

      if((TenkansenArr[0] > KijunsenArr[0]))
        {
         Print("Buy Cross");
         BuySignal_1 = true; // TK Cross


         if(Number_of_Positions > 0 && SellSignal_1 == true)
           {
            closeAllPositions();
           }

         SellSignal_1 = false; // cancelling sell signal

        }
      else
        {
         BuySignal_1 = false;
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

      if((ShiftedSenkouspanAArr[0] > ShiftedSenkouspanBArr[0]) /* && (SenkouspanAArr[1] < SenkouspanBArr[1]) */)
        {
         BuySignal_3 = true;
         SellSignal_3 = false;
        }

      if(BuySignal_1 && BuySignal_2 && BuySignal_3 && (CurrentHigh > SenkouspanBArr[0]) && (Number_of_Positions == 0))
        {
         BuySignal_GO = true;
         SellSignal_GO = false;
        }


      if(BuySignal_GO)
        {
         BuySignal_1 = BuySignal_2 = BuySignal_3 = BuySignal_GO = false;
         SellSignal_1 = SellSignal_2 = SellSignal_3 = SellSignal_GO = false;

         Print(__FUNCTION__," > Buy signal.");
         Print(BuySignal_1," ",BuySignal_2," ",SellSignal_1," ",SellSignal_2);
         double sl = ask - SlPoints*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double tp = ask + TpPoints*SymbolInfoDouble(_Symbol,SYMBOL_POINT);

         trade.Buy(Lots,_Symbol,ask,sl,tp,"This is a BUY trade");

         Print("KUKU - Buy");


        }


      // SELL trades

      if((TenkansenArr[0] < KijunsenArr[0]))
        {
         Print("Sell Cross");
         SellSignal_1 = true; // KT Cross

         if(Number_of_Positions > 0 && BuySignal_1 == true)
           {
            closeAllPositions();
           }

         BuySignal_1 = false; // cancelling buy signal
        }
      else
        {
         SellSignal_1 = false;
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

      if((ShiftedSenkouspanAArr[0] < ShiftedSenkouspanBArr[0])  /* && (SenkouspanAArr[1] > SenkouspanBArr[1]) */)
        {
         SellSignal_3 = true;
         BuySignal_3 = false;
        }

      if(SellSignal_1 && SellSignal_2 && SellSignal_3 && (CurrentLow < SenkouspanBArr[0]) && (Number_of_Positions == 0))
        {
         SellSignal_GO = true;
         BuySignal_GO = false;
        }


      if(SellSignal_GO)
        {

         SellSignal_1 = SellSignal_2 = SellSignal_3 = SellSignal_GO = false;
         BuySignal_1 = BuySignal_2 = BuySignal_3 = BuySignal_GO = false;

         Print(__FUNCTION__," > Sell signal = ",SellSignal_GO);
         Print(BuySignal_1," ",BuySignal_2," ",SellSignal_1," ",SellSignal_2);
         double sl = bid + SlPoints*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double tp = bid - TpPoints*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         trade.Sell(Lots,_Symbol,bid,sl,tp,"This is a SELL trade");

         Print("KUKU - Sell");

        }

   Print(BuySignal_1," ",BuySignal_2," ",BuySignal_3," ",BuySignal_4," ",BuySignal_GO,"\n",SellSignal_1," ",SellSignal_2," ",SellSignal_3," ",SellSignal_4," ",SellSignal_GO,"\nNumber of Positions = ",Number_of_Positions);


     }


  }
//+------------------------------------------------------------------+
