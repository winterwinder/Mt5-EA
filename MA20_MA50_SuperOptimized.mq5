//+------------------------------------------------------------------+
//|   MA20/MA50 Super Optimized EA - MT5                             |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>
CTrade trade;

//-------------------- INPUT SETTINGS -------------------------------//
input double Lots          = 0.10;
input int StopLoss         = 300;       // poin
input int TakeProfit       = 300;       // poin
input bool UseTrailingStop = true;
input int TrailingStop     = 150;
input bool UseBreakEven    = true;
input int BreakEvenTrigger = 200;
input int BreakEvenOffset  = 20;
input bool UseTimeFilter   = false;
input int TradeStartHour   = 7;
input int TradeEndHour     = 22;
input bool AntiOvertrade   = true;
input int MinBarsBetweenTrade = 3;

int maFast = 20;
int maSlow = 50;
int lastTradeBar = -10;
int MagicNumber = 123456;

//------------------- CLOSE ALL POSITIONS --------------------------//
void CloseAll()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol)
      {
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         trade.PositionClose(ticket);
      }
   }
}

//------------------- ONTICK FUNCTION -------------------------------//
void OnTick()
{
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);

   // Time filter
   if(UseTimeFilter)
   {
      if(tm.hour < TradeStartHour || tm.hour > TradeEndHour)
         return;
   }

   // MA Calculation
   double fastMA      = iMA(NULL, PERIOD_CURRENT, maFast, 0, MODE_EMA, PRICE_CLOSE, 0);
   double fastMA_prev = iMA(NULL, PERIOD_CURRENT, maFast, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slowMA      = iMA(NULL, PERIOD_CURRENT, maSlow, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowMA_prev = iMA(NULL, PERIOD_CURRENT, maSlow, 0, MODE_EMA, PRICE_CLOSE, 1);

   // Signals
   bool buySignal  = (fastMA_prev < slowMA_prev) && (fastMA > slowMA);
   bool sellSignal = (fastMA_prev > slowMA_prev) && (fastMA < slowMA);

   // Overtrade filter
   if(AntiOvertrade)
   {
      if(lastTradeBar == iBars(NULL, PERIOD_CURRENT)) return;
   }

   // Check open positions
   bool buyOpen  = false;
   bool sellOpen = false;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetSymbol(i)==_Symbol)
      {
         int type = PositionGetInteger(POSITION_TYPE);
         if(type==POSITION_TYPE_BUY) buyOpen=true;
         if(type==POSITION_TYPE_SELL) sellOpen=true;
      }
   }

   // BUY ENTRY
   if(buySignal && !buyOpen)
   {
      if(sellOpen) CloseAll();
      double sl = NormalizeDouble(Ask - StopLoss*_Point, _Digits);
      double tp = NormalizeDouble(Ask + TakeProfit*_Point, _Digits);
      trade.Buy(Lots, _Symbol, Ask, sl, tp, "MA BUY");
      lastTradeBar = iBars(NULL, PERIOD_CURRENT);
   }

   // SELL ENTRY
   if(sellSignal && !sellOpen)
   {
      if(buyOpen) CloseAll();
      double sl = NormalizeDouble(Bid + StopLoss*_Point, _Digits);
      double tp = NormalizeDouble(Bid - TakeProfit*_Point, _Digits);
      trade.Sell(Lots, _Symbol, Bid, sl, tp, "MA SELL");
      lastTradeBar = iBars(NULL, PERIOD_CURRENT);
   }

   // TRAILING STOP & BREAK-EVEN
   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetSymbol(i)==_Symbol)
      {
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         int type = PositionGetInteger(POSITION_TYPE);

         if(type==POSITION_TYPE_BUY)
         {
            double profitPts = (Bid - priceOpen)/_Point;
            if(UseBreakEven && profitPts>=BreakEvenTrigger)
               trade.PositionModify(ticket, priceOpen + BreakEvenOffset*_Point, PositionGetDouble(POSITION_TP));
            if(UseTrailingStop && profitPts>=TrailingStop)
               trade.PositionModify(ticket, Bid - TrailingStop*_Point, PositionGetDouble(POSITION_TP));
         }

         if(type==POSITION_TYPE_SELL)
         {
            double profitPts = (priceOpen - Ask)/_Point;
            if(UseBreakEven && profitPts>=BreakEvenTrigger)
               trade.PositionModify(ticket, priceOpen - BreakEvenOffset*_Point, PositionGetDouble(POSITION_TP));
            if(UseTrailingStop && profitPts>=TrailingStop)
               trade.PositionModify(ticket, Ask + TrailingStop*_Point, PositionGetDouble(POSITION_TP));
         }
      }
   }
}Initial commit: MA20_MA50 Super Optimized EA
//+--------------------Initial commit: MA20_MA50 Super Optimized EA----------------------------------------------+
