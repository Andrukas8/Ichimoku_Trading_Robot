//+------------------------------------------------------------------+
//|                                               ControlsButton.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Control Panels and Dialogs. Demonstration class CButton"

#include <Trade/Trade.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>
sinput string ______________1 = ""; // ------------- Position Variables ----------------------------
input string posLotsDef = "0.1"; // Lot size
input string slPipsDef = "10"; // Stoploss in pips
input string RiskToRewardDef = "2"; // Risk to Reward Ratio

sinput string ______________2  = ""; // ------------- Auto Position Management Controls ------------
input bool autoBreakEven = false; // Auto Break Even
input bool pointsTSL = true; // Regular Trailing SL in points
input bool fractalsTSL = false; // Fractal Trailing SL
input bool movingAverageTSL = false; // Moving Average Trailing SL
input bool tenkansenTSL = false; // Ichimoku Kijunsen Line Trailing SL
input bool kijunsenTSL = false; // Ichimoku Kijunsen Line Trailing SL


sinput string ______________3 = ""; // ------------- Auto Position Management Settings -------------
input int TslOffsetPoints = 10; // Points Above/Below the MA
input int TslPoints = 50; // Points for Regular TSL
input ENUM_TIMEFRAMES TimeFrame = 1; // Time frame
input double breakevenRatio = 1; // Break Even Ratio
input int MaPeriod = 8; // MA Period
input int MaShift = 5; // MA Shift
input ENUM_MA_METHOD TslMaMethod = MODE_SMMA; // MA Method
input ENUM_APPLIED_PRICE TslMaAppPrice = PRICE_MEDIAN; // MA Price

int barsTotal;

double mainUpper = 0;
double mainLower = 0;

double mainUpperFractal = 0;
double mainLowerFractal = 0;

int maShift;

int handleFractal;
int handleMA;
int handleIchimoku;

string text;

struct StopLoss
  {
   ulong             posTicketArr;
   double            posSlArr;
  };

StopLoss originalPosSlArr[];

double ask;
double bid;

double tpBuy;
double tpSell;

double slSell;
double slBuy;

double posLots; // Lot size
double slPips; // Stoploss in pips
double RiskToReward; // Risk to Reward Ratio
bool lineInput = false; // show lines for graphical input
bool pendingToggle = false; // toggle between market and pending order types
bool sellToggle = false;
bool buyToggle = false;
bool stopToggle = false;
bool limitToggle = false;
bool autoPosMgmtToggle = false;

double inputStopLoss;
double inputTakeProfit;
double inputPrice;
double calcSlPips;
double calcTpPips;
double calcRRR;

double linePriceNew;
double lineSlNew;
double lineTpNew;

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (11)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (11)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (11)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (11)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (3)       // gap by X coordinate
#define CONTROLS_GAP_Y                      (3)       // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH                        (100)     // size by X coordinate
#define BUTTON_HEIGHT                       (20)      // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT                         (20)      // size by Y coordinate
#define EDIT_WIDTH                          (70)      // size by X coordinate
#define EDIT_WIDTH_SMALL                    (40)      // size by X coordinate
//--- for group controls
#define GROUP_WIDTH                         (150)     // size by X coordinate
#define LIST_HEIGHT                         (179)     // size by Y coordinate
#define RADIO_HEIGHT                        (56)      // size by Y coordinate
#define CHECK_HEIGHT                        (93)      // size by Y coordinate

//+------------------------------------------------------------------+
//| Class CControlsDialog                                            |
//| Usage: main dialog of the Controls application                   |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
  {
private:
   // Labels
   CLabel            m_LotsLbl;                       // Label for Lots
   CLabel            m_SlPipsLbl;                     // Label for Lots
   CLabel            m_RiskToRewardRatioLbl;          // Label for Risk to Reward Ratio
   CLabel            m_RiskLbl;                       // Label for Risk percentage
   CLabel            m_TpPipsLbl;                     // Label for Take Profit price level
   CLabel            m_PriceLbl;                      // Label for Price for pending orders
   CLabel            m_SlLbl;
   CLabel            m_TpLbl;

   // Edits
   CEdit             m_LotsEdit;                      // Edit field for the lots
   CEdit             m_SlPipsEdit;                    // Edit field for the sl pips
   CEdit             m_RiskToRewardRatioEdit;         // Edit field for Risk to Reward Ratio
   CEdit             m_RiskEdit;                      // Edit field for Risk percentage
   CEdit             m_TpPipsEdit;                    // Edit field for Risk percentage\
   CEdit             m_PriceEdit;                     // Edit field for Risk percentage
   CEdit             m_SlEdit;                        // Edit field for Risk percentage
   CEdit             m_TpEdit;                        // Edit field for Risk percentage

   // Buttons
   CButton           m_SellBtn;                       // button to sell
   CButton           m_BuyBtn;                        // button to buy
   CButton           m_CloseAllBtn;                   // button to close all positions
   CButton           m_CalculatePosBtn;               // button to calculate lot size based on % of deposit to risk
   CButton           m_ClearInputsBtn;                // button to clear the input fields
   CButton           m_BreakEvenBtn;                  // button to break even all traded on the current chart
   CButton           m_MarketPendingBtn;              // Button to toggle between market and pending orders
   CButton           m_ShowLinesBtn;                  // Button to show price sl and tp prices for order placing
   CButton           m_SellToggleBtn;
   CButton           m_BuyToggleBtn;
   CButton           m_SendOrderBtn;
   CButton           m_StopToggleBtn;
   CButton           m_LimitToggleBtn;
   CButton           m_AutoPosMgmtToggleBtn;
   CButton           m_DoubleOrderBtn;
   CButton           m_DrawPositionsBtn;

public:
                     CControlsDialog(void);
                    ~CControlsDialog(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

protected:
   //--- create dependent controls
   bool              CreateSellBtn(void);
   bool              CreateBuyBtn(void);
   bool              CreateCloseAllBtn(void);
   bool              CreateCalculatePosBtn(void);
   bool              CreateClearInputsBtn(void);
   bool              CreateBreakEvenBtn(void);
   bool              CreateMarketPendingBtn(void);
   bool              CreateShowLinesBtn(void);
   bool              CreateSellToggleBtn(void);
   bool              CreateBuyToggleBtn(void);
   bool              CreateSendOrderBtn(void);
   bool              CreateStopToggleBtn(void);
   bool              CreateLimitToggleBtn(void);
   bool              CreateAutoPosMgmtToggleBtn(void);
   bool              CreateDoubleOrderBtn(void);
   bool              CreateDrawPositionsBtn(void);

   bool              CreateLotsEdit(void);
   bool              CreateSlPipsEdit(void);
   bool              CreateRiskToRewardRatioEdit(void);
   bool              CreateRiskEdit(void);
   bool              CreateTpPipsEdit(void);
   bool              CreatePriceEdit(void);
   bool              CreateSlEdit(void);
   bool              CreateTpEdit(void);

   bool              CreateLotsLbl(void);
   bool              CreateSlPipsLbl(void);
   bool              CreateRiskToRewardRatioLbl(void);
   bool              CreateRiskLbl(void);
   bool              CreateTpPipsLbl(void);
   bool              CreatePriceLbl(void);
   bool              CreateSlLbl(void);
   bool              CreateTpLbl(void);

   // -- Auxilary functions
   bool              GetOrderData(void);
   bool              GetDataFromLines(void);
   bool              MarketSellOrder(void);
   bool              MarketBuyOrder(void);
   bool              PendingSellStopOrder(void);
   bool              PendingSellLimitOrder(void);
   bool              PendingBuyStopOrder(void);
   bool              PendingBuyLimitOrder(void);
   bool              MarketSellDoubleOrder(void);
   bool              MarketBuyDoubleOrder(void);
   bool              PendingSellStopDoubleOrder(void);
   bool              PendingSellLimitDoubleOrder(void);
   bool              PendingBuyStopDoubleOrder(void);
   bool              PendingBuyLimitDoubleOrder(void);
   bool              CalculatePosition(void);


   //--- handlers of the dependent controls events
   void              OnClickSellBtn(void);
   void              OnClickBuyBtn(void);
   void              OnClickCloseAllBtn(void);
   void              OnClickCalculatePosBtn(void);
   void              OnClickClearInputsBtn(void);
   void              OnClickBreakEvenBtn(void);
   void              OnClickMarketPendingBtn(void);
   void              OnClickShowLinesBtn(void);
   void              OnClickSellToggleBtn(void);
   void              OnClickBuyToggleBtn(void);
   void              OnClickSendOrderBtn(void);
   void              OnClickStopToggleBtn(void);
   void              OnClickLimitToggleBtn(void);
   void              OnClickAutoPosMgmtToggleBtn(void);
   void              OnClickDoubleOrderBtn(void);
   void              OnClickDrawPositionsBtn(void);

  };
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CControlsDialog)
ON_EVENT(ON_CLICK,m_SellBtn,OnClickSellBtn)
ON_EVENT(ON_CLICK,m_BuyBtn,OnClickBuyBtn)
ON_EVENT(ON_CLICK,m_CloseAllBtn,OnClickCloseAllBtn)
ON_EVENT(ON_CLICK,m_CalculatePosBtn,OnClickCalculatePosBtn)
ON_EVENT(ON_CLICK,m_ClearInputsBtn,OnClickClearInputsBtn)
ON_EVENT(ON_CLICK,m_BreakEvenBtn,OnClickBreakEvenBtn)
ON_EVENT(ON_CLICK,m_MarketPendingBtn,OnClickMarketPendingBtn)
ON_EVENT(ON_CLICK,m_ShowLinesBtn,OnClickShowLinesBtn)
ON_EVENT(ON_CLICK,m_SellToggleBtn,OnClickSellToggleBtn)
ON_EVENT(ON_CLICK,m_BuyToggleBtn,OnClickBuyToggleBtn)
ON_EVENT(ON_CLICK,m_SendOrderBtn,OnClickSendOrderBtn)
ON_EVENT(ON_CLICK,m_StopToggleBtn,OnClickStopToggleBtn)
ON_EVENT(ON_CLICK,m_LimitToggleBtn,OnClickLimitToggleBtn)
ON_EVENT(ON_CLICK,m_AutoPosMgmtToggleBtn,OnClickAutoPosMgmtToggleBtn)
ON_EVENT(ON_CLICK,m_DoubleOrderBtn,OnClickDoubleOrderBtn)
ON_EVENT(ON_CLICK,m_DrawPositionsBtn,OnClickDrawPositionsBtn)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CControlsDialog::CControlsDialog(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CControlsDialog::~CControlsDialog(void)
  {
  }
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);
//--- create dependent controls

// --- Create Labels
   if(!CreateLotsLbl())
      return(false);
   if(!CreateSlPipsLbl())
      return(false);
   if(!CreateRiskToRewardRatioLbl())
      return(false);
   if(!CreateRiskLbl())
      return(false);
   if(!CreateTpPipsLbl())
      return(false);
   if(!CreatePriceLbl())
      return(false);
   if(!CreateSlLbl())
      return(false);
   if(!CreateTpLbl())
      return(false);

// --- Create Edit fields
   if(!CreateLotsEdit())
      return(false);
   if(!CreateSlPipsEdit())
      return(false);
   if(!CreateRiskToRewardRatioEdit())
      return(false);
   if(!CreateRiskEdit())
      return(false);
   if(!CreateTpPipsEdit())
      return(false);
   if(!CreatePriceEdit())
      return(false);
   if(!CreateSlEdit())
      return(false);
   if(!CreateTpEdit())
      return(false);

// --- Create Buttons
   if(!CreateSellBtn())
      return(false);
   if(!CreateBuyBtn())
      return(false);
   if(!CreateCloseAllBtn())
      return(false);
   if(!CreateCalculatePosBtn())
      return(false);
   if(!CreateClearInputsBtn())
      return(false);
   if(!CreateBreakEvenBtn())
      return(false);
   if(!CreateMarketPendingBtn())
      return(false);
   if(!CreateShowLinesBtn())
      return(false);
   if(!CreateSellToggleBtn())
      return(false);
   if(!CreateBuyToggleBtn())
      return(false);
   if(!CreateSendOrderBtn())
      return(false);
   if(!CreateStopToggleBtn())
      return(false);
   if(!CreateLimitToggleBtn())
      return(false);
   if(!CreateAutoPosMgmtToggleBtn())
      return(false);
   if(!CreateDoubleOrderBtn())
      return(false);
   if(!CreateDrawPositionsBtn())
      return(false);

//--- succeed
   return(true);
  }


// Creating Labels =====================================================================================================


//+------------------------------------------------------------------+
//| Create the Lots Label                  #1                        |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLotsLbl(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_LotsLbl.Create(m_chart_id,m_name+"LotsLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_LotsLbl.Text("L"))
      return(false);
   if(!Add(m_LotsLbl))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the SlPips label             #2                           |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSlPipsLbl(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+EDIT_WIDTH_SMALL+CONTROLS_GAP_X;
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;

//--- create
   if(!m_SlPipsLbl.Create(m_chart_id,m_name+"SlPipsLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_SlPipsLbl.Text("SLp"))
      return(false);
   if(!Add(m_SlPipsLbl))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the Tp pips label                   #3                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateTpPipsLbl(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+2*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_TpPipsLbl.Create(m_chart_id,m_name+"TpPipsLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_TpPipsLbl.Text("TPp"))
      return(false);
   if(!Add(m_TpPipsLbl))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the risk to reward ratio Label              #4            |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateRiskToRewardRatioLbl(void)
  {
//--- coordinates

   int x1=INDENT_LEFT+3*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;

//--- create
   if(!m_RiskToRewardRatioLbl.Create(m_chart_id,m_name+"RRRLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_RiskToRewardRatioLbl.Text("RRR"))
      return(false);
   if(!Add(m_RiskToRewardRatioLbl))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the Risk label                   #5                       |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateRiskLbl(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+4*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_RiskLbl.Create(m_chart_id,m_name+"RiskLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_RiskLbl.Text("R %"))
      return(false);
   if(!Add(m_RiskLbl))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the Price  label                   #6                     |
//+------------------------------------------------------------------+
bool CControlsDialog::CreatePriceLbl(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+5*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_PriceLbl.Create(m_chart_id,m_name+"PriceLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_PriceLbl.Text("$"))
      return(false);
   if(!Add(m_PriceLbl))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the Sl  label                   #7                        |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSlLbl(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+ 5*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X) + (EDIT_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_SlLbl.Create(m_chart_id,m_name+"SlLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_SlLbl.Text("SL"))
      return(false);
   if(!Add(m_SlLbl))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the Tp  label                   #8                        |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateTpLbl(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+ 5*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X) + 2*(EDIT_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_TpLbl.Create(m_chart_id,m_name+"TpLbl",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_TpLbl.Text("TP"))
      return(false);
   if(!Add(m_TpLbl))
      return(false);
//--- succeed
   return(true);
  }

// Creating Edit Fields =====================================================================================================

//+------------------------------------------------------------------+
//| Create the Lots field                  #1                        |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLotsEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_LotsEdit.Create(m_chart_id,m_name+"Lots",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_LotsEdit.ReadOnly(false))
      return(false);
   if(!Add(m_LotsEdit))
      return(false);
//--- Assign default value from the inputs
   if(!m_LotsEdit.Text(posLotsDef))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the SlPips field             #2                           |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSlPipsEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+EDIT_WIDTH_SMALL+CONTROLS_GAP_X;
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;

//--- create
   if(!m_SlPipsEdit.Create(m_chart_id,m_name+"SlPips",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_SlPipsEdit.ReadOnly(false))
      return(false);
   if(!Add(m_SlPipsEdit))
      return(false);
//--- Assign default value from the inputs
   if(!m_SlPipsEdit.Text(slPipsDef))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the TP Pips Edit field              #3                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateTpPipsEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+2*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_TpPipsEdit.Create(m_chart_id,m_name+"TpRiskEdit",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_TpPipsEdit.ReadOnly(false))
      return(false);
   if(!Add(m_TpPipsEdit))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the Risk to reward ratio edit field          #4           |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateRiskToRewardRatioEdit(void)
  {
//--- coordinates

   int x1=INDENT_LEFT+3*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;

//--- create
   if(!m_RiskToRewardRatioEdit.Create(m_chart_id,m_name+"RRR",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_RiskToRewardRatioEdit.ReadOnly(false))
      return(false);
   if(!Add(m_RiskToRewardRatioEdit))
      return(false);
//--- Assign default value from the inputs
   if(!m_RiskToRewardRatioEdit.Text(RiskToRewardDef))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the Risk Edit field              #5                       |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateRiskEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+4*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH_SMALL;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_RiskEdit.Create(m_chart_id,m_name+"Risk",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_RiskEdit.ReadOnly(false))
      return(false);

   if(!Add(m_RiskEdit))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the Price Edit field              #6                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreatePriceEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+5*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X);
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_PriceEdit.Create(m_chart_id,m_name+"PriceEdit",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_PriceEdit.ReadOnly(false))
      return(false);
   if(!Add(m_PriceEdit))
      return(false);
//--- succeed
   return(true);
  }



//+------------------------------------------------------------------+
//| Create the Sl Edit field              #7                         |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSlEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+ 5*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X) + (EDIT_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_SlEdit.Create(m_chart_id,m_name+"SlEdit",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_SlEdit.ReadOnly(false))
      return(false);
   if(!Add(m_SlEdit))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the Sl Edit field              #8                         |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateTpEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+ 5*(EDIT_WIDTH_SMALL+CONTROLS_GAP_X) + 2*(EDIT_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_TpEdit.Create(m_chart_id,m_name+"TpEdit",m_subwin,x1,y1,x2,y2))
      return(false);
//--- allow editing the content
   if(!m_TpEdit.ReadOnly(false))
      return(false);
   if(!Add(m_TpEdit))
      return(false);
//--- succeed
   return(true);
  }

// Creating Buttons =====================================================================================================

//+------------------------------------------------------------------+
//| Create the "SellBtn" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+3*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_SellBtn.Create(m_chart_id,m_name+"SellBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_SellBtn.Text("SELL"))
      return(false);
   if(!Add(m_SellBtn))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "BuyBtn" button                                       |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+BUTTON_WIDTH/2;
   int y1=INDENT_TOP+3*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_BuyBtn.Create(m_chart_id,m_name+"BuyBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_BuyBtn.Text("BUY"))
      return(false);
   if(!Add(m_BuyBtn))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "CloseAllBtn"   button                                |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCloseAllBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+3*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_CloseAllBtn.Create(m_chart_id,m_name+"CloseAllBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_CloseAllBtn.Text("Close"))
      return(false);
   if(!Add(m_CloseAllBtn))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the "DoubleOrderBtn"   button                             |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateDoubleOrderBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+3*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_DoubleOrderBtn.Create(m_chart_id,m_name+"DoubleOrderBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_DoubleOrderBtn.Text("2 "+"\x00BD"+"\x2714"))
      return(false);
   if(!Add(m_DoubleOrderBtn))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "CalculateRisk" button                                |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCalculatePosBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+4*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_CalculatePosBtn.Create(m_chart_id,m_name+"CalculatePosBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_CalculatePosBtn.Text("Calc"))
      return(false);
   if(!Add(m_CalculatePosBtn))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "ClearInputs" button                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateClearInputsBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+4*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_ClearInputsBtn.Create(m_chart_id,m_name+"ClearInputsBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_ClearInputsBtn.Text("Clear"))
      return(false);
   if(!Add(m_ClearInputsBtn))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Break Even"  button                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBreakEvenBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+4*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_BreakEvenBtn.Create(m_chart_id,m_name+"BreakEvenBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_BreakEvenBtn.Text("BE"))
      return(false);
   if(!Add(m_BreakEvenBtn))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the "Market Pending"  button                              |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateMarketPendingBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+2*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_MarketPendingBtn.Create(m_chart_id,m_name+"MarketPending",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_MarketPendingBtn.Text("[=M=]"))
      return(false);
   if(!Add(m_MarketPendingBtn))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Show Lines"  button                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateShowLinesBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+3*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+2*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_ShowLinesBtn.Create(m_chart_id,m_name+"ShowLinesBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_ShowLinesBtn.Text("\x4E09"))
      return(false);
   if(!Add(m_ShowLinesBtn))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the "Sell Toggle"  button                                 |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSellToggleBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+2*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_SellToggleBtn.Create(m_chart_id,m_name+"SellToggleBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_SellToggleBtn.Text("S"))
      return(false);
   if(!Add(m_SellToggleBtn))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the "Buy Toggle"  button                                 |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateBuyToggleBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X)+BUTTON_WIDTH/2;
   int y1=INDENT_TOP+2*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_BuyToggleBtn.Create(m_chart_id,m_name+"BuyToggleBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_BuyToggleBtn.Text("B"))
      return(false);
   if(!Add(m_BuyToggleBtn))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the "Stop Toggle"  button                                 |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateStopToggleBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+2*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+2*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_StopToggleBtn.Create(m_chart_id,m_name+"StopToggleBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_StopToggleBtn.Text("STP"))
      return(false);
   if(!Add(m_StopToggleBtn))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Limit Toggle"  button                                |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLimitToggleBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+2*(BUTTON_WIDTH+CONTROLS_GAP_X)+BUTTON_WIDTH/2;
   int y1=INDENT_TOP+2*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_LimitToggleBtn.Create(m_chart_id,m_name+"LimitToggleBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_LimitToggleBtn.Text("LMT"))
      return(false);
   if(!Add(m_LimitToggleBtn))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Send Order"  button                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateSendOrderBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+3*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+3*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_SendOrderBtn.Create(m_chart_id,m_name+"SendOrderBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_SendOrderBtn.Text("\x2714"))
      return(false);
   if(!Add(m_SendOrderBtn))
      return(false);
//--- succeed
   return(true);
  }



//+------------------------------------------------------------------+
//| Create the "Auto Position Management"  button                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateAutoPosMgmtToggleBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+3*(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+4*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_AutoPosMgmtToggleBtn.Create(m_chart_id,m_name+"AutoPosMgmtToggleBtn",m_subwin,x1,y1,x2,y2))
      return(false);

   if(autoPosMgmtToggle)
     {
      if(!m_AutoPosMgmtToggleBtn.Text("[=APM=]"))
         return(false);
     }
   else
      if(!autoPosMgmtToggle)
        {
         if(!m_AutoPosMgmtToggleBtn.Text("APM"))
            return(false);
        }

   if(!Add(m_AutoPosMgmtToggleBtn))
      return(false);
//--- succeed
   return(true);
  }


//+------------------------------------------------------------------+
//| Create the "Draw Positions"  button                              |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateDrawPositionsBtn(void)
  {
//--- coordinates
   int x1=INDENT_LEFT+3*(BUTTON_WIDTH+CONTROLS_GAP_X)+BUTTON_WIDTH/2;
   int y1=INDENT_TOP+4*(EDIT_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH/2;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_DrawPositionsBtn.Create(m_chart_id,m_name+"DrawPositionsBtn",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_DrawPositionsBtn.Text("\x270F"))
      return(false);
   if(!Add(m_DrawPositionsBtn))
      return(false);

//--- succeed
   return(true);
  }



//+------------------------------------------------------------------+
//| +++   Event handlers   +++                                       |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Event handler for Sell Button                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickSellBtn(void)
  {
   MarketSellOrder();
   Comment(__FUNCTION__);
  }
//+------------------------------------------------------------------+
//| Event handler for Buy Button                                     |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickBuyBtn(void)
  {
   MarketBuyOrder();
   Comment(__FUNCTION__);
  }


//+------------------------------------------------------------------+
//| Event handler for Close All Positions Button                     |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickCloseAllBtn(void)
  {
   CTrade trade;
   for(int i = PositionsTotal() - 1; i>=0; i--)
     {
      ulong posTicket = PositionGetTicket(i);
      if(trade.PositionClose(_Symbol))
        {
         Print(i," Position #",posTicket," Was closed...");
        }
     } // end of for loop
   Comment(__FUNCTION__);
  }



//+------------------------------------------------------------------+
//| Event handler for Send D Order Button                            |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickDoubleOrderBtn(void)
  {
   CTrade trade;

   Print("Market/Pending = " + pendingToggle + " Sell = " + sellToggle + " Buy = " + buyToggle);

   if(!pendingToggle && sellToggle && !buyToggle) // if market sell order
     {
      MarketSellDoubleOrder();
     }
   else
      if(!pendingToggle && !sellToggle && buyToggle) // if market buy order
        {
         MarketBuyDoubleOrder();
        }
      else
         if(pendingToggle && sellToggle && !buyToggle)
           {
            //+------------------------------------------------------------------+
            //|                          Pending Order   Sell                    |
            //+------------------------------------------------------------------+

            if(limitToggle && !stopToggle)
              {
               PendingSellLimitDoubleOrder();
              }
            else
               if(!limitToggle && stopToggle)
                 {
                  PendingSellStopDoubleOrder();
                 }

           }
         else
            if(pendingToggle && !sellToggle && buyToggle)
              {
               //+------------------------------------------------------------------+
               //|                          Pending Order   Buy                    |
               //+------------------------------------------------------------------+
               if(limitToggle && !stopToggle)
                 {
                  PendingBuyLimitDoubleOrder();
                 }
               else
                  if(!limitToggle && stopToggle)
                    {
                     PendingBuyStopDoubleOrder();
                    }
              }

   Comment(__FUNCTION__);
  }


//+------------------------------------------------------------------+
//| Event handler for Calculate Position Button                      |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickCalculatePosBtn(void)
  {
   CalculatePosition();
   Comment(__FUNCTION__);
  }


//+------------------------------------------------------------------+
//| Event handler for Clear Inputs Button                            |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickClearInputsBtn(void)
  {
   m_LotsEdit.Text(NULL);
   m_SlPipsEdit.Text(NULL);
   m_RiskToRewardRatioEdit.Text(NULL);
   m_RiskEdit.Text(NULL);
   m_PriceEdit.Text(NULL);
   m_SlEdit.Text(NULL);
   m_TpEdit.Text(NULL);
   m_TpPipsEdit.Text(NULL);
   Comment(__FUNCTION__);
  }

//+------------------------------------------------------------------+
//| Event handler for Break Even Button                              |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickBreakEvenBtn(void)
  {
   CTrade trade;
   for(int i = PositionsTotal() - 1; i>=0; i--)
     {
      ulong posTicket = PositionGetTicket(i);
      string posSymbol = PositionGetSymbol(i);
      double posOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),4);
      double posSl = NormalizeDouble(PositionGetDouble(POSITION_SL),4);
      double posTp = NormalizeDouble(PositionGetDouble(POSITION_TP),4);
      double posCurrent = NormalizeDouble(PositionGetDouble(POSITION_PRICE_CURRENT),4);

      if(posSymbol == _Symbol)
        {
         if((posCurrent > posOpen && posOpen > posSl) || (posCurrent < posOpen && posOpen < posSl))
           {
            trade.PositionModify(posTicket,posOpen,posTp);
            Print(i," Position #",posTicket," Break Even...");
           }
         else
           {
            Print("Break Even not possible");
           }
        }
     } // end of for loop
   Comment(__FUNCTION__);
  }

//+------------------------------------------------------------------+
//| Event handler for Market Pending Button                          |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickMarketPendingBtn(void)
  {
   if(pendingToggle)
     {
      m_MarketPendingBtn.Text("[=M=]");
      pendingToggle = false;
     }
   else
      if(!pendingToggle)
        {
         m_MarketPendingBtn.Text("[=P=]");
         pendingToggle = true;
        }
   Comment(__FUNCTION__);
  }

//+------------------------------------------------------------------+
//| Event handler for Show Lines Button                              |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickShowLinesBtn(void)
  {
   Print("Line input = ", lineInput);
   if(!lineInput)
     {
      lineInput = true;
      m_ShowLinesBtn.Text("Hide");

      // Line Price
      ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

      double linePrice;
      double lineSl;
      double lineTp;

      if(sellToggle && !buyToggle)
        {
         // SELL
         linePrice = NormalizeDouble(ask,4);
         lineSl = NormalizeDouble(ask + StringToDouble(slPipsDef)*10*_Point,5);
         lineTp = NormalizeDouble(ask - StringToDouble(slPipsDef)*StringToDouble(RiskToRewardDef)*10*_Point,5);
        }
      else
         if(!sellToggle && buyToggle)
           {
            // BUY
            linePrice = NormalizeDouble(bid,4);
            lineSl = NormalizeDouble(bid - StringToDouble(slPipsDef)*10*_Point,5);
            lineTp = NormalizeDouble(bid + StringToDouble(slPipsDef)*StringToDouble(RiskToRewardDef)*10*_Point,5);
           }

      if(sellToggle || buyToggle)
        {
         // Create Price Line
         if(pendingToggle)
           {
            ObjectCreate(0,"priceLine",OBJ_HLINE,0,0,linePrice);
            ObjectSetInteger(0, "priceLine", OBJPROP_COLOR, clrGoldenrod);
            ObjectSetInteger(0, "priceLine", OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, "priceLine", OBJPROP_WIDTH, 3);
            ObjectSetInteger(0, "priceLine", OBJPROP_BACK, true);
            ObjectSetInteger(0, "priceLine", OBJPROP_SELECTABLE, true);
            ObjectSetInteger(0, "priceLine", OBJPROP_SELECTED, true);
            ObjectSetInteger(0, "priceLine", OBJPROP_HIDDEN, false);
            ObjectSetInteger(0, "priceLine", OBJPROP_ZORDER, 0);
           }

         // Create Stoploss Line
         ObjectCreate(0,"stopLossLine",OBJ_HLINE,0,0,lineSl);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_COLOR, clrTomato);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_WIDTH, 3);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_BACK, true);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_SELECTABLE, true);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_SELECTED, true);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_HIDDEN, false);
         ObjectSetInteger(0, "stopLossLine", OBJPROP_ZORDER, 0);

         // Create Take Profit Line
         ObjectCreate(0,"takeProfitLine",OBJ_HLINE,0,0,lineTp);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_COLOR, clrDodgerBlue);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_WIDTH, 3);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_BACK, true);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_SELECTABLE, true);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_SELECTED, true);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_HIDDEN, false);
         ObjectSetInteger(0, "takeProfitLine", OBJPROP_ZORDER, 0);

         if(!GetDataFromLines())
           {
            Print("Get Data From Lines Failed...");
           }

         if(!CalculatePosition())
           {
            Print("Position Calculation Failed...");
           }

         if(pendingToggle)
           {
            m_PriceEdit.Text("M");
           }
        }

      // Line Sl
     }
   else
      if(lineInput)
        {
         lineInput = false;
         m_ShowLinesBtn.Text("\x4E09");
         ObjectDelete(0,"priceLine");
         ObjectDelete(0,"stopLossLine");
         ObjectDelete(0,"takeProfitLine");
         sellToggle = false;
         buyToggle = false;
         m_SellToggleBtn.Text("S");
         m_BuyToggleBtn.Text("B");
         m_StopToggleBtn.Text("STP");
         m_LimitToggleBtn.Text("LMT");
        }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   Comment(__FUNCTION__);
  }


//+------------------------------------------------------------------+
//| Event handler for Sell Toggle Button                             |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickSellToggleBtn(void)
  {
   sellToggle = true;
   buyToggle = false;
   m_SellToggleBtn.Text("[=S=]");
   m_BuyToggleBtn.Text("B");
   Print("SellToggle");
   Comment(__FUNCTION__);
  }

//+------------------------------------------------------------------+
//| Event handler for Buy Toggle Button                              |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickBuyToggleBtn(void)
  {
   sellToggle = false;
   buyToggle = true;
   m_SellToggleBtn.Text("S");
   m_BuyToggleBtn.Text("[=B=]");
   Print("BuyToggle");
   Comment(__FUNCTION__);
  }



//+------------------------------------------------------------------+
//| Event handler for Stop Toggle Button                             |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickStopToggleBtn(void)
  {
   stopToggle = true;
   limitToggle  = false;
   m_StopToggleBtn.Text("[STP]");
   m_LimitToggleBtn.Text("LMT");
   Print("StopToggle");
   Comment(__FUNCTION__);
  }

//+------------------------------------------------------------------+
//| Event handler for Limit Toggle Button                            |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickLimitToggleBtn(void)
  {
   stopToggle = false;
   limitToggle = true;
   m_StopToggleBtn.Text("STP");
   m_LimitToggleBtn.Text("[LMT]");
   Print("LimitToggle");
   Comment(__FUNCTION__);
  }

//+------------------------------------------------------------------+
//| Event handler for Auto Position Management Button                |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickAutoPosMgmtToggleBtn(void)
  {

   if(autoPosMgmtToggle)
     {
      autoPosMgmtToggle = false;
      m_AutoPosMgmtToggleBtn.Text("APM");
     }
   else
      if(!autoPosMgmtToggle)
        {
         autoPosMgmtToggle = true;
         m_AutoPosMgmtToggleBtn.Text("[=APM=]");
        }

   Print("APM = ",autoPosMgmtToggle);
   Comment(__FUNCTION__);
  }


//+------------------------------------------------------------------+
//| Event handler for Send Order Button                              |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickSendOrderBtn(void)
  {

   CTrade trade;

   Print("Market/Pending = " + pendingToggle + " Sell = " + sellToggle + " Buy = " + buyToggle);

   if(!pendingToggle && sellToggle && !buyToggle) // if market sell order
     {
      MarketSellOrder();
     }
   else
      if(!pendingToggle && !sellToggle && buyToggle) // if market buy order
        {
         MarketBuyOrder();
        }
      else
         if(pendingToggle && sellToggle && !buyToggle)
           {
            //+------------------------------------------------------------------+
            //|                          Pending Order   Sell                    |
            //+------------------------------------------------------------------+

            if(limitToggle && !stopToggle)
              {
               PendingSellLimitOrder();
              }
            else
               if(!limitToggle && stopToggle)
                 {
                  PendingSellStopOrder();
                 }

           }
         else
            if(pendingToggle && !sellToggle && buyToggle)
              {
               //+------------------------------------------------------------------+
               //|                          Pending Order   Buy                    |
               //+------------------------------------------------------------------+
               if(limitToggle && !stopToggle)
                 {
                  PendingBuyLimitOrder();
                 }
               else
                  if(!limitToggle && stopToggle)
                    {
                     PendingBuyStopOrder();
                    }
              }

   Comment(__FUNCTION__);
  }


//+------------------------------------------------------------------+
//| Event handler for "Draw Positions" Button                        |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickDrawPositionsBtn(void)
  {
   int totalPos = PositionsTotal();

   for(int i = 0; i < totalPos; i++)
     {
      ulong posTicket = PositionGetTicket(i);

      if(PositionSelectByTicket(posTicket))
        {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            datetime time1 = PositionGetInteger(POSITION_TIME);
            datetime time2 = time1+(PeriodSeconds(_Period)*15);
            double price1 = PositionGetDouble(POSITION_PRICE_OPEN);
            double price2 = PositionGetDouble(POSITION_SL);
            double price3 = PositionGetDouble(POSITION_TP);

            if(price2 > 0)
              {
               ObjectCreate(0, "SL_Rectangle_"+i, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
               ObjectSetInteger(0,"SL_Rectangle_"+i,OBJPROP_COLOR,clrDarkRed);
               ObjectSetInteger(0,"SL_Rectangle_"+i,OBJPROP_FILL,false);
               ObjectSetInteger(0,"SL_Rectangle_"+i,OBJPROP_SELECTABLE,true);
              }

            if(price3 > 0)
              {
               ObjectCreate(0, "TP_Rectangle_"+i, OBJ_RECTANGLE, 0, time1, price1, time2, price3);
               ObjectSetInteger(0,"TP_Rectangle_"+i,OBJPROP_COLOR,clrDarkGreen);
               ObjectSetInteger(0,"TP_Rectangle_"+i,OBJPROP_FILL,false);
               ObjectSetInteger(0,"TP_Rectangle_"+i,OBJPROP_SELECTABLE,true);
              }
           }
        }
     }


   Comment(__FUNCTION__);
  }

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CControlsDialog ExtDialog;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectDelete(0,"priceLine");
   ObjectDelete(0,"stopLossLine");
   ObjectDelete(0,"takeProfitLine");
//--- create application dialog
   if(!ExtDialog.Create(0,"Controls",0,10,20,475,180))
      return(INIT_FAILED);
//--- run application
   ExtDialog.Run();

// Auto Position Management EA initialization

   if(fractalsTSL)
     {
      handleFractal = iFractals(_Symbol, TimeFrame);
     }

   if(movingAverageTSL)
     {
      handleMA = iMA(_Symbol, TimeFrame, MaPeriod, MaShift, TslMaMethod, TslMaAppPrice);
     }

   if(kijunsenTSL || tenkansenTSL)
     {
      handleIchimoku = iIchimoku(_Symbol,PERIOD_CURRENT,9,26,52);
     }


   /*   ------ NOT SURE if this code is needed. 2022-09-13
    long totalPos = PositionsTotal();
    for(int i = 0; i < totalPos; i++)
      {
       ulong originalPosTicket = PositionGetTicket(i);
       if(PositionSelectByTicket(originalPosTicket))
         {
          double originalPosSl = NormalizeDouble(PositionGetDouble(POSITION_SL),5);
          if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
             ArrayResize(originalPosSlArr,i+1);
             originalPosSlArr[i].posTicketArr = originalPosTicket;
             originalPosSlArr[i].posSlArr = originalPosSl;
            }
         }
      }
   */

//--- succeed
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- clear comments
   Comment("");
   ObjectDelete(0,"priceLine");
   ObjectDelete(0,"stopLossLine");
   ObjectDelete(0,"takeProfitLine");
//--- destroy dialog
   ExtDialog.Destroy(reason);
  }

//-------------------------------------------------------------------+
//| Expert chart event function                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event ID
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
  {
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(autoPosMgmtToggle)
     {
      double spreadPos = SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
      int bars = iBars(_Symbol, TimeFrame);
      int totalPos = PositionsTotal();

      text = "-----------------------------\nPosition Management EA\n " + _Symbol + " " +_Period + "\n";
      text += "------------------------------\n";
      text += "Spread = " + IntegerToString(spreadPos) + "\n";
      text += "Lower Fractal = " + DoubleToString(mainLower, 4) + "\n";
      text += "Upper Fractal = " + DoubleToString(mainUpper, 4) + "\n";
      text += "BE Ratio = " + (string)breakevenRatio + "\n";
      text += "MA Period = " + (string)MaPeriod +  " | Shift = " + (string)MaShift + " | TF = "  + (string)TimeFrame + "\n";
      text += "TSL Fra   = [ " + (string)fractalsTSL + " ]\n";
      text += "TSL MA  = [ " + (string)movingAverageTSL + " ]\n";
      text += "Auto BE  = [ " + (string)autoBreakEven + " ]" + " ]\n";
      text += "Points TSL = [ " + (string)pointsTSL + " ]";

      //+------------------------------------------------------------------+
      //|        Trailing SL activated by a new Tick                       |
      //+------------------------------------------------------------------+
      if(autoBreakEven)
        {
         for(int i = 0; i < totalPos; i++)
           {
            ulong posTicket = PositionGetTicket(i);

            if(PositionSelectByTicket(posTicket))
              {
               if(PositionGetString(POSITION_SYMBOL) == _Symbol)
                 {
                  CTrade trade;
                  double posOpenPrice = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),4);
                  double posSl = NormalizeDouble(PositionGetDouble(POSITION_SL),4);
                  double posTp = NormalizeDouble(PositionGetDouble(POSITION_TP),4);

                  double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),4);
                  double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),4);
                  double oldPosSl;

                  //+------------------------------------------------------------------+
                  //|         Break Even                                               |
                  //+------------------------------------------------------------------+



                  if(breakevenRatio > 0 && NormalizeDouble(posOpenPrice,4) != oldPosSl && posOpenPrice != posSl)
                    {
                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  // checking if the open position has type BUY
                       {
                        double posTriggerBuy = NormalizeDouble((posOpenPrice - posSl) * breakevenRatio,_Digits);
                        if(posSl < posOpenPrice)
                          {
                           if(bid > posOpenPrice + posTriggerBuy)

                             {
                              Print("BUY Break Even Conditions Met...  Position Open Price = ",posOpenPrice);
                              if(trade.PositionModify(posTicket, posOpenPrice, posTp))
                                {
                                 Print(__FUNCTION__, " > Position #", posTicket, " was modified by Breakeven BUY");
                                }
                             }
                          }
                       }

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) // checking if the open position has type SELL
                       {
                        double posTriggerSell = NormalizeDouble((posSl - posOpenPrice) * breakevenRatio,_Digits);
                        if(posSl > posOpenPrice)
                          {
                           if(ask < posOpenPrice - posTriggerSell)

                             {
                              Print("BUY Break Even Conditions Met...  Position Open Price = ",posOpenPrice);
                              if(trade.PositionModify(posTicket, posOpenPrice, posTp))
                                {
                                 Print(__FUNCTION__, " > Position #", posTicket, " was modified by Breakeven SELL");
                                }
                             }
                          }
                       }
                    } // Breakeven ratio > 0
                 }
              }
           } // for loop
        } // if autobreakeven
      //+------------------------------------------------------------------+
      //|        End of Break Even                                         |
      //+------------------------------------------------------------------+


      //+------------------------------------------------------------------+
      //|       Regular TSL in Points                                      |
      //+------------------------------------------------------------------+


      if(pointsTSL && TslPoints > 0)
        {
         for(int i = 0; i < totalPos; i++)
           {
            ulong posTicket = PositionGetTicket(i);

            if(PositionSelectByTicket(posTicket))
              {
               if(PositionGetString(POSITION_SYMBOL) == _Symbol)
                 {
                  CTrade trade;
                  double posOpenPrice = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),4);
                  double posSl = NormalizeDouble(PositionGetDouble(POSITION_SL),4);
                  double posTp = NormalizeDouble(PositionGetDouble(POSITION_TP),4);

                  double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),4);
                  double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),4);
                  double oldPosSl;

                  if(TslPoints > spreadPos)
                    {
                     // --------------------
                     // --- BUY POSITION ---
                     // --------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       {
                        double sl = NormalizeDouble(ask - (TslPoints + spreadPos) * _Point,_Digits);

                        if(sl > posSl && sl < bid)
                          {

                           if(trade.PositionModify(posTicket,sl,posTp))
                             {
                              Print(__FUNCTION__," > Position #",posTicket," was modified by Regular TSL BUY.");
                             }
                          }
                       }

                     // ---------------------
                     // --- SELL POSITION ---
                     // ---------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                       {
                        double sl = NormalizeDouble(bid + (TslPoints + spreadPos) * _Point,_Digits);

                        if(sl < posSl && sl > ask)
                          {
                           if(trade.PositionModify(posTicket,sl,posTp))
                             {
                              Print(__FUNCTION__," > Position #",posTicket," was modified by Regular TSL SELL.");
                             }
                          }
                       }

                    }

                 } // +Symbol
              } // posTicket
           } // for loop
        }
      //+------------------------------------------------------------------+
      //|      End of Regular TSL in Points                                |
      //+------------------------------------------------------------------+






      //+------------------------------------------------------------------+
      //|        Trailing SL activated by a new bar                        |
      //+------------------------------------------------------------------+


      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(barsTotal != bars && totalPos > 0)  // New bar appeared on the chart
        {
         barsTotal = bars;

         double fracUpper[];
         double fracLower[];

         CopyBuffer(handleFractal, UPPER_LINE, 3, 1, fracUpper);
         CopyBuffer(handleFractal, LOWER_LINE, 3, 1, fracLower);

         if(fracUpper[0] != EMPTY_VALUE)
           {
            mainUpper = NormalizeDouble(fracUpper[0] + (TslOffsetPoints + spreadPos) * _Point, 4);
           }

         if(fracLower[0] != EMPTY_VALUE)
           {
            mainLower = NormalizeDouble(fracLower[0] - (TslOffsetPoints + spreadPos) * _Point, 4);
           }

         for(int i = 0; i < totalPos; i++)
           {
            ulong posTicket = PositionGetTicket(i);

            if(PositionSelectByTicket(posTicket))
              {
               if(PositionGetString(POSITION_SYMBOL) == _Symbol)
                 {
                  CTrade trade;
                  double posOpenPrice = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),4);
                  double posSl = NormalizeDouble(PositionGetDouble(POSITION_SL),4);
                  double posTp = NormalizeDouble(PositionGetDouble(POSITION_TP),4);

                  double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),4);
                  double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),4);

                  double ma[];
                  CopyBuffer(handleMA,MAIN_LINE,1,MaShift,ma);




                  //+------------------------------------------------------------------+
                  //|         Fractals                                                 |
                  //+------------------------------------------------------------------+

                  if(fractalsTSL)
                    {
                     // --------------------
                     // --- BUY POSITION ---
                     // --------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  // checking if the open position if has type BUY
                       {
                        // ---
                        if(posSl < mainLower && bid > mainLower)
                          {
                           double sl = mainLower;

                           if(sl > posSl)
                             {
                              if(trade.PositionModify(posTicket, sl, posTp))

                                {
                                 Print(__FUNCTION__, " > Position #", posTicket, " was modified by Fractal tsl. BUY");
                                }
                             }
                          }
                       }

                     // ---------------------
                     // --- SELL POSITION ---
                     // ---------------------
                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                       {
                        //---
                        if(posSl > mainUpper && ask < mainUpper)
                          {
                           double sl = mainUpper;

                           if(sl < posSl || posSl == 0)
                             {
                              if(trade.PositionModify(posTicket, sl, posTp))
                                {
                                 Print(__FUNCTION__, " > Position #", posTicket, " was modified by Fractal tsl. SELL");
                                }
                             }
                          }
                       }
                    } // end of if fractals


                  //+------------------------------------------------------------------+
                  //|        End of Fractals                                           |
                  //+------------------------------------------------------------------+


                  //+------------------------------------------------------------------+
                  //|         MA                                                       |
                  //+------------------------------------------------------------------+

                  if(movingAverageTSL)
                    {
                     // --------------------
                     // --- BUY POSITION ---
                     // --------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       {
                        if(ArraySize(ma) > 0)
                          {
                           double sl = NormalizeDouble(NormalizeDouble(ma[MaShift - 1],4) - (TslOffsetPoints + spreadPos) * _Point,4);

                           if(sl > posSl && sl < bid)
                             {
                              if(trade.PositionModify(posTicket,sl,posTp))
                                {
                                 Print(NormalizeDouble(sl - posSl,4), " ", NormalizeDouble(bid - sl,4));
                                 Print("SL = ",sl, " TP = ", posTp);
                                 Print(__FUNCTION__," > Position #",posTicket," was modified by ma tsl.");
                                }
                             }
                          }

                       }

                     // ---------------------
                     // --- SELL POSITION ---
                     // ---------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                       {
                        if(ArraySize(ma) > 0)
                          {
                           double sl = NormalizeDouble(NormalizeDouble(ma[MaShift - 1],4) + (TslOffsetPoints + spreadPos) * _Point,4);
                           if(sl < posSl || posSl == 0)
                             {
                              if(trade.PositionModify(posTicket,sl,posTp))
                                {
                                 Print("SL = ",sl, " TP = ", posTp);
                                 Print(__FUNCTION__," > Position #",posTicket," was modified by ma tsl.");
                                }
                             }
                          }
                       }

                    }// end of moving average


                  //+------------------------------------------------------------------+
                  //|       end of MA                                                  |
                  //+------------------------------------------------------------------+


                  //+------------------------------------------------------------------+
                  //|       Kinjunsen TSL                                              |
                  //+------------------------------------------------------------------+


                  if(kijunsenTSL)
                    {
                     double KijunsenArr[];
                     CopyBuffer(handleIchimoku,1,0,2,KijunsenArr);


                     // --------------------
                     // --- BUY POSITION ---
                     // --------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       {
                        if(ArraySize(KijunsenArr) > 0)
                          {
                           double sl = NormalizeDouble(NormalizeDouble(KijunsenArr[0],4) - (TslOffsetPoints + spreadPos) * _Point,4);

                           if(sl > posSl && sl < bid)
                             {
                              if(trade.PositionModify(posTicket,sl,posTp))
                                {
                                 Print(NormalizeDouble(sl - posSl,4), " ", NormalizeDouble(bid - sl,4));
                                 Print("SL = ",sl, " TP = ", posTp);
                                 Print(__FUNCTION__," > Position #",posTicket," was modified by Kijunsen tsl.");
                                }
                             }
                          }

                       }

                     // ---------------------
                     // --- SELL POSITION ---
                     // ---------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                       {
                        if(ArraySize(KijunsenArr) > 0)
                          {
                           double sl = NormalizeDouble(NormalizeDouble(KijunsenArr[0],4) + (TslOffsetPoints + spreadPos) * _Point,4);
                           if(sl < posSl || posSl == 0)
                             {
                              if(trade.PositionModify(posTicket,sl,posTp))
                                {
                                 Print("SL = ",sl, " TP = ", posTp);
                                 Print(__FUNCTION__," > Position #",posTicket," was modified by Kijunsen tsl.");
                                }
                             }
                          }
                       }
                    }
                  //+------------------------------------------------------------------+
                  //|       End of Kinjunsen TSL                                       |
                  //+------------------------------------------------------------------+



                  //+------------------------------------------------------------------+
                  //|       Tenkansen TSL                                              |
                  //+------------------------------------------------------------------+


                  if(tenkansenTSL)
                    {
                     double TenkansenArr[];
                     CopyBuffer(handleIchimoku,1,0,2,TenkansenArr);


                     // --------------------
                     // --- BUY POSITION ---
                     // --------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       {
                        if(ArraySize(TenkansenArr) > 0)
                          {
                           double sl = NormalizeDouble(NormalizeDouble(TenkansenArr[0],4) - (TslOffsetPoints + spreadPos) * _Point,4);

                           if(sl > posSl && sl < bid)
                             {
                              if(trade.PositionModify(posTicket,sl,posTp))
                                {
                                 Print(NormalizeDouble(sl - posSl,4), " ", NormalizeDouble(bid - sl,4));
                                 Print("SL = ",sl, " TP = ", posTp);
                                 Print(__FUNCTION__," > Position #",posTicket," was modified by Tenkansen tsl.");
                                }
                             }
                          }
                       }

                     // ---------------------
                     // --- SELL POSITION ---
                     // ---------------------

                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                       {
                        if(ArraySize(TenkansenArr) > 0)
                          {
                           double sl = NormalizeDouble(NormalizeDouble(TenkansenArr[0],4) + (TslOffsetPoints + spreadPos) * _Point,4);
                           if(sl < posSl || posSl == 0)
                             {
                              if(trade.PositionModify(posTicket,sl,posTp))
                                {
                                 Print("SL = ",sl, " TP = ", posTp);
                                 Print(__FUNCTION__," > Position #",posTicket," was modified by Tenkansen tsl.");
                                }
                             }
                          }
                       }
                    }
                  //+------------------------------------------------------------------+
                  //|       End of Tenkansen TSL                                       |
                  //+------------------------------------------------------------------+





                 } // if pos symbol
              } // if pos ticket
           } // for loop
        } // bars total

      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      Comment(text);
      text="";
     } // autoPosMgmtToggle
  }// OnTick








//+---------------------------------------------------------------------------------------+
//+---------------------------------------------------------------------------------------+
//|                              +++ DEFINED FUNCTIONS +++                                |
//+---------------------------------------------------------------------------------------+
//+---------------------------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                      Get Order Data Function                     |
//+------------------------------------------------------------------+
bool CControlsDialog::GetOrderData()
  {
   posLots = NormalizeDouble(StringToDouble(m_LotsEdit.Text()),2);
   slPips = NormalizeDouble(StringToDouble(m_SlPipsEdit.Text()),2);
   RiskToReward = NormalizeDouble(StringToDouble(m_RiskToRewardRatioEdit.Text()),2);

   ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   slSell = NormalizeDouble(bid + slPips*_Point*10,4);
   slBuy = NormalizeDouble(ask - slPips*_Point*10,4);

   tpSell = NormalizeDouble(bid - RiskToReward * (slSell - bid),4);
   tpBuy = NormalizeDouble(ask + RiskToReward * (ask - slBuy),4);
   return(true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::GetDataFromLines()
  {
   linePriceNew = NormalizeDouble(ObjectGetDouble(0,"priceLine",OBJPROP_PRICE),4);
   lineSlNew =  NormalizeDouble(ObjectGetDouble(0,"stopLossLine",OBJPROP_PRICE),4);
   lineTpNew =  NormalizeDouble(ObjectGetDouble(0,"takeProfitLine",OBJPROP_PRICE),4);

   m_PriceEdit.Text(DoubleToString(linePriceNew,4));
   m_SlEdit.Text(DoubleToString(lineSlNew,4));
   m_TpEdit.Text(DoubleToString(lineTpNew,4));
   return(true);
  }



//+------------------------------------------------------------------+
//|                          Market Order SELL                       |
//+------------------------------------------------------------------+
bool CControlsDialog::MarketSellOrder()
  {
   CTrade trade;
   if(m_LotsEdit.Text() != "" && m_SlPipsEdit.Text() != "" && m_RiskToRewardRatioEdit.Text() != "")
     {
      GetOrderData();

      Print("Lots = ",posLots," SL pips = ",slPips," RRR = ",RiskToReward, " SL Buy = ",slBuy, " Ask = ",ask," Ask - SL Buy = ",NormalizeDouble(ask-slBuy,4),
            " TP = ", tpBuy, " TP - ask = ",NormalizeDouble(tpBuy - ask,4));

      if(posLots > 0 && slPips > 0 && RiskToReward > 0)
        {
         if(trade.Sell(posLots,_Symbol,bid,slSell,tpSell,"This is a SELL trade"))
           {
            Print("Sold ",posLots," Lots of ",_Symbol," @ ",bid," SL = ",slSell, " TP = ",tpSell);
           }
        }
      else
        {
         Print("Incorrect input");
        }
     }
   else
     {
      Print("Not enough input");
     }
   return(true);
  }


//+------------------------------------------------------------------+
//|                          Market Order BUY                        |
//+------------------------------------------------------------------+
bool  CControlsDialog::MarketBuyOrder()
  {
   CTrade trade;

   if(m_LotsEdit.Text() != "" && m_SlPipsEdit.Text() != "" && m_RiskToRewardRatioEdit.Text() != "")
     {
      GetOrderData();

      Print("Lots = ",posLots," SL pips = ",slPips," RRR = ",RiskToReward, " SL Buy = ",slBuy, " Ask = ",ask," Ask - SL Buy = ",NormalizeDouble(ask-slBuy,5),
            " TP = ", tpBuy, " TP - ask = ",NormalizeDouble(tpBuy - ask,5));

      if(posLots > 0 && slPips > 0 && RiskToReward > 0)
        {
         if(trade.Buy(posLots,_Symbol,ask,slBuy,tpBuy,"This is a BUY trade"))
           {
            Print("Bought ",posLots," Lots of ",_Symbol," @ ",ask," SL = ",slBuy, " TP = ",tpBuy);
           }
        }
      else

        {
         Print("Incorrect input");
        }
     }
   else
     {
      Print("Not enough input");
     }
   return(true);

  }

//+------------------------------------------------------------------+
//|                                PendingSellStopOrder              |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingSellStopOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   if(lineSlNew > linePriceNew && (linePriceNew >= lineTpNew) && linePriceNew < ask)
     {
      if(trade.SellStop(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("SellStop Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
     }
   else
     {
      Print("Incorrect input parameters for SellStop operation");
     }
   return(true);
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingSellLimitOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   if(lineSlNew > linePriceNew && (linePriceNew >= lineTpNew) && linePriceNew > ask)
     {
      if(trade.SellLimit(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("SellLimit Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
     }
   else
     {
      Print("Incorrect input parameters for SellLimit operation");
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingBuyStopOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   if(lineSlNew < linePriceNew && (linePriceNew <= lineTpNew) && linePriceNew > bid)
     {
      if(trade.BuyStop(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("BuyStop Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
     }
   else
     {
      Print("Incorrect input parameters for BuyStop operation");
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingBuyLimitOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   if(lineSlNew < linePriceNew && (linePriceNew <= lineTpNew) && linePriceNew < bid)
     {
      if(trade.BuyLimit(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("BuyLimit Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
     }
   else
     {
      Print("Incorrect input parameters for BuyLimit operation");
     }
   return(true);
  }


//+------------------------------------------------------------------+
// Auxiliary functions for Double Orders button
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                          Market Order SELL Double                |
//+------------------------------------------------------------------+
bool CControlsDialog::MarketSellDoubleOrder()
  {
   CTrade trade;
   if(m_LotsEdit.Text() != "" && m_SlPipsEdit.Text() != "" && m_RiskToRewardRatioEdit.Text() != "")
     {
      GetOrderData();

      tpSell =  slSell - 2*(slSell - bid);
      posLots = NormalizeDouble(0.5 * posLots,2);

      Print("Lots = ",posLots," SL pips = ",slPips," RRR = ",RiskToReward, " SL Buy = ",slBuy, " Ask = ",ask," Ask - SL Buy = ",NormalizeDouble(ask-slBuy,4),
            " TP = ", tpBuy, " TP - ask = ",NormalizeDouble(tpBuy - ask,4));

      if(posLots > 0 && slPips > 0 && RiskToReward > 0)
        {
         if(trade.Sell(posLots,_Symbol,bid,slSell,tpSell,"This is a SELL trade"))
           {
            Print("Sold ",posLots," Lots of ",_Symbol," @ ",bid," SL = ",slSell, " TP = ",tpSell);
           }
         tpSell = 0;
         if(trade.Sell(posLots,_Symbol,bid,slSell,0,"This is a SELL trade"))
           {
            Print("Sold ",posLots," Lots of ",_Symbol," @ ",bid," SL = ",slSell, " TP = ",tpSell);
           }
        }
      else
        {
         Print("Incorrect input");
        }
     }
   else
     {
      Print("Not enough input");
     }
   return(true);
  }

//+------------------------------------------------------------------+
//|                          Market Order BUY Double                 |
//+------------------------------------------------------------------+
bool  CControlsDialog::MarketBuyDoubleOrder()
  {
   CTrade trade;

   if(m_LotsEdit.Text() != "" && m_SlPipsEdit.Text() != "" && m_RiskToRewardRatioEdit.Text() != "")
     {
      GetOrderData();

      tpBuy =  ask + ask - slBuy;
      posLots = NormalizeDouble(0.5 * posLots,2);

      Print("Lots = ",posLots," SL pips = ",slPips," RRR = ",RiskToReward, " SL Buy = ",slBuy, " Ask = ",ask," Ask - SL Buy = ",NormalizeDouble(ask-slBuy,5),
            " TP = ", tpBuy, " TP - ask = ",NormalizeDouble(tpBuy - ask,5));

      if(posLots > 0 && slPips > 0 && RiskToReward > 0)
        {
         if(trade.Buy(posLots,_Symbol,ask,slBuy,tpBuy,"This is a BUY trade"))
           {
            Print("Bought ",posLots," Lots of ",_Symbol," @ ",ask," SL = ",slBuy, " TP = ",tpBuy);
           }

         tpBuy =  0;
         if(trade.Buy(posLots,_Symbol,ask,slBuy,tpBuy,"This is a BUY trade"))
           {
            Print("Bought ",posLots," Lots of ",_Symbol," @ ",ask," SL = ",slBuy, " TP = ",tpBuy);
           }

        }
      else

        {
         Print("Incorrect input");
        }
     }
   else
     {
      Print("Not enough input");
     }
   return(true);

  }

//+------------------------------------------------------------------+
//|                          PendingSellStopDoubleOrder              |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingSellStopDoubleOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   lineTpNew = lineSlNew - 2*(lineSlNew - linePriceNew);
   posLots = NormalizeDouble(0.5 * posLots,2);

   if(lineSlNew > linePriceNew && (linePriceNew >= lineTpNew) && linePriceNew < ask)
     {
      if(trade.SellStop(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("SellStop Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
      lineTpNew = 0;
      if(trade.SellStop(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("SellStop Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }

     }
   else
     {
      Print("Incorrect input parameters for SellStop Double Order operation");
     }
   return(true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingSellLimitDoubleOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   lineTpNew = lineSlNew - 2*(lineSlNew - linePriceNew);
   posLots = NormalizeDouble(0.5 * posLots,2);

   if(lineSlNew > linePriceNew && (linePriceNew >= lineTpNew) && linePriceNew > ask)
     {
      if(trade.SellLimit(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("SellLimit Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
      lineTpNew = 0;
      if(trade.SellLimit(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("SellLimit Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }

     }
   else
     {
      Print("Incorrect input parameters for SellLimit Double operation");
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingBuyStopDoubleOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   lineTpNew = linePriceNew + linePriceNew - lineSlNew;
   posLots = NormalizeDouble(0.5 * posLots,2);

   if(lineSlNew < linePriceNew && (linePriceNew <= lineTpNew) && linePriceNew > bid)
     {
      if(trade.BuyStop(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("BuyStop Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
      lineTpNew = 0;
      if(trade.BuyStop(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("BuyStop Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
     }
   else
     {
      Print("Incorrect input parameters for BuyStop operation");
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::PendingBuyLimitDoubleOrder()
  {
   CTrade trade;
   GetOrderData();
   GetDataFromLines();

   lineTpNew = linePriceNew + linePriceNew - lineSlNew;
   posLots = NormalizeDouble(0.5 * posLots,2);

   if(lineSlNew < linePriceNew && (linePriceNew <= lineTpNew) && linePriceNew < bid)
     {
      if(trade.BuyLimit(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("BuyLimit Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
      lineTpNew = 0;
      if(trade.BuyLimit(posLots,linePriceNew,_Symbol,lineSlNew,lineTpNew))
        {
         Print("BuyLimit Placed ",posLots," Lots of ",_Symbol," @ ",linePriceNew," SL = ",lineSlNew, " TP = ",lineTpNew);
        }
     }
   else
     {
      Print("Incorrect input parameters for BuyLimit Double operation");
     }
   return(true);
  }


//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CalculatePosition()
  {
   if(lineInput)
     {
      double percentRisk = NormalizeDouble(StringToDouble(m_RiskEdit.Text()),2);
      double AccountBalance = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
      double AmountToRisk = NormalizeDouble(AccountBalance*percentRisk/100,2);
      double ValuePp = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);

      if(pendingToggle)
        {
         inputPrice = NormalizeDouble(ObjectGetDouble(0,"priceLine",OBJPROP_PRICE),4);
         string inputPriceStr = DoubleToString(inputPrice,4);
         m_PriceEdit.Text(inputPriceStr);
        }

      inputStopLoss = NormalizeDouble(ObjectGetDouble(0,"stopLossLine",OBJPROP_PRICE),4);
      inputTakeProfit = NormalizeDouble(ObjectGetDouble(0,"takeProfitLine",OBJPROP_PRICE),4);

      string inputStopLossStr = DoubleToString(inputStopLoss,4);
      string inputTakeProfitStr = DoubleToString(inputTakeProfit,4);

      m_SlEdit.Text(inputStopLossStr);
      m_TpEdit.Text(inputTakeProfitStr);

      if(pendingToggle)
        {
         calcTpPips = 0.1*MathAbs(inputTakeProfit - inputPrice)/_Point;
         calcSlPips = 0.1*MathAbs(inputStopLoss - inputPrice)/_Point;
        }
      else
         if(!pendingToggle)
           {
            if(sellToggle && !buyToggle) // SELL
              {
               calcTpPips = 0.1*MathAbs(inputTakeProfit - bid)/_Point;
               calcSlPips = 0.1*MathAbs(inputStopLoss - bid)/_Point;
              }
            else
               if(!sellToggle && buyToggle) // BUY
                 {
                  calcTpPips = 0.1*MathAbs(inputTakeProfit - ask)/_Point;
                  calcSlPips = 0.1*MathAbs(inputStopLoss - ask)/_Point;
                 }
           }

      calcRRR = NormalizeDouble(calcTpPips/calcSlPips,1);

      m_TpPipsEdit.Text(DoubleToString(NormalizeDouble(MathRound(calcTpPips),1),0));
      m_SlPipsEdit.Text(DoubleToString(NormalizeDouble(MathRound(calcSlPips),1),0));
      m_RiskToRewardRatioEdit.Text(DoubleToString(MathRound(calcRRR),1));

      double LotsCalculated = 0.01 * NormalizeDouble(AmountToRisk/calcSlPips*10/ValuePp,2);

      string LotsCalculatedStr = DoubleToString(LotsCalculated,2);
      m_LotsEdit.Text(DoubleToString(LotsCalculated,2));
      Print(MathAbs(inputStopLoss-inputPrice));
      Print("SL Pips = ",calcSlPips);
      Print(calcRRR);
      Print("Lots = ", LotsCalculated, " ",LotsCalculatedStr);
     }
   else
      if(!lineInput)
        {
         if(m_RiskEdit.Text() !="" && m_SlPipsEdit.Text() != "")
           {
            double percentRisk = NormalizeDouble(StringToDouble(m_RiskEdit.Text()),2);
            double AccountBalance = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
            double AmountToRisk = NormalizeDouble(AccountBalance*percentRisk/100,2);
            double ValuePp = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);

            double LotsCalculated = NormalizeDouble(AmountToRisk/(StringToDouble(m_SlPipsEdit.Text())*10)/ValuePp,2);

            string LotsCalculatedStr = DoubleToString(LotsCalculated,2);

            if(
               percentRisk > 0 &&
               AccountBalance > 0 &&
               AmountToRisk  > 0 &
               ValuePp > 0 &&
               LotsCalculated > 0
            )
              {
               m_LotsEdit.Text(DoubleToString(LotsCalculated,2));
              }
            else
              {
               Print("Incorrect Input...");
              }
           }
         else
           {
            Print("Not enough Input...");
           }
        }

   return(true);
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
