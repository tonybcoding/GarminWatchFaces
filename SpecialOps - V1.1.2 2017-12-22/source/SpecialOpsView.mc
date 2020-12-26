using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Time as Time;
using Toybox.Timer as Timer;
using Toybox.System as Sys;
using Toybox.Math as Math;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;

class SpecialOpsView extends Ui.WatchFace {
    
	// Settings from CIQ mobile app
    var appStore_handTipColor	= null;
    var appStore_hashColor 		= null;
    var appStore_secHandColor	= null;
    var appStore_calorieGoal 	= null;
	var appStore_timeoffset		= null;
	var appStore_dispBatt		= null;
	var appStore_dispStep		= null;
	var appStore_dispCals    	= null;
	var appStore_topDigi		= null;
	var appStore_bottomDigi		= null;
	const C_YELLOW				= 1000;
	const C_WHITE				= 1001;	
	const C_LT_GRAY				= 1002;
	const C_DK_GRAY				= 1003;
	const C_BLACK				= 1004;
	const C_BLUE				= 1005;
	const C_DK_BLUE				= 1006;
	const C_GREEN				= 1007;
	const C_DK_GREEN			= 1008;
	const C_RED					= 1009;	    
	const C_DK_RED				= 1010;
	const C_ORANGE				= 1011;
	const C_PURPLE				= 1012;
	const C_PINK				= 1013;
	var colArray 				= [
									[C_YELLOW, Gfx.COLOR_YELLOW],
									[C_WHITE, Gfx.COLOR_WHITE], 
									[C_LT_GRAY, Gfx.COLOR_LT_GRAY],
									[C_DK_GRAY, Gfx.COLOR_DK_GRAY], 
									[C_BLACK, Gfx.COLOR_BLACK],
									[C_BLUE, Gfx.COLOR_BLUE],
									[C_DK_BLUE, Gfx.COLOR_DK_BLUE], 
									[C_GREEN, Gfx.COLOR_GREEN],
									[C_DK_GREEN, Gfx.COLOR_DK_GREEN],
									[C_RED, Gfx.COLOR_RED], 
									[C_DK_RED, Gfx.COLOR_DK_RED],
									[C_ORANGE, Gfx.COLOR_ORANGE],
									[C_PURPLE, Gfx.COLOR_PURPLE],
									[C_PINK, Gfx.COLOR_PINK]
								  ]; 
    
    
	// Must declare globals here, but apparetnly can't call certain system functions yet.     
 	var fast_updates 		= false;
    var mid_x				= null; // center horizontal
    var mid_y				= null; // center vertical
    var arcWidth			= null; // width of stat arcs (this will be set when drawing status arcs--can be dynamic
    const ARCWIDTH			= 7; 	// may have to change arcWidth if display indicators of arcs are all false
    var c_tipColor			= null;
    var c_hashColor			= null;
	var c_secColor			= null;
	var	c_arborColor		= null;
	var	c_secFill			= null;
	var c_digitalBG			= null;
	var c_digitalText		= null;
	var smallFont			= null;
	var digitalFont			= null;
	var digSmallFont		= null;
	var digSmallNMFont		= null;
	var numFont				= null;
	var num2Font			= null;
	
	// Metrics capturing variables
	var appStartTimer		= null;
	var appBattStartValue	= null;
	var appAvgLatency		= null;
	var appRefreshCounter	= null;
	var logging				= false;


	////////////////////////////////////////////////////////////////////
	// initialize() function ran when app is initially selected
	////////////////////////////////////////////////////////////////////
    function initialize() {
        WatchFace.initialize();
        
        // Initialize metrics variables
        appStartTimer			= Sys.getTimer();
    	appBattStartValue		= Sys.getSystemStats().battery;
    	appAvgLatency			= 0;
    	appRefreshCounter		= 0;
    	        
    }
	////////////////////////////////////////////////////////////////////
    // end of initialize() function
	////////////////////////////////////////////////////////////////////    


	////////////////////////////////////////////////////////////////////
	// onLayout() function load resources and set global "constants"
	////////////////////////////////////////////////////////////////////
    function onLayout(dc) {

        setLayout(Rez.Layouts.WatchFace(dc));

		// load fonts and set "global" variables
		mid_x				= dc.getWidth() / 2;
		mid_y				= dc.getHeight() / 2;   
        smallFont			= Ui.loadResource(Rez.Fonts.proan_font);  
        digitalFont			= Ui.loadResource(Rez.Fonts.proan_digital_font);
        digSmallFont		= Ui.loadResource(Rez.Fonts.proan_digitalsmall_font); 
        digSmallNMFont		= Ui.loadResource(Rez.Fonts.proan_digitalsmall_nonmono_font);   
        numFont 			= Ui.loadResource(Rez.Fonts.proan_num_font);
        num2Font   			= Ui.loadResource(Rez.Fonts.proan_num2_font);
        c_digitalBG			= Gfx.COLOR_LT_GRAY;
        c_digitalText		= Gfx.COLOR_BLACK;
        
        onUpdate(dc);

    }
	////////////////////////////////////////////////////////////////////
    // end of onLayout() function
	////////////////////////////////////////////////////////////////////
	    


	/////////////////////////////////////////////////////////////////////////////////
	// Update the view
	/////////////////////////////////////////////////////////////////////////////////
    function onUpdate(dc) {
       
		// retrieve user settings from mobile app store
	    appStore_handTipColor	= App.getApp().getProperty("handtipcolor_prop");
	    appStore_hashColor 		= App.getApp().getProperty("hashcolor_prop");
	    appStore_secHandColor	= App.getApp().getProperty("sechandcolor_prop");
	    appStore_calorieGoal 	= App.getApp().getProperty("cals_prop");
	    appStore_dispBatt		= App.getApp().getProperty("dispbatt_prop");
	    appStore_dispStep		= App.getApp().getProperty("dispstep_prop");
	    appStore_dispCals		= App.getApp().getProperty("dispcals_prop");
	    appStore_topDigi		= App.getApp().getProperty("digitop_prop");
		appStore_bottomDigi		= App.getApp().getProperty("digibottom_prop");
	    appStore_timeoffset		= App.getApp().getProperty("timeoffset_prop") % 24;  // converts numbers greater than +/- 24 from affecting calculations

		// set remainder of hour, min hand variables; arc stats variables
		var timer				= Sys.getTimer();
        var now         		= Sys.getClockTime();
        var hour        		= now.hour;
        var minute      		= now.min;
        var second      		= now.sec;
		var arcStart 	= 90.0;
		var goalPos		= 0; // used to determine where to put next "goal" indicator
		var battery	 	= Sys.getSystemStats().battery;	
		var actInfo 	= ActivityMonitor.getInfo();
		var stepPerc 	= (actInfo.steps < actInfo.stepGoal) ? (1.0 * actInfo.steps / actInfo.stepGoal) : 1.0;
		var calInfo		= actInfo.calories;
		var calPerc		= 1.0 * calInfo / appStore_calorieGoal;
		var n,x			= null; // general use variables for numerical calculations

		//////////////////////////////////////////////////////////////////////
		// Some significant array work including setting arcWidth
		// may be a good candidate for a function
		//////////////////////////////////////////////////////////////////////
		// create two-dimensional array. Each index whil contain three values (a calculation, a color, and a display indicator)
		var numItems 	= 3;	// this many entries
		var numNodes 	= 3;	// each entry with this many "nodes" 
		var arc			= new[numItems];
		for (n = 0; n < arc.size(); n += 1) {
			arc[n] = new[numItems];
			for (x = 0; x < arc.size(); x+=1) {
				arc[n][x] = new[numNodes];
			}
		}
		arc[0][0] = ((battery / 100.0) * 360.0);
		arc[0][1] = Gfx.COLOR_RED;
		arc[0][2] = appStore_dispBatt;
		arc[1][0] = (stepPerc * 360.0);
		arc[1][1] = Gfx.COLOR_DK_GREEN;
		arc[1][2] = appStore_dispStep;
		arc[2][0] = (calPerc * 360.0);
		arc[2][1] = Gfx.COLOR_YELLOW;
		arc[2][2] = appStore_dispCals;		
		// Sort array from smallest to largest (we will print smallest arc first and "build" on next, etc.)
		// the nested for loops are required to do a full sort at each position being testing
		// Not economical, but with just a few entries, it will not matter
		for (x = 0; x < arc.size(); x++) {
			for (n = 1; n < arc.size(); n++) {		
				if (arc[n][0] < arc [n-1][0]) {  		// if current item is less than previous, then swap
					var tempVal = arc[n][0];
					var tempCol = arc[n][1];
					var tempDis = arc[n][2];
					arc[n][0] = arc[n-1][0];
					arc[n][1] = arc[n-1][1];
					arc[n][2] = arc[n-1][2];
					arc[n-1][0] = tempVal;
					arc[n-1][1] = tempCol;
					arc[n-1][2] = tempDis; 
				} // end of if current less than previous
			} // end of nested for loop
		} // end of outter for loop
		// if two adjoining items are equal && less then 360 && display indicator is true,
		// then change "display" indicator on latter to false
		// This test is required, because if two items have the same value (and less than 360),
		// the "build on" test below causes a full circle to be drawn
		// also use this test to see if all display indicators are false. If so, adjust arcWidth
		// This is also why we do not set arcWidth until now. It can either be ARCWIDTH or 0.
		// And we have to set it early since many drawing methods depend on it		
		for (n = 1; n < numItems; n++) {
			if ( (arc[n][0].toNumber() == arc[n-1][0].toNumber()) && (arc[n][0] < 360) && (arc[n][2]) ) {
				arc[n][2] = false;
			} // end of adjoining items equal check
		} // end of for loop
		var anyStatsDisplay = false;
		for (n = 0; n < numItems; n++) { // have to run this separate since going from "0" instead of "1" above
			if (!anyStatsDisplay && arc[n][2]) { // if anyStatsDisplay is still false AND this entry is set to display
				anyStatsDisplay = true;			// change anyStatsDisplay indicator to true
			} // end of check anyStatsDisplay
		} // end of for loop				
		if (anyStatsDisplay) {
			arcWidth = ARCWIDTH;	// since there is at least one arc to display, set to width of ARCWIDTH
		} else {
			arcWidth = 1;			// otherwise, set to zero
		}
		//////////////////////////////////////////////////////////////////		
		// end of significant array work
		//////////////////////////////////////////////////////////////////

		// set angles for hour, minute, second
		var h_fraction 			= minute / 60.0;
		var m_angle 			= h_fraction * (2*Math.PI);
		var h_angle 			= (((hour % 12) / 12.0) + (h_fraction / 12.0)) * (2*Math.PI);        
        var secAngle			= (second/60.0 ) * (2*Math.PI);
		var scalex 				= 1;
		var scaley 				= 1;

		// hour hand parameters
		var hrTail				= (mid_y * 0.15) - arcWidth*0.5; // using mid_y in case semi circular watch where mid_y will be less than mid_x 
		var hrLen				= (mid_y * 0.60) - arcWidth;
		var hrUpY				= 6;
		var hrDnY				= 6;

		// min hand parameters
		var minTail		= (mid_y * 0.20) - arcWidth*0.5; // using mid_y in case semi circular watch where mid_y will be less than mid_x 
		var minLen		= (mid_y * 0.75) - arcWidth;
		var minUpY		= 6;
		var minDnY		= 5;

		// second hand definition
		var secTail		= (mid_y * 0.40) - arcWidth*0.5; // using mid_y in case semi circular watch where mid_y will be less than mid_x 
		var secLen		= (mid_y * 0.60) - arcWidth;
		var tailStart 	= -18;
		var secUpY 		= 2;
		var secDnY 		= 2;
		var sHand		= [ [tailStart, secUpY], [tailStart-1, secUpY+2], [-secTail, secUpY+3], [-secTail-2, 0], [-secTail, -(secDnY+3)], [tailStart-1, -(secDnY+2)], [tailStart, -(secDnY)], [secLen, -(secDnY)], [secLen, secUpY], [tailStart, secUpY]    ];
		var sTip 		= [ [secLen,-6],[secLen,6],[(secLen+20),1],[(secLen+28),1],[(secLen+28),-1], [(secLen+20),-1],[secLen,-6] ];
		var sTipFill 	= [ [(secLen+3),-3], [(secLen+2),3], [(secLen+17),0] ];
		var sHandXform 	= generateCoords(mid_x, mid_y, scalex, scaley, secAngle, sHand);
		var sTipXform 	= generateCoords(mid_x, mid_y, scalex, scaley, secAngle, sTip);
		var sTipFillXform 	= generateCoords(mid_x, mid_y, scalex, scaley, secAngle, sTipFill);

		// set user-selected colors based on mobile app entries
        for (n = 0; n < colArray.size(); n++) {
			if (appStore_handTipColor == colArray[n][0]) {
				c_tipColor = colArray[n][1];
			}
			if (appStore_hashColor == colArray[n][0]) {
				c_hashColor = colArray[n][1];
			}
			if (appStore_secHandColor ==  colArray[n][0]) {
				c_secColor = colArray[n][1];
				c_arborColor 	= c_secColor;
				c_secFill = Gfx.COLOR_WHITE;
			}		
        }     


		/////////////////////////////////////////////////////////////////////
		// Begin to draw the watch face
		/////////////////////////////////////////////////////////////////////

		// Clear screen 
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
		dc.clear();

		/////////////////////////////////////////////////////////////////////
		// draw top and bottom rectangles for digital entries
		/////////////////////////////////////////////////////////////////////
		var xStart = mid_x * 0.50;		// x start for both digital areas
		var yTStart = mid_y * 0.50;		// y beginning spot for top digital area
		var yBStart	= mid_y * 1.15; 	// y beginning spot for bottom digital area
		// '0" is the indicator for "Do not display"
		if (appStore_topDigi != 0) {
			drawDigInset(dc, xStart, yTStart+4, Gfx.getFontHeight(digitalFont)-6);
			displayStats (dc, appStore_topDigi, xStart, yTStart, battery, timer);
		} 
		// '0" is the indicator for "Do not display"
		if (appStore_bottomDigi != 0) {
			drawDigInset(dc, xStart, yBStart+4, Gfx.getFontHeight(digitalFont)-6);
			displayStats (dc, appStore_bottomDigi, xStart, yBStart, battery, timer); 
		}

		
		/////////////////////////////////////////////////////////////////////
		// draw 12, 9, 6, 3
		/////////////////////////////////////////////////////////////////////
		n = Gfx.getFontHeight(num2Font);
		drawNum(dc, mid_x, 										(arcWidth + 13), 				mid_x, 										(arcWidth + 14), 				"12", Gfx.TEXT_JUSTIFY_CENTER);
		drawNum(dc, mid_x, 										(mid_y*2-(arcWidth+n/2-5)), 	mid_x, 										(mid_y*2-(arcWidth+n/2-6)), 	"6", Gfx.TEXT_JUSTIFY_CENTER);
		drawNum(dc, (mid_x - mid_y) + arcWidth+2, 				(mid_y-3), 						(mid_x - mid_y) + (arcWidth+4), 			(mid_y-2), 						"9", Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
		drawNum(dc, ((mid_x*2)-((arcWidth+2)+(mid_x-mid_y))), 	(mid_y-3), 						((mid_x*2)-((arcWidth+4)+(mid_x-mid_y))), 	(mid_y-2), 						"3", Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);

		// draw status arcs ONLY if anyStatsDisplay is true (and of the entries have display set to true)
		// draw black and gray outline (with gray slightly extended beyond to simulate shading
		if (anyStatsDisplay) {
			dc.setPenWidth(arcWidth+2);
			dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
			dc.drawCircle(mid_x, mid_y, mid_y-(arcWidth/2));
			dc.setPenWidth(arcWidth);
			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			dc.drawCircle(mid_x, mid_y, mid_y-(arcWidth/2-2));
			dc.setPenWidth(arcWidth);
			for (n = 0; n < arc.size(); n++) {    
				if (arc[n][2]) { // only display if display indicator set to "true"
					// if greater than 360, arc continues to draw being 360 degrees 
					if (arc[n][0] > 360) {
						arc[n][0] = 360.0;
					}
					// if arc = 0, the drawArc method would draw a complete circle
					if (!(arc[n][0] == 0) && (arc[n][0] < 360.0)) {
						dc.setColor(arc[n][1], Gfx.COLOR_TRANSPARENT);			
						dc.drawArc(mid_x, mid_y, mid_y-(arcWidth/2)+1, Gfx.ARC_CLOCKWISE, arcStart, 90.0 - arc[n][0]);
						arcStart = 90.0 - arc[n][0];
					} else if ( (arc[n][1] != Gfx.COLOR_RED) && (arc[n][0] >= 360.0) ) { // when n=0, it is battery. No need to set indicator
						// here I should build an array and only include the color, then
						// by array size, I know how to space each item and by array content, I know
						// what color to make them			
						dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);						
						dc.fillCircle((mid_x-30)+(goalPos*60), arcWidth+18, 8);
						dc.setColor(arc[n][1], Gfx.COLOR_TRANSPARENT);
						dc.fillCircle((mid_x-30)+(goalPos*60), arcWidth+18, 6);
						goalPos++;
					}
				} // end of check "to display" setting as true
			} // end of for loop
			dc.setPenWidth(1);	
		} // end of check to see if anyStatsDisplay is set

		// draw customized tick marks for this watch face
		drawTicks(dc);


		// draw hour & min hands
		drawHrMinHands(dc, hrLen, hrTail, hrUpY, hrDnY, scalex, scaley, h_angle);
		drawHrMinHands(dc, minLen, minTail, minUpY, minDnY, scalex, scaley, m_angle);

		// if in "high power" mode...
		// draw second hand, hand tip, and hand fill
		if (fast_updates) {
			dc.setColor(c_secColor, Gfx.COLOR_TRANSPARENT);
			dc.fillPolygon(sHandXform);
			dc.fillPolygon(sTipXform);
			dc.setColor(c_secFill, Gfx.COLOR_TRANSPARENT);		
			dc.fillPolygon(sTipFillXform);
		}
	
		// draw arbor
		dc.setColor(c_arborColor, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(mid_x, mid_y, 6);
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		dc.drawCircle(mid_x, mid_y, 6);
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(mid_x, mid_y, 2);


		/////////////////////////////////////////////////////////////////
		// Always calc metrics, but only show if buttonSelect is true
		/////////////////////////////////////////////////////////////////		
    	var stats = getStats(battery, timer);
    	var currTimer 		= stats[0];
    	var currLatency 	= stats[1];
    	var timeRunning 	= stats[2];
    	var timeRunHrs 		= stats[3];
    	var battUsed 		= stats[4]; // battery consumption since App initialized
    	var battPerHr 		= stats[5]; // battery usage per hour
    	var timeRemaining 	= stats[6];
    	appAvgLatency = ((appAvgLatency * appRefreshCounter) + currLatency) / (appRefreshCounter+1);

		var tx = mid_x*0.5;
		var ty = mid_y*0.5;
		var yinc = 15;
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		//battery per hour
//		dc.drawText(mid_x*0.6, mid_y, smallFont, "bph " + battPerHr.format("%2.2f")+"%", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    	appRefreshCounter++;
		
    }
	/////////////////////////////////////////////////////////////////////////////////
	// end of onUpdate function
	/////////////////////////////////////////////////////////////////////////////////



	/////////////////////////////////////////////////////
	// helper function to get battery stats
	/////////////////////////////////////////////////////
	function getStats(battery, timer) {
		var stats = new[7];
		stats[0] = Sys.getTimer();					// currentTimer
		stats[1] = stats[0] - timer;				// currentLatency
		stats[2] = stats[0] - appStartTimer;		// time running
		stats[3] = stats[2]/1000.0/60.0/60.0; 		// time running in hours: ms->sec->min->hrs
    	stats[4] = appBattStartValue - battery; 	// battery consumption since App initialized
    	stats[5] = stats[4] / stats[3]; 			// battery usage per hour
    	stats[6] = (stats[5] > 0) ? (battery / stats[5]) : null;		
		return stats;
	}
	/////////////////////////////////////////////////////
	// end of helper function
	/////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////
	// function to display desired stats in top or bottom digital display
	/////////////////////////////////////////////////////////////////////////////////
	function displayStats(dc, index, x, y, battery, timer) {

		// set label_y based on whether we are displaying stats in upper or lower digital display
		y += 2;
		var label_y = null;
		if ( y < mid_y ) {
			label_y = y - 8;		
		} else {
			label_y = y + Gfx.getFontHeight(digitalFont) + 3;
		} 
		dc.setColor(c_digitalText, Gfx.COLOR_TRANSPARENT);

		switch(index) {

			///////////////////////////////////////////////
			// display day and date
			///////////////////////////////////////////////
			case 1:
				var dateString 	= Time.Gregorian.info( Time.now(), Time.FORMAT_MEDIUM);		
				var dayOfWeek 	= dateString.day_of_week.substring(0,3);
				var day			= (dateString.day.toString().length() == 1) ? "0" + dateString.day : dateString.day;
				y -= 2;
				dc.drawText(mid_x, y, digitalFont, dayOfWeek.toLower() + " " + day, Gfx.TEXT_JUSTIFY_CENTER);
			break;

			///////////////////////////////////////////////			
			// display digital time with offset			
			///////////////////////////////////////////////			
			case 2:
		        var now         		= Sys.getClockTime();
		        var hour        		= now.hour;
		        var minute      		= now.min;
		        var second      		= now.sec;
				var stringSec = second.toString();
				var offsetHour = hour + appStore_timeoffset;
					// must run this test to prevent negative hours or hours > 23
					if (offsetHour < 0) {
						offsetHour = offsetHour + 24;
					} else if (offsetHour > 23) {
						offsetHour = offsetHour - 24;
					}
				var stringHr = offsetHour.toString();
				var stringMin = minute.toString();
				y -= 2;
				stringMin = (stringMin.length()==1) ? "0"+stringMin : stringMin;
				stringSec = (stringSec.length()==1) ? "0"+stringSec : stringSec;
				stringHr = (stringHr.length() == 1) ? " "+stringHr : stringHr;
				// adding 15 pixels for the colon and small between time and seconds
				var n = dc.getTextWidthInPixels(stringHr+stringMin, digitalFont) + dc.getTextWidthInPixels(stringMin, digSmallFont) + 15;
				x = mid_x - (n / 2.0);
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
				dc.drawText (x, y, digitalFont, stringHr, Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText (x + dc.getTextWidthInPixels(stringHr, digitalFont)+1, y, digitalFont, ":", Gfx.TEXT_JUSTIFY_CENTER);
				dc.drawText (x + dc.getTextWidthInPixels(stringHr, digitalFont)+5, y, digitalFont, stringMin, Gfx.TEXT_JUSTIFY_LEFT);
				if (fast_updates) {
					dc.drawText (x + dc.getTextWidthInPixels((stringHr+stringMin), digitalFont)+10, y + 11, digSmallFont, stringSec, Gfx.TEXT_JUSTIFY_LEFT);
				} else {
					dc.drawText (x + dc.getTextWidthInPixels((stringHr+stringMin), digitalFont)+1, y + 13, digSmallNMFont, battery.format("%3.0f")+"%", Gfx.TEXT_JUSTIFY_LEFT);
				}
			break;
		
			///////////////////////////////////////////////
			// display battery % remaining and approximate time left
			///////////////////////////////////////////////						
			case 3:
				var stats = getStats(battery, timer);
				var timeRemaining = stats[6];
				dc.drawText((mid_x - (x/2)), label_y, smallFont, "Batt %", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
				dc.drawText((mid_x + (x/2)), label_y, smallFont, "Hrs Left", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
				y += Gfx.getFontHeight(digSmallNMFont) / 2 - 4;
				dc.drawText((mid_x - (x/2)), y, digSmallNMFont, battery.format("%3.1f")+"%", Gfx.TEXT_JUSTIFY_CENTER );
				if (timeRemaining != null) {
					dc.drawText((mid_x + (x/2)), y, digSmallNMFont, timeRemaining.format("%3.1f"), Gfx.TEXT_JUSTIFY_CENTER );
				} else {
					dc.drawText((mid_x + (x/2)), y, digSmallNMFont, "N/A", Gfx.TEXT_JUSTIFY_CENTER );
				}

			break;

			///////////////////////////////////////////////
			// display steps and cals burned			
			///////////////////////////////////////////////			
			case 4:
				var actInfo 	= ActivityMonitor.getInfo();
				var steps 		= actInfo.steps;
				var cals		= actInfo.calories;
				dc.drawText((mid_x - (x/2)), label_y, smallFont, "Steps", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
				dc.drawText((mid_x + (x/2)), label_y, smallFont, "kCals", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);				
				y += Gfx.getFontHeight(digSmallNMFont) / 2 - 4;
				dc.drawText((mid_x - (x/2)), y, digSmallNMFont, steps, Gfx.TEXT_JUSTIFY_CENTER);
				dc.drawText((mid_x + (x/2)), y, digSmallNMFont, cals, Gfx.TEXT_JUSTIFY_CENTER);
			break;


			// display heart rate and altitude			
			case 5:
				var sensorInfo	= Sensor.getInfo();
				var heartRate	= sensorInfo.heartRate; 
				var altitude	= sensorInfo.altitude * 3.28; // convert from meters to feet
				var mid2_x = (mid_x - x)/2;
				dc.drawText((mid_x - (x/2)), label_y, smallFont, "HR", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
				dc.drawText((mid_x + (x/2)), label_y, smallFont, "Alt (ft)", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);				
				y += Gfx.getFontHeight(digSmallNMFont) / 2 - 4;		
				dc.drawText((mid_x - (x/2)), y, digSmallNMFont, heartRate, Gfx.TEXT_JUSTIFY_CENTER);				
				dc.drawText((mid_x + (x/2)), y, digSmallNMFont, altitude.toNumber(), Gfx.TEXT_JUSTIFY_CENTER);			
			break;

			// display temperature, and barametric pressure			
			case 6:
				dc.drawText(x, y, digSmallNMFont, "temp and pressure", Gfx.TEXT_JUSTIFY_LEFT );
			
			
			break;


			// display cal and % of cal goal			
			case 7:
				dc.drawText(x, y, digSmallNMFont, "cals and % of goal", Gfx.TEXT_JUSTIFY_LEFT );
			
			
			break;


			// display steps and % of step goal			
			case 8:
				dc.drawText(x, y, digSmallNMFont, "steps and % of goal", Gfx.TEXT_JUSTIFY_LEFT );
			
			
			break;


			// display floors and % of floor goal			
			case 9:
				dc.drawText(x, y, digSmallNMFont, "floors and % of goal", Gfx.TEXT_JUSTIFY_LEFT );
			
			
			break;


			// display distance and move bar level			
			case 10:
				dc.drawText(x, y, digSmallNMFont, "distance and move bar lvl", Gfx.TEXT_JUSTIFY_LEFT );
			
			
			break;

			
			default:
				dc.drawText(x, y, digSmallNMFont, "other", Gfx.TEXT_JUSTIFY_LEFT);
			
			
			break;
		
		
		
		}
	
		// https://developer.garmin.com/downloads/connect-iq/monkey-c/doc/Toybox/ActivityMonitor/Info.html		



//		var userSettings		= System.getDeviceSettings();
//		var clockMode24 		= userSettings.is24Hour;			// 24 hour mode? True, yes. False, 12 hour mode




	



	
	
	} 
	/////////////////////////////////////////////////////////////////////////////////
	// end of function to display desired stats in top or bottom digital display
	/////////////////////////////////////////////////////////////////////////////////






	/////////////////////////////////////////////////////////////////////////////////
	// drawStatsPointers function
	/////////////////////////////////////////////////////////////////////////////////
	function drawStatsPointers(dc, steps, stepGoal, battery) {		
		var pSteps = (steps > stepGoal) ? stepGoal * 1.0 : steps * 1.0; 
		var pAngB = (battery/100.0) * (2*Math.PI);
		var pAngS = (pSteps /stepGoal) * (2*Math.PI);
		/*
		var pSx = mid_x - 20;
		var pEx = mid_x + 5;
		var pY = 9;
		var pRecDef   	= [ [pSx, pY], [pSx, -pY], [pEx, -pY], [pEx, pY], [pSx, pY] ]; 
		pY -=2;
		pSx += 2;
		var pPointDef 	= [ [pSx, pY], [pSx, -pY], [pSx+12, 0 ], [pSx, pY] ];
		var pRecBX		= generateCoords(mid_x, mid_y, 1, 1, pAngB, pRecDef);
		var pPointBX	= generateCoords(mid_x, mid_y, 1, 1, pAngB, pPointDef);
		var pRecSX		= generateCoords(mid_x, mid_y, 1, 1, pAngS, pRecDef);
		var pPointSX	= generateCoords(mid_x, mid_y, 1, 1, pAngS, pPointDef);
		*/
		var pSx 		= mid_x - 10;
		var pEx 		= mid_x - 2;
		var pRecDef		= [ [pSx, 0], [pEx, 0]    ];
		var pRecBX		= generateCoords(mid_x, mid_y, 1, 1, pAngB, pRecDef);
		var pRecSX		= generateCoords(mid_x, mid_y, 1, 1, pAngS, pRecDef);		

		dc.setPenWidth(8);
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		drawPolyOutline(dc, pRecBX);		
		dc.setPenWidth(4);
		dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
		drawPolyOutline(dc, pRecBX);
		dc.setPenWidth(1);
		//		dc.fillPolygon(pPointBX);

		dc.setPenWidth(8);
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		drawPolyOutline(dc, pRecSX);
		dc.setPenWidth(4);
		dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
		drawPolyOutline(dc, pRecSX);
		dc.setPenWidth(1);
		//		dc.fillPolygon(pPointSX);
					
	}
	/////////////////////////////////////////////////////////////////////////////////
	// end of drawStatsPointers function
	/////////////////////////////////////////////////////////////////////////////////


	////////////////////////////////////////////////////////////////
	// drawTicks function (tick marks for update02 watch face
	////////////////////////////////////////////////////////////////
	function drawTicks(dc) {
		// define sections of arm
		var tickEnd = null;
		var tickStart = null;
		var baseOffset = null;
		if (arcWidth == ARCWIDTH) {
			tickEnd = mid_x - (arcWidth);
			tickStart = tickEnd - 21;
			baseOffset = 10;
		} else { // if no arcs, then make tick marks and bases longer
			tickEnd = mid_x;
			tickStart = tickEnd - (21+(ARCWIDTH/2));
			baseOffset = 10+(ARCWIDTH/2);
		}
		var yOff = 3;	// width of colored portion of tick mark
		var sx = 1;
		var sy = 1;
		var tickdef		= [ [tickStart, yOff], [tickStart, -yOff], [tickEnd, -yOff], [tickEnd, yOff], [tickStart, yOff]    ];
		yOff += 2;		// width of black base of tick mark
		var tick2def	= [ [tickEnd, yOff], [tickEnd, -yOff], [tickEnd-baseOffset, -yOff], [tickEnd-baseOffset, yOff], [tickEnd, yOff]  ];
		var tick = null;
		var t_angle = null;
		var tickX = null;

		for (var n = 5; n < 60; n+=5) {
			if (!(n % 15 == 0)) {
				tick 	= n / 60.0;
				t_angle = tick * (2*Math.PI);
				// draw black tick base
				tickX = generateCoords(mid_x, mid_y, sx, sy, t_angle, tick2def);
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
				dc.setPenWidth(3);
				drawPolyOutline(dc, tickX);	
				dc.setPenWidth(1);
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
				dc.fillPolygon(tickX);
				// draw colored tick overlay with black "border"
				tickX = generateCoords(mid_x, mid_y, sx, sy, t_angle, tickdef);
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
				dc.setPenWidth(3);
				drawPolyOutline(dc, tickX);		
				dc.setPenWidth(1);
				dc.setColor(c_hashColor, Gfx.COLOR_TRANSPARENT);
				dc.fillPolygon(tickX);
			} // end check to ensure not adding tick to 15/30/45/60
		} // end for loop

	} // end drawTicks function				
	////////////////////////////////////////////////////////////////
	// end of drawTicks function
	////////////////////////////////////////////////////////////////



	/////////////////////////////////////////////////////////////////////////////////
	// draw hour numbers on screen
	/////////////////////////////////////////////////////////////////////////////////
	function drawNum (dc, x1, y1, x2, y2, num, justify) {
		var numCol = Gfx.COLOR_BLACK;
		var numShade = Gfx.COLOR_LT_GRAY;
		dc.setColor(numShade, Gfx.COLOR_TRANSPARENT);
		dc.drawText(x1, y1, num2Font, num, justify | Gfx.TEXT_JUSTIFY_VCENTER);
		dc.setColor(numCol, Gfx.COLOR_TRANSPARENT);		 
		dc.drawText(x2, y2, numFont, num, justify | Gfx.TEXT_JUSTIFY_VCENTER);		
	}
	/////////////////////////////////////////////////////////////////////////////////
	// end of draw hour numbers on screen
	/////////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////////////////
	// draw hour and minute hands for update02 watch face
	/////////////////////////////////////////////////////////////////////////////////
	function drawHrMinHands(dc, len, tail, upY, dnY, sx, sy, angle) {

		// define sections of arm
		var baseLen		= 10;
		var base		= [ [-tail, upY], [-tail, -dnY], [baseLen, -dnY], [baseLen, upY], [-tail, upY] ];
		var midLen		= (len - baseLen) * 0.90;
		var mid			= [ [baseLen, upY], [baseLen, -dnY], [midLen, -dnY], [midLen, upY], [baseLen, upY] ];
		upY -= 2;
		dnY -= 2;
		var endStart	= midLen * 0.70;
		var end			= [ [endStart, upY], [endStart, -dnY], [len, -dnY], [len, upY], [endStart, upY] ];
		
		// translate points
		var baseX		= generateCoords(mid_x, mid_y, sx, sy, angle, base);
		var midX		= generateCoords(mid_x, mid_y, sx, sy, angle, mid);		
		var endX		= generateCoords(mid_x, mid_y, sx, sy, angle, end);		

		
		// draw mid "hollow" arm
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(3);
		drawPolyOutline(dc, midX);		
		dc.setPenWidth(1);
		
		// draw tail/base
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(3);
		drawPolyOutline(dc, baseX);		
		dc.setPenWidth(1);
		dc.fillPolygon(baseX);
		
		// draw end tip
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(3);
		drawPolyOutline(dc, endX);	
		dc.setPenWidth(1);
		dc.setColor(c_tipColor, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(endX);

		
	}
	/////////////////////////////////////////////////////////////////////////////////
	// end of draw hour and minute hands for update02 watch face
	/////////////////////////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////
	// draw "shaded" rectange for digi display at the x, y location
	// length will be calculated to end equal to where it started
	/////////////////////////////////////////////////////////////////////////////////
	function drawDigInset(dc, x, y, h) {
		var len = (mid_x * 2.0) - (2.0 * x);
		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_GRAY);
		dc.fillRoundedRectangle(x - 2, y - 2, len + 2, h + 4, Math.PI);
		dc.setColor(c_digitalBG, c_digitalText);
		dc.fillRoundedRectangle(x, y, len - 2, h, Math.PI);	
	} // end of drawDigInset


	/////////////////////////////////////////////////////////////////////////////////////////////
	// drawPolyOutline function: this function draws the outline (i.e., unfilled) of a polygon
	// This allows "transparent" shapes and hands to be drawn
	/////////////////////////////////////////////////////////////////////////////////////////////
	function drawPolyOutline (dc, points) {
		// Since we invoke points[i+1], must ensure we stay under array size
		// So we use < points.size()-1
		for (var i = 0; i < (points.size() - 1); i++) {
			dc.drawLine(points[i][0], points[i][1], points[i+1][0], points[i+1][1]);
		}	
	}
	/////////////////////////////////////////////////////////////////////////////
	// End of drawPolyOutline function.
	/////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////////////
	// Credits to travis.vitek (Master member on ConnectIQ developer forum)
	// Copied directly from him with just one minor mod: rotated given angle
	// 90 degrees. Easier for me to work with clock orientation this way.
	/////////////////////////////////////////////////////////////////////////////
	function generateCoords(dx, dy, sx, sy, theta, points) {
	    var sin = Math.sin(theta - Math.PI/2);
	    var cos = Math.cos(theta - Math.PI/2);
	
	    var coords = new [points.size()];
	    for (var i = 0; i < points.size(); ++i) {
	
	        // make a copy so as to not modify the points array
	        coords[i] = [ points[i][0] * sx, points[i][1] * sy ];
	
	        var x = (coords[i][0] * cos) - (coords[i][1] * sin) + dx;
	        var y = (coords[i][0] * sin) + (coords[i][1] * cos) + dy;
	
	        coords[i][0] = x;
	        coords[i][1] = y;
	    }
	
	   return(coords);
	}	
	/////////////////////////////////////////////////////////////////////////////
	// End of generateCoords function.
	/////////////////////////////////////////////////////////////////////////////


	////////////////////////////////////////////////////////////////////////////
	// Debug function to print array to console; specifically set up for array
	// containing three items per index
	////////////////////////////////////////////////////////////////////////////
	function printArray(array) {
		for (var n = 0; n < array.size() ; n++) {
				System.println(array[n][0] + " " + array[n][1] + " " + array [n][2]);
		}
	}


	////////////////////////////////////////////////////////////////
	// Functions to set flag for high and low power modes
	////////////////////////////////////////////////////////////////
    function onExitSleep() {
        fast_updates = true;    // indicator that refresh is once per second    
        Ui.requestUpdate();
    }

    function onEnterSleep() {
        fast_updates = false;    // indicator that everythings slows to once a minute update    
        Ui.requestUpdate();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
