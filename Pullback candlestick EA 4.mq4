#include <stdlib.mqh>
#define  NL    "\n"

//+------------------------------------------------------------------+
//| EA Parameters                                        |
//+------------------------------------------------------------------+
extern string Expert_Name = "Pullback Candlestick EA 4";
input bool CloseBySignal = True;
extern bool UseHourTrade = true; //If set to TRUE, the EA only active on certain time.      
extern int StartHour = 8, //Time when the EA start active (use with UseHourTrade = TRUE).
		EndHour = 20; //Time when the EA stop active (use with UseHourTrade = TRUE).

//-----------------------------Orders Setting-------------------------------------
int MagicNumber = 12345, NumberOfTries = 10, //Number of try if the order rejected by the system.
		Slippage = 5;  //Slippage setting
int OrderBuy, OrderSell;
int ticket;
input string Koment = "PullbackEA";

//------------------------------Start Strategy Variables----------------------------------------------
double SetupCandleRange;
static int TimeFrame = 0;
bool ExitHalf;

//------------------------------Relative Strength Index------------------------------------
extern double Stoploss = 100;
input int RSIperiod = 8;
input double BuyLevel = 50;
input double SellLevel = 50;

//------------------------------Moving Average------------------------------------
extern int MAType = 0,    //0:SMA 1:EMA 2:SMMA 3:LWMA
		MAPrice = 0, //0:Close 1:Open 2:High 3:Low 4:Median 5:Typical 6:Weighted
		MAshift = 0;    //Moving Average Shift

//------------------------------End Strategy Variables----------------------------------------------

//-----------------------------Start Multi Purpose Trade Management Variables------------------------
extern string MM_Parameters = "---------- Money Management";
extern double Lots = 1.0; //Number of lot per trade.
extern bool MM = true, //If set to TRUE, will use build in money management.
		AccountIsMicro = true; //If using Micro Account set this to TRUE.
extern int Risk = 5; //Use with MM = TRUE to set the risk per trade. 10 = 10% Equity

// These allow the EA to run AlwaysOn even without any ticks
extern string b10 = "===== AlwaysOn =====";
extern bool AlwaysOn = false; // EA Run every delay (ms) (true) or every ticks (false)
extern int delay = 1000;	//====== Time (ms) restart adviser in AlwaysOn mode
// User can choose a variety of trade managment triggers.
// These are for use on a chart that controls the currency of that chart
extern string ManagementStyle = "You can select more than one option";
extern bool ManageByMagicNumber = false;
//extern int     MagicNumber=1;
extern bool ManageByTradeComment = false;
extern string TradeComment = "Fib";
extern bool ManageByTickeNumber = false;
extern int TicketNumber;
extern string OverRide = "ManageThisPairOnly will override all previous";
extern string OverRide2 = "or can be used in combination with 1 of above";
extern bool ManageThisPairOnly = true;
extern bool ManageSpecifiedPairs = false;		//############## ADDED BY CACUS
extern string PairsToManage =
		"AUDJPY,AUDUSD,CHFJPY,EURCHF,EURGBP,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDJPY,NZDUSD,USDCHF,USDJPY";//############## ADDED BY CACUS
// This allows the ea to manage all existing trades
extern string OverRide1 = "ManageAllTrades will override all others";
extern bool ManageAllTrades = false;
extern bool ManagingNanningbobTrades = false;

// Now give user a variety of facilities
extern string bl1 =
		"---------------------------------------------------------------------";
extern string ManagementFacilities = "Select the management facilities you want";
extern string slf = "----Stop Loss & Take Profit Manipulation----";
extern bool DoNotOverload5DigitCriminals = false;
extern string BE = "Break even settings";
extern bool BreakEven = true;
extern int BreakEvenPips = 50; //must be single digit for GBPUSD
extern int BreakEvenProfit = 10; //must be single digit for GBPUSD
extern bool HideBreakEvenStop = false;
extern int PipsAwayFromVisualBE = 100;
extern string JSL = "Jumping stop loss settings";
extern bool JumpingStop = false;
extern int JumpingStopPips = 100;
extern bool AddBEP = false;
extern bool JumpAfterBreakevenOnly = true;
extern bool HideJumpingStop = false;
extern int PipsAwayFromVisualJS = 100;
extern string pcbe = "PartClose settings can be used in";
extern string pcbe1 = "conjunction with Breakeven settings";
extern bool PartCloseEnabled = false;
extern double Close_Lots = 0.02;
extern double Preserve_Lots = 0.02;
extern string TSL = "Trailing stop loss settings";
extern bool TrailingStop = false;

extern string bl3 =
		"---------------------------------------------------------------------";
extern string hs = "----Hedge settings----";
extern bool HedgeEnabled = true;
extern int HedgeAtLossPips = 10;
extern double HedgeLotsPercent = 100;
extern int HedgingIncrementPips = 10000000;
extern int HedgeTradeStopLoss = 0;
extern int HedgeTradeTakeProfit = 0;
extern bool CloseAtBreakEven = false;
extern bool HedgingTheHedgeIsAllowed = false;
extern double HedgeTheHedgeLotsPercent = 200;

extern string bl4 =
		"---------------------------------------------------------------------";
extern string OtherStuff = "----Other stuff----";
extern bool ShowAlerts = true;
// Added by Robert for those who do not want the comments.
extern bool ShowComments = false;
// Added by Robert for those who do not want the journal messages.
extern bool PrintToJournal = false;

double LockedProfit = -1;
int cnt = 0; //loop counter
double bid, ask; // For storing the Bid\Ask so that one instance of the ea can manage all trades, if required
double point, digits; // Saves the Point and Digits of an order
// Variables for part-close reoutine

//############## ADDED BY CACUS
string String;
int PairsQty;
string suffix;
string ManagePair[20];

//-----------------------------End Multi Purpose Trade Management Variables------------------------

//+------------------------------------------------------------------+
// End of EA Parameters                                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {

	return (0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
//----

//----
	return (0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {

	double rsi = iRSI(Symbol(), 0, RSIperiod, PRICE_CLOSE, 0);
	double rsi1 = iRSI(Symbol(), 0, RSIperiod, PRICE_CLOSE, 1);

	double min50MACurrent, min200MACurrent;
	string condition = "";

	bool result;
	int err;

	// Moving Average Variables
	min50MACurrent = iMA(NULL, TimeFrame, 50, MAshift, MAType, MAPrice, 0);
	min200MACurrent = iMA(NULL, TimeFrame, 200, MAshift, MAType, MAPrice, 0);

	double stoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
	OrderBuy = 0;
	OrderSell = 0;

	if (UseHourTrade && (Hour() >= StartHour && Hour() <= EndHour)) {

		OrderSelect(0, SELECT_BY_POS, MODE_TRADES);

		if (OrdersTotal() == 0) {

			//----------------------------------ENTRY CONDITION----------------------------------------------

			//SELL CONDITION 1
			if (Close[0] < min50MACurrent
					&& High[1] > High[iHighest(NULL, 0, MODE_HIGH, 4, 2)]
					&& Close[1] - High[1] < (Low[1] - High[1]) * 0.75
					&& Close[0] < Low[1] && rsi < SellLevel) {

				ticket = OrderSend(Symbol(), OP_SELL, 1, Bid, Slippage,
						High[1] + 10 * Point, 0, Koment, MagicNumber, 0,
						DeepPink);
				SetupCandleRange = High[1] - Low[1];
				ExitHalf = false;
				BreakEven = false;
			}

			//SELL CONDITION 2
			else if (Close[0] < min50MACurrent
					&& High[2] > High[iHighest(NULL, 0, MODE_HIGH, 4, 3)]
					&& Close[2] - High[2] > (Low[2] - High[2]) * 0.75
					&& Close[1] - High[1] < (Low[1] - High[1]) * 0.75
					&& Close[0] < Low[1] && rsi < SellLevel

					) {
				ticket = OrderSend(Symbol(), OP_SELL, 1, Bid, Slippage,
						High[2] + 10 * Point, 0, Koment, MagicNumber, 0,
						DeepPink);
				SetupCandleRange = High[1] - Low[1];
				ExitHalf = false;
				BreakEven = false;
			}

			//BUY CONDITION 1
			else if (Close[0] > min50MACurrent
					&& Low[1] < Low[iLowest(NULL, 0, MODE_LOW, 4, 2)]
					&& Close[1] - Low[1] > 0.75 * (High[1] - Low[1])
					&& Close[0] > High[1] && rsi > BuyLevel

					) {

				// OPBUY();
				ticket = OrderSend(Symbol(), OP_BUY, 1, Ask, Slippage,
						Low[1] - 10 * Point, 0, Koment, MagicNumber, 0,
						DodgerBlue);
				SetupCandleRange = High[1] - Low[1];
				ExitHalf = false;
				BreakEven = false;

			}

			//BUY CONDITION 2
			else if (Close[0] > min50MACurrent
					&& Low[2] < Low[iLowest(NULL, 0, MODE_LOW, 4, 3)]
					&& Close[2] - Low[2] < 0.75 * (High[2] - Low[2])
					&& Close[1] - Low[1] > 0.75 * (High[1] - Low[1])
					&& Close[0] > High[1] && rsi > BuyLevel) {
				ticket = OrderSend(Symbol(), OP_BUY, 1, Ask, Slippage,
						Low[2] - 10 * Point, 0, Koment, MagicNumber, 0,
						DodgerBlue);
				SetupCandleRange = High[1] - Low[1];
				ExitHalf = false;
				BreakEven = false;

			}

		}

	}

//----------------------------------EXIT CONDITION----------------------------------------------

	if (OrdersTotal() > 0) {

//--- close position by signal
		if (CloseBySignal) {

			OrderSelect(0, SELECT_BY_POS, MODE_TRADES);

			double TakeProfitPips = OrderProfit() / OrderLots()
					/ MarketInfo(OrderSymbol(), MODE_TICKVALUE) / 10;

			//Standard exit 1 exit half lots
			if (ExitHalf == false) {
				if ((OrderType() == 0
						&& Close[0] > OrderOpenPrice() + SetupCandleRange)
						|| (OrderType() == 1
								&& Close[0]
										< OrderOpenPrice() - SetupCandleRange)) {

					if (OrderType() == OP_BUY)
						OrderClose(OrderTicket(), OrderLots() / 2,
								MarketInfo(OrderSymbol(), MODE_BID), 5);
					else if (OrderType() == OP_SELL)
						OrderClose(OrderTicket(), OrderLots() / 2,
								MarketInfo(OrderSymbol(), MODE_ASK), 5);
					ExitHalf = true;
				}

			}

			//Exit 2 market deciding price exit (trailing stop loss)
			if ((OrderType() == 0
					&& Close[0] > OrderOpenPrice() + SetupCandleRange / 2)
					|| (OrderType() == 1
							&& Close[0]
									< OrderOpenPrice() - SetupCandleRange / 2)) {
				BreakEven = true;
				JumpingStop = true;
				JumpingStopPips = SetupCandleRange / 2 / Point;

			} else {
				JumpingStop = false;
				BreakEven = false;
			}

		}
	}

//-----------------------Trade Management for breakeven and trailing stop ----------------------------------------------

	if (AlwaysOn == true) {
		while (IsExpertEnabled()) // Check if expert advisors are enabled for running
		{		// This is an infinite loop so the expert doesn't wait for ticks
			main();
			Sleep(delay);
			WindowRedraw();
		}
	} else {
		main();
	}

}

//+------------------------------------------------------------------+
//| End Start function                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Methods and Functions                                          |
//+------------------------------------------------------------------+

int PairsQty() {
	int i = 0;
	int j;
	int qty = 0;

	while (i > -1) {
		i = StringFind(String, ",", j);
		if (i > -1) {
			qty++;
			j = i + 1;
		}
	}
	return (qty);
}

void MonitorTrades() {

	bool ManageTrade; // tell the program when there is a trade to manage
	string ScreenMessage;

	for (cnt = OrdersTotal() - 1; cnt >= 0; cnt--) {
		if (OrderSelect(cnt, SELECT_BY_POS)) {
			//If there are >1 trades open, then we must be into Recovery, and so do not want
			//indiidual trade management
			bool abort = false;
			if (ManagingNanningbobTrades) {
				int ticket = OrderTicket();
				string sSymbol = OrderSymbol();
				for (int cc = cnt - 1; cc >= 0; cc--) {
					if (!OrderSelect(cc, SELECT_BY_POS))
						continue;
					if (OrderSymbol() == sSymbol) {
						abort = true;
						break;
					}         //if (OrderSymbol() == sSymbol)                  
				}         //for (int cc = cnt - 1; cc >= 0; cc --)
				OrderSelect(ticket, SELECT_BY_TICKET);
			}         //if (ManagingNanningbobTrades)
			if (abort)
				continue;

			ManageTrade = false;
			ScreenMessage = "Managing by: ";
			// Set up bid and ask so the program can use them to calculate jumping stops, be's etc
			bid = MarketInfo(OrderSymbol(), MODE_BID);
			ask = MarketInfo(OrderSymbol(), MODE_ASK);
			point = MarketInfo(OrderSymbol(), MODE_POINT);
			digits = MarketInfo(OrderSymbol(), MODE_DIGITS);

			// Test whether this individual trade needs managing
			// MagicNumber
			if (ManageByMagicNumber && OrderMagicNumber() == MagicNumber) {
				ManageTrade = true;
				ScreenMessage = StringConcatenate(ScreenMessage,
						"Magic Number=", MagicNumber, "; ");
			}
			if (ManageByMagicNumber && !OrderMagicNumber() == MagicNumber) {
				ScreenMessage = StringConcatenate(ScreenMessage,
						"Magic Number=", MagicNumber, "; ");
			}

			// TradeComment
			if (ManageByTradeComment && OrderComment() == TradeComment) {
				ManageTrade = true;
				ScreenMessage = StringConcatenate(ScreenMessage,
						"Trade Comment=", TradeComment, "; ");
			}
			if (ManageByTradeComment && OrderComment() != TradeComment) {
				ScreenMessage = StringConcatenate(ScreenMessage,
						"Trade Comment=", TradeComment, "; ");
			}

			// ManageByTickeNumber
			if (ManageByTickeNumber && OrderTicket() == TicketNumber) {
				ManageTrade = true;
				ScreenMessage = StringConcatenate(ScreenMessage,
						"Ticket Number=", TicketNumber, "; ");
			}
			if (ManageByTickeNumber && !OrderTicket() == TicketNumber) {
				ScreenMessage = StringConcatenate(ScreenMessage,
						"Ticket Number=", TicketNumber, "; ");
			}

			if (ManageThisPairOnly && OrderSymbol() == Symbol()) {
				ManageTrade = true;
				ScreenMessage = "Managing this pair only";
			}

			if (ManageThisPairOnly && OrderSymbol() != Symbol()) {
				ManageTrade = false;
				ScreenMessage = "Managing this pair only";
			}
			//############## ADDED BY CACUS
			if (ManageSpecifiedPairs) {
				for (int d = 0; d < PairsQty(); d++) {
					if (OrderSymbol() == ManagePair[d]) {
						ManageTrade = true;
						ScreenMessage = "Managing selected pairs only";
					}
				}
			}
			//############## ADDED BY CACUS

			// Allow for combinations of pair management
			if (ManageThisPairOnly && OrderSymbol() == Symbol()) {
				if (ManageByMagicNumber)
					ScreenMessage = StringConcatenate(ScreenMessage,
							" by MagicNumber = ", MagicNumber);
				if (ManageByMagicNumber && !OrderMagicNumber() == MagicNumber) {
					ManageTrade = false;
				}
			}

			if (ManageThisPairOnly && OrderSymbol() == Symbol()) {
				if (ManageByTradeComment)
					ScreenMessage = StringConcatenate(ScreenMessage,
							" by TradeComment = ", TradeComment);
				if (ManageByTradeComment && OrderComment() != TradeComment) {
					ManageTrade = false;
				}
			}

			if (ManageThisPairOnly && OrderSymbol() == Symbol()) {
				if (ManageByTickeNumber)
					ScreenMessage = StringConcatenate(ScreenMessage,
							" by TicketNumber = ", TicketNumber);
				if (ManageByTickeNumber && !OrderTicket() == TicketNumber) {
					ManageTrade = false;
				}
			}

			// ManageAllTrades
			if (ManageAllTrades) {
				ManageTrade = true;
				ScreenMessage = "Managing all open trades";
			}

			// Is this trade being managed by the ea?
			if (ManageTrade)
				ManageTrade(); // The subroutine that calls the other working subroutines

		} // Close if (OrderSymbol()==Symbol())

	} // Close For loop

	if (BreakEven) {
		ScreenMessage = StringConcatenate(ScreenMessage, NL,
				"Break even set to ", BreakEvenPips,
				". BreakEvenProfit is set to ", BreakEvenProfit, " pips");
	} else {
		ScreenMessage = StringConcatenate(ScreenMessage, NL,
				"Break even disabled");
	}

	if (JumpingStop == true) {
		ScreenMessage = StringConcatenate(ScreenMessage, NL,
				"Jumping stop set to ", JumpingStopPips);
		if (JumpAfterBreakevenOnly)
			ScreenMessage = StringConcatenate(ScreenMessage,
					" after breakeven is achieved");
		if (AddBEP == true) {
			ScreenMessage = StringConcatenate(ScreenMessage,
					", also adding BreakEvenProfit (", BreakEvenProfit,
					" pips)");
		}
	}

	// Comment(ScreenMessage); // User feedback

} // end of MonitorTrades

void JumpingStopLoss() {
	// Jump sl by pips and at intervals chosen by user .
	// Also carry out partial closure if the user requires this

	// Abort the routine if JumpAfterBreakevenOnly is set to true and be sl is not yet set
	if (JumpAfterBreakevenOnly && OrderType() == OP_BUY) {
		if (OrderStopLoss() < OrderOpenPrice())
			return (0);
	}

	if (JumpAfterBreakevenOnly && OrderType() == OP_SELL) {
		if (OrderStopLoss() > OrderOpenPrice())
			return (0);
	}

	double sl = OrderStopLoss(); //Stop loss

	if (OrderType() == OP_BUY) {

		// First check if sl needs setting to breakeven
		if (sl == 0 || sl < OrderOpenPrice()) {
			if (ask >= OrderOpenPrice() + (JumpingStopPips * point)) {
				sl = OrderOpenPrice();
				if (AddBEP == true)
					sl = sl + (BreakEvenProfit * point); // If user wants to add a profit to the break even
				bool result = OrderModify(OrderTicket(), OrderOpenPrice(), sl,
						OrderTakeProfit(), 0, CLR_NONE);
				if (result) {
					if (ShowAlerts == true)
						Alert("Jumping stop set at breakeven ", sl, " ",
								OrderSymbol(), " ticket no ", OrderTicket());
					Print("Jumping stop set at breakeven: ", OrderSymbol(),
							": SL ", sl, ": Ask ", ask);

				} //if (result)
				if (!result) {
					int err = GetLastError();
					if (ShowAlerts)
						Alert(OrderSymbol(),
								" buy trade. Jumping stop function failed to set SL at breakeven, with error(",
								err, "): ", ErrorDescription(err));
					Print(OrderSymbol(),
							" buy trade. Jumping stop function failed to set SL at breakeven, with error(",
							err, "): ", ErrorDescription(err));
				} //if (!result)

				return (0);
			} //if (ask >= OrderOpenPrice() + (JumpingStopPips*point))
		} //close if (sl==0 || sl<OrderOpenPrice()

		// Increment sl by sl + JumpingStopPips.
		// This will happen when market price >= (sl + JumpingStopPips)
		if (bid >= sl + ((JumpingStopPips * 2) * point)
				&& sl >= OrderOpenPrice()) {
			sl = sl + (JumpingStopPips * point);
			result = OrderModify(OrderTicket(), OrderOpenPrice(), sl,
					OrderTakeProfit(), 0, CLR_NONE);
			if (result) {
				if (ShowAlerts == true)
					Alert("Jumping stop set at ", sl, " ", OrderSymbol(),
							" ticket no ", OrderTicket());
				Print("Jumping stop set: ", OrderSymbol(), ": SL ", sl,
						": Ask ", ask);

			}      //if (result)
			if (!result) {
				err = GetLastError();
				if (ShowAlerts)
					Alert(OrderSymbol(),
							" buy trade. Jumping stop function failed with error(",
							err, "): ", ErrorDescription(err));
				Print(OrderSymbol(),
						" buy trade. Jumping stop function failed with error(",
						err, "): ", ErrorDescription(err));
			}      //if (!result)

		} // if (bid>= sl + (JumpingStopPips*point) && sl>= OrderOpenPrice())      
	}      //if (OrderType()==OP_BUY)

	if (OrderType() == OP_SELL) {

		// First check if sl needs setting to breakeven
		if (sl == 0 || sl > OrderOpenPrice()) {
			if (ask <= OrderOpenPrice() - (JumpingStopPips * point)) {
				sl = OrderOpenPrice();
				if (AddBEP == true)
					sl = sl - (BreakEvenProfit * point); // If user wants to add a profit to the break even
				result = OrderModify(OrderTicket(), OrderOpenPrice(), sl,
						OrderTakeProfit(), 0, CLR_NONE);
				if (result) {

				} //if (result)
				if (!result) {
					err = GetLastError();
					if (ShowAlerts)
						Alert(OrderSymbol(),
								" sell trade. Jumping stop function failed to set SL at breakeven, with error(",
								err, "): ", ErrorDescription(err));
					Print(OrderSymbol(),
							" sell trade. Jumping stop function failed to set SL at breakeven, with error(",
							err, "): ", ErrorDescription(err));
				} //if (!result)

				return (0);
			} //if (ask <= OrderOpenPrice() - (JumpingStopPips*point))
		} // if (sl==0 || sl>OrderOpenPrice()

		// Decrement sl by sl - JumpingStopPips.
		// This will happen when market price <= (sl - JumpingStopPips)
		if (bid <= sl - ((JumpingStopPips * 2) * point)
				&& sl <= OrderOpenPrice()) {
			sl = sl - (JumpingStopPips * point);
			result = OrderModify(OrderTicket(), OrderOpenPrice(), sl,
					OrderTakeProfit(), 0, CLR_NONE);
			if (result) {
				if (ShowAlerts == true)
					Alert("Jumping stop set at ", sl, " ", OrderSymbol(),
							" ticket no ", OrderTicket());
				Print("Jumping stop set: ", OrderSymbol(), ": SL ", sl,
						": Ask ", ask);

			}      //if (result)          
			if (!result) {
				err = GetLastError();
				if (ShowAlerts)
					Alert(OrderSymbol(),
							" sell trade. Jumping stop function failed with error(",
							err, "): ", ErrorDescription(err));
				Print(OrderSymbol(),
						" sell trade. Jumping stop function failed with error(",
						err, "): ", ErrorDescription(err));
			}      //if (!result)

		} // close if (bid>= sl + (JumpingStopPips*point) && sl>= OrderOpenPrice())         
	}      //if (OrderType()==OP_SELL)

} //End of JumpingStopLoss sub

void ManageTrade() {

	// Call the working subroutines one by one. 

	//Cut down 5 digit order modify calls for 5 digit crims, if required
	static int NoOfTicks = 9;
	int ndigits = MarketInfo(Symbol(), MODE_DIGITS);
	if (DoNotOverload5DigitCriminals && (ndigits == 3 || ndigits == 5)) {
		NoOfTicks++;
	} //if (DoNotOverload5DigitCriminals && ( digits == 3 || digits == 5) )

	if (!DoNotOverload5DigitCriminals || ndigits == 2 || ndigits == 4) {
		NoOfTicks = 10;
	} //if (!DoNotOverload5DigitCriminals || digits == 2 || digits == 4)

	// Breakeven
	if (BreakEven)
		BreakEvenStopLoss();

	// JumpingStop
	if (JumpingStop)
		JumpingStopLoss();

	// AutoStopLoss
	// if(AutoStopLoss) AutoSetStopLoss();

} // End of ManageTrade()

void main() {

	if (OrdersTotal() > 1) {
		BreakEven = False;
		JumpingStop = False;
	} else {
		BreakEven = True;
		//JumpingStop=True;
	}

	//############## ADDED BY CACUS
	suffix = StringSubstr(Symbol(), 6, 4);
	int qty = PairsQty();

	int i = 0;
	int j = 0;
	for (int k = 0; k < qty; k++) {
		i = StringFind(String, ",", j);
		if (i > -1) {
			ManagePair[k] = StringSubstr(String, j, i - j);
			ManagePair[k] = StringTrimLeft(ManagePair[k]);
			ManagePair[k] = StringTrimRight(ManagePair[k]);
			ManagePair[k] = StringConcatenate(ManagePair[k], suffix);
			j = i + 1;
		}
	}

	// Stop if there is nothing to do
	if (OrdersTotal() == 0) {
		if (ShowComments)
			Comment("No trades to manage. I am bored witless.");
		return (0);
	}

	MonitorTrades(); // Stop loss adjusting, part closure etc

} //end void main()

void BreakEvenStopLoss() // Move stop loss to breakeven
{

	bool result;
	//Print("OrderOpenPrice()+(BreakEvenProfit*Point)", OrderOpenPrice()+(BreakEvenProfit*Point));

	if (OrderType() == OP_BUY) {
		if (bid >= OrderOpenPrice() + (Point * BreakEvenPips)
				&& OrderStopLoss() < OrderOpenPrice()
				&& OrderOpenPrice() + (BreakEvenProfit * Point)
						!= OrderStopLoss()) {
			result = OrderModify(OrderTicket(), OrderOpenPrice(),
					OrderOpenPrice() + (BreakEvenProfit * Point),
					OrderTakeProfit(), 0, CLR_NONE);
			if (result && ShowAlerts == true)
				Alert("Breakeven set on ", OrderSymbol(), " ticket no ",
						OrderTicket());
			Print("Breakeven set on ", OrderSymbol(), " ticket no ",
					OrderTicket());
			if (!result) {
				int err = GetLastError();
				if (ShowAlerts == true)
					Alert("Setting of breakeven SL ", OrderSymbol(),
							" ticket no ", OrderTicket(),
							" failed with error (", err, "): ",
							ErrorDescription(err));
				Print("Setting of breakeven SL ", OrderSymbol(), " ticket no ",
						OrderTicket(), " failed with error (", err, "): ",
						ErrorDescription(err));
			} //if !result && ShowAlerts)      

		}
	}

	if (OrderType() == OP_SELL) {
		if (ask <= OrderOpenPrice() - (Point * BreakEvenPips)
				&& (OrderStopLoss() > OrderOpenPrice() || OrderStopLoss() == 0)
				&& OrderStopLoss()
						!= OrderOpenPrice() - (BreakEvenProfit * Point)) {
			result = OrderModify(OrderTicket(), OrderOpenPrice(),
					OrderOpenPrice() - (BreakEvenProfit * Point),
					OrderTakeProfit(), 0, CLR_NONE);
			if (result && ShowAlerts == true)
				Alert("Breakeven set on ", OrderSymbol(), " ticket no ",
						OrderTicket());
			Print("Breakeven set on ", OrderSymbol(), " ticket no ",
					OrderTicket());
			if (!result && ShowAlerts) {
				err = GetLastError();
				if (ShowAlerts == true)
					Alert("Setting of breakeven SL ", OrderSymbol(),
							" ticket no ", OrderTicket(),
							" failed with error (", err, "): ",
							ErrorDescription(err));
				Print("Setting of breakeven SL ", OrderSymbol(), " ticket no ",
						OrderTicket(), " failed with error (", err, "): ",
						ErrorDescription(err));
			} //if !result && ShowAlerts)      

		}
	}

} // End BreakevenStopLoss sub

//+------------------------------------------------------------------+
//| End Methods and Functions                                          |
//+------------------------------------------------------------------+
