
 //+------------------------------------------------------------------+
 //|                                            ScenarioFunctions.mq4 |
 //|                        Copyright 2017, MetaQuotes Software Corp. |
 //|                                             https://www.mql5.com |
 //+------------------------------------------------------------------+
 #property library
 #property copyright "Copyright 2017, MetaQuotes Software Corp."
 #property link      "https://www.mql5.com"
 #property version   "1.00"
 #property strict
 #include <stdlib.mqh>

// this function returns a double value for the nth fractal
// nbr is the nth number of fractal that you want, 0 is most recent fractal
// mode can be MODE_LOWER for up fractal or MODE_UPPER for down fractal
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc

 double findFractal(int nbr, int mode, int timeframe) export {
 int i = 3, n;
 for (n = 0; n <= nbr; n++) {
 while (iFractals(Symbol(), timeframe, mode, i) == 0)
 i++;
 if (n < nbr)
 i++;
 }
 return (iFractals(Symbol(), timeframe, mode, i));
 }
 
// this function returns the candlestick position ith when the nth fractal first appear
// nbr is the nth number of fractal that you want, 0 is most recent
// mode can be MODE_LOWER for up fractal or MODE_UPPER for down fractal
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc

 int findFractalCandle(int nbr, int mode, int timeframe) export {
 int i = 3, n;
 for (n = 0; n <= nbr; n++) {
 while (iFractals(Symbol(), timeframe, mode, i) == 0)
 i++;
 if (n < nbr)
 i++;
 }
 return (i);
 }

// this function returns a double value for the nth fractal
// nbr is the nth number of fractal that you want, 0 is most recent fractal
// mode can be MODE_LOWER for up fractal or MODE_UPPER for down fractal
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc
// candle is nth candlestick in your chart

 double findFractalWithCandleInput(int nbr, int mode, int timeframe,
 int candle) export {
 int i = candle + 3, n;
 for (n = 0; n <= nbr; n++) {
 while (iFractals(Symbol(), timeframe, mode, i) == 0)
 i++;
 if (n < nbr)
 i++;
 }
 return (iFractals(Symbol(), timeframe, mode, i));
 }


// this function returns true if the nth fractal reversal candle is larger and 
// false if smaller than momentum candle preceding it in its 5 candle formation
// nbr is the nth number of fractal that you want, 0 is most recent fractal
// mode can be MODE_LOWER for up fractal or MODE_UPPER for down fractal
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc
// candle is nth candlestick in your chart
// operation can be Buy or Sell and this method is used to trade on price reversal

 bool FractalReversalStrong(int nbr, int mode, int timeframe, int candle,
 string operation) export {
 int i = candle + 3, n;
 bool FractalMomentumCandleNotLarger = false;

 for (n = 0; n <= nbr; n++) {
 while (iFractals(Symbol(), timeframe, mode, i) == 0)
 i++;
 if (n < nbr)
 i++;
 }

 if (operation == "Buy") {
 //if most recent fractal candle is falling
 if (Close[i] < Open[i]
 && ((MathAbs(Close[i - 1] - Open[i - 1])
 > MathAbs(Close[i] - Open[i])
 && Close[i - 1] > Open[i - 1])
 || (MathAbs(Close[i - 2] - Open[i - 2])
 > MathAbs(Close[i] - Open[i])
 && Close[i - 2] > Open[i - 2]))) {
 FractalMomentumCandleNotLarger = true;
 }

 //if most recent fractal candle is rising
 if (Close[i] > Open[i]
 && ((MathAbs(Close[i] - Open[i])
 > MathAbs(Close[i + 1] - Open[i + 1]))
 || (MathAbs(Close[i - 1] - Open[i - 1])
 > MathAbs(Close[i + 1] - Open[i + 1])
 && Close[i - 1] > Open[i - 1])
 || (MathAbs(Close[i - 2] - Open[i - 2])
 > MathAbs(Close[i + 1] - Open[i + 1])
 && Close[i - 2] > Open[i - 2]))) {
 FractalMomentumCandleNotLarger = true;
 }

 }
 //operation is sell
 else {
 //if most recent fractal candle is rising
 if (Close[i] > Open[i]
 && ((MathAbs(Close[i - 1] - Open[i - 1])
 > MathAbs(Close[i] - Open[i])
 && Close[i - 1] < Open[i - 1])
 || (MathAbs(Close[i - 2] - Open[i - 2])
 > MathAbs(Close[i] - Open[i])
 && Close[i - 2] < Open[i - 2]))) {
 FractalMomentumCandleNotLarger = true;
 }

 //if most recent fractal is falling
 if (Close[i] < Open[i]
 && ((MathAbs(Close[i] - Open[i])
 > MathAbs(Close[i + 1] - Open[i + 1]))
 || (MathAbs(Close[i - 1] - Open[i - 1])
 > MathAbs(Close[i + 1] - Open[i + 1])
 && Close[i - 1] < Open[i - 1])
 || (MathAbs(Close[i - 2] - Open[i - 2])
 > MathAbs(Close[i + 1] - Open[i + 1])
 && Close[i - 2] < Open[i - 2]))) {
 FractalMomentumCandleNotLarger = true;
 }

 }

 return FractalMomentumCandleNotLarger;
 }

//this method enforce the Expert Advisor to auto trail your profits 1 pip behind the most recent fractal formed
//this method only execute when you are in profit
//lastUpFractal is most recent Up fractal
//lastDownFractal is the most recent Down fractal
//the 2 paremeters passed in must be declared outside the start() body

 void TrailByFractal(double lastUpFractal, double lastDownFractal) export
 {

 if (OrdersTotal() > 0) {

 //Start Trail by fractal FOR BUY
 if (OrderType() == 0) {

 if (lastDownFractal != findFractal(0, MODE_LOWER, 0)) {
 lastDownFractal = findFractal(0, MODE_LOWER, 0);

 if (lastDownFractal > OrderStopLoss()
 && lastDownFractal > OrderOpenPrice() + 20 * Point
 ) {

 int ticket = OrderModify(OrderTicket(), OrderOpenPrice(),
 lastDownFractal - 10 * Point, OrderTakeProfit(), 0,
 Blue);

 }
 }

 }
 //End Trail by fractal FOR BUY   

 //Start Trail by fractal FOR SELL
 if (OrderType() == 1) {
 if (lastUpFractal != findFractal(0, MODE_UPPER, 0)) {
 lastUpFractal = findFractal(0, MODE_UPPER, 0);

 if (lastUpFractal < OrderStopLoss()
 && lastUpFractal < OrderOpenPrice() - 20 * Point
 ) {

 int ticket = OrderModify(OrderTicket(), OrderOpenPrice(),
 lastUpFractal + 10 * Point, OrderTakeProfit(), 0,
 Blue);

 }
 }
 }
 //End Trail by fractal FOR SELL 

 }
 }	

// this function returns true if the current price is X number of pips away from most recent fractal
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc
// candle is nth candlestick in your chart
// operation can be Buy or Sell and this method is used to trade on price reversal
// pips is the number of pips away from current price
// includeLastSecond is set to true to check if the current price is X number of pips away from last second fractal
// includeOpposite is set to true to check if the current price is X number of pips away from a last opposite fractal, meaning for buy, the fractal is a lower fractal

 bool LastReversalFractalNotNear(int candle, string operation,  int pips, int timeframe, bool includeLastSecond, bool includeOpposite) export
 {     
 bool LastReversalFractalNotNear=true;
 
 if(operation=="Buy")
 {

 if(MathAbs(Close[candle] - findFractal(0, MODE_UPPER, timeframe)) < pips*Point*10
 && findFractal(0, MODE_UPPER, timeframe)>Close[candle] )
 {
 LastReversalFractalNotNear=false;
 }
 else if(MathAbs(Close[candle] - findFractal(1, MODE_UPPER, timeframe)) < pips*Point*10
 && findFractal(1, MODE_UPPER, timeframe)>Close[candle] 
 && includeLastSecond)
 {
 LastReversalFractalNotNear=false;
 }   
 if(MathAbs(Close[candle] - findFractal(1, MODE_LOWER, timeframe)) < pips*Point*10
 && findFractal(1, MODE_LOWER, timeframe)>Close[candle] 
 && includeOpposite)
 {
 LastReversalFractalNotNear=false;
 }  
 
 }
 
 else if(operation=="Sell")
 {
 if(MathAbs(Close[candle] - findFractal(0, MODE_LOWER, timeframe)) < pips*Point*10
 && findFractal(0, MODE_LOWER, timeframe)<Close[candle])
 {
 LastReversalFractalNotNear=false;
 }
 
 else  if(MathAbs(Close[candle] - findFractal(1, MODE_LOWER, timeframe)) < pips*Point*10
 && findFractal(1, MODE_LOWER, timeframe)<Close[candle]
 && includeLastSecond)
 {
 LastReversalFractalNotNear=false;
 }
 else  if(MathAbs(Close[candle] - findFractal(1, MODE_UPPER, timeframe)) < pips*Point*10
 && findFractal(1, MODE_UPPER, timeframe)<Close[candle]
 && includeOpposite)
 {
 LastReversalFractalNotNear=false;
 }
 
 }

 return LastReversalFractalNotNear;
 
 }
 
// this function returns true if the current price is X number of pips away from last 4 most recent zigzag peaks and bottoms
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc
// candle is nth candlestick in your chart
// operation can be Buy or Sell and this method is used to trade on price reversal
// pips is the number of pips away from current price
// checkForLeglength is set to true to check if the current zigzag line is at least X number of pips in length, the longer the more likely it will reverse
// legLength is the number of pips in length of the current zigzag line

 bool ZigZagsIsNotNear(int candle,string operation, int timeframe, int pips, bool checkForLeglength, int legLength) export
 {
 
 bool ZigZagsIsNotNear =false;
 //Zigzag variables
 double LastUpZigZag, LastDownZigZag, LastSecondUpZigZag, LastSecondDownZigZag,
 LastThirdUpZigZag, LastThirdDownZigZag, LastUpZigZagMove,
 LastSecondUpZigZagMove, LastDownZigZagMove, LastSecondDownZigZagMove,
 LastZigZagMove, LastZigZag, LastDownZZ, LastUpZZ;

 datetime LastUpZigZagTime, LastDownZigZagTime, LastSecondUpZigZagTime,
 LastSecondDownZigZagTime, LastThirdUpZigZagTime,
 LastThirdDownZigZagTime, LastDownZZTime, LastUpZZTime;
 double pipsmultiplier;		
 double leg1,leg2, avgleg;

 //Zigzag calculation
 double SwingValue[4];
 datetime SwingTime[4];
 int Found = 0;
 int m = candle;
 while (Found <= 3) {
 if (iCustom(NULL, timeframe, "ZigZag", 12, 5, 3, 0, m) != 0) {
 
 SwingValue[Found] = iCustom(NULL, timeframe, "ZigZag", 12, 5, 3,
 0, m);
 SwingTime[Found] = iTime(NULL, 0, m);
 Found++;
 }
 m++;
 }
 

 if (SwingValue[0] > SwingValue[1]) {

 LastUpZigZag = SwingValue[0];
 LastDownZigZag = SwingValue[1];
 LastSecondUpZigZag = SwingValue[2];
 LastSecondDownZigZag = SwingValue[3];
 /*  LastThirdUpZigZag=SwingValue[4];
 LastThirdDownZigZag=SwingValue[5];
 LastUpZigZagTime=SwingTime[0];
 LastDownZigZagTime=SwingTime[1];
 LastSecondUpZigZagTime=SwingTime[2];
 LastSecondDownZigZagTime=SwingTime[3];
 LastThirdUpZigZagTime=SwingTime[4];
 LastThirdDownZigZagTime=SwingTime[5];
 
 LastDownZZ =LastDownZigZag;
 LastDownZZTime =LastDownZigZagTime;*/
}

else {
LastDownZigZag = SwingValue[0];
LastUpZigZag = SwingValue[1];
LastSecondDownZigZag = SwingValue[2];
LastSecondUpZigZag = SwingValue[3];
/*  LastThirdDownZigZag=SwingValue[4];
 LastThirdUpZigZag=SwingValue[5];
 LastDownZigZagTime=SwingTime[0];
 LastUpZigZagTime=SwingTime[1];
 LastSecondDownZigZagTime=SwingTime[2];
 LastSecondUpZigZagTime=SwingTime[3];
 LastThirdDownZigZagTime=SwingTime[4];
 LastThirdUpZigZagTime=SwingTime[5];
 
 LastUpZZ =LastUpZigZag;
 LastUpZZTime=LastUpZigZagTime;*/
}


leg1 = MathAbs(SwingValue[0] - SwingValue[1]);
leg2 = MathAbs(SwingValue[1] - SwingValue[2]);
avgleg = (leg1 + leg2 - 50 * Point) / 2;
//  double leg3=MathAbs(SwingValue[2]-SwingValue[3]);
//  double leg4=MathAbs(SwingValue[3]-SwingValue[4]);

if(operation=="Buy")
{

if( (Close[candle]-LastSecondDownZigZag <=-pips*Point*10 || Close[candle]-LastSecondDownZigZag > 0)
		&& (Close[candle]-LastUpZigZag <=-pips*Point*10)
		&& (Close[candle]-LastSecondUpZigZag <=-pips*Point*10 || Close[candle]-LastSecondUpZigZag > 0))
{
	ZigZagsIsNotNear = true;
}
}
else if(operation=="Sell")
{
if( (Close[candle]-LastSecondUpZigZag >=pips*Point || Close[candle]-LastSecondUpZigZag < 0)
		&& (Close[candle]-LastDownZigZag >=pips*Point)
		&& (Close[candle]-LastSecondDownZigZag >=pips*Point || Close[candle]-LastSecondDownZigZag < 0))
{
	ZigZagsIsNotNear = true;
}
}

if(checkForLeglength && leg1/Point/10< legLength)
{
ZigZagsIsNotNear = false;
}

return ZigZagsIsNotNear;

}


// this function returns true if the current price is X number of pips away from last zigzag peak and bottom
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc
// candle is nth candlestick in your chart
// operation can be Buy or Sell and this method is used to trade on price reversal
// pips is the number of pips away from current price

bool priceCloseToPreviousZigZag(int candle, string operation, int timeframe,
int pips)
export
{

bool priceCloseToPreviousZigZag =false;
			      //Zigzag variables
double LastUpZigZag, LastDownZigZag, LastSecondUpZigZag, LastSecondDownZigZag,
	LastThirdUpZigZag, LastThirdDownZigZag, LastUpZigZagMove,
	LastSecondUpZigZagMove, LastDownZigZagMove, LastSecondDownZigZagMove,
	LastZigZagMove, LastZigZag, LastDownZZ, LastUpZZ;

datetime LastUpZigZagTime, LastDownZigZagTime, LastSecondUpZigZagTime,
	LastSecondDownZigZagTime, LastThirdUpZigZagTime, LastThirdDownZigZagTime,
	LastDownZZTime, LastUpZZTime;
double pipsmultiplier;
double leg1, leg2, avgleg;

//Zigzag calculation
double SwingValue[4];
datetime SwingTime[4];
int Found = 0;
int m = candle;
while (Found <= 3) {
if (iCustom(NULL, timeframe, "ZigZag", 12, 5, 3, 0, m) != 0) {

	SwingValue[Found] = iCustom(NULL, timeframe, "ZigZag", 12, 5, 3,
			0, m);
	SwingTime[Found] = iTime(NULL, 0, m);
         Found++;
}
m++;
}

if (SwingValue[0] > SwingValue[1]) {

LastUpZigZag = SwingValue[0];
LastDownZigZag = SwingValue[1];
LastSecondUpZigZag = SwingValue[2];
LastSecondDownZigZag = SwingValue[3];
/*  LastThirdUpZigZag=SwingValue[4];
 LastThirdDownZigZag=SwingValue[5];
 LastUpZigZagTime=SwingTime[0];
 LastDownZigZagTime=SwingTime[1];
 LastSecondUpZigZagTime=SwingTime[2];
 LastSecondDownZigZagTime=SwingTime[3];
 LastThirdUpZigZagTime=SwingTime[4];
 LastThirdDownZigZagTime=SwingTime[5];
 
 LastDownZZ =LastDownZigZag;
 LastDownZZTime =LastDownZigZagTime;*/
}

else {
LastDownZigZag = SwingValue[0];
LastUpZigZag = SwingValue[1];
LastSecondDownZigZag = SwingValue[2];
LastSecondUpZigZag = SwingValue[3];
/*  LastThirdDownZigZag=SwingValue[4];
 LastThirdUpZigZag=SwingValue[5];
 LastDownZigZagTime=SwingTime[0];
 LastUpZigZagTime=SwingTime[1];
 LastSecondDownZigZagTime=SwingTime[2];
 LastSecondUpZigZagTime=SwingTime[3];
 LastThirdDownZigZagTime=SwingTime[4];
 LastThirdUpZigZagTime=SwingTime[5];
 
 LastUpZZ =LastUpZigZag;
 LastUpZZTime=LastUpZigZagTime;*/
}

leg1 = MathAbs(SwingValue[0] - SwingValue[1]);
leg2 = MathAbs(SwingValue[1] - SwingValue[2]);
avgleg = (leg1 + leg2 - 50 * Point) / 2;
			//  double leg3=MathAbs(SwingValue[2]-SwingValue[3]);
			//  double leg4=MathAbs(SwingValue[3]-SwingValue[4]);

if(operation=="Buy")
{

if( MathAbs (Close[candle]-LastSecondDownZigZag) <=pips*Point*10
		&& MathAbs (LastDownZigZag-LastSecondDownZigZag) <=30*Point
		&& Close[candle]> LastSecondDownZigZag)
{
	priceCloseToPreviousZigZag = true;
}
}
else if(operation=="Sell")
{
if( MathAbs (Close[candle]-LastSecondUpZigZag) <=pips*Point*10
		&& MathAbs (LastSecondUpZigZag-LastUpZigZag) <=30*Point
		&& Close[candle] <LastSecondUpZigZag)
{
	priceCloseToPreviousZigZag = true;
}
}

return priceCloseToPreviousZigZag;

}

// this function returns true if the current price is X number of pips away from the most recent Upper and Lower Fractal
// timeframe can be 0 for current chart timeframe, 1 for 1 min chart etc
// candle is nth candlestick in your chart
// operation can be Buy or Sell and this method is used to trade on price reversal
// pips is the number of pips away from current price
// checkCandles is the number of candlesticks to traverse back to check for this condition

bool noFractalWithinPips(int candle, int checkCandles, int pips, int timeframe,
string operation)
export {

bool noFractalWithinPips = true;
double upFractal, downFractal;

if(operation == "Buy")
{
for (int n = candle; n <= checkCandles; n++) {
	upFractal=iFractals(Symbol(), timeframe, MODE_UPPER, n);
	downFractal = iFractals(Symbol(), timeframe, MODE_LOWER, n);

	if ((upFractal > 0 && upFractal > Close[candle]
					&& MathAbs(Close[candle]-upFractal) < pips*10*Point) ||
			(downFractal > 0 && downFractal > Close[candle]
					&& MathAbs(Close[candle]-downFractal) < pips*10*Point))
	{
		noFractalWithinPips = false;
		break;
	}

}

}			//end if

else if(operation == "Sell")
{
for (int n = candle; n <= checkCandles; n++) {
	upFractal=iFractals(Symbol(), timeframe, MODE_UPPER, n);
	downFractal = iFractals(Symbol(), timeframe, MODE_LOWER, n);

	if ((upFractal > 0 && upFractal < Close[candle]
					&& MathAbs(Close[candle]-upFractal) < pips*10*Point) ||
			(downFractal > 0 && downFractal < Close[candle]
					&& MathAbs(Close[candle]-downFractal) < pips*10*Point))
	{
		noFractalWithinPips = false;
		break;
	}

}

}			//end if

return noFractalWithinPips;

}

