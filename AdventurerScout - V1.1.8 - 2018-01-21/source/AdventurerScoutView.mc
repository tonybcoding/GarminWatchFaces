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
using Toybox.Activity as Activity;


// This must carry between classes; therefore we set it globally
var partialUpdatesAllowed = false;

class AdventurerScoutView extends Ui.WatchFace {

	// varliables for 1Hz and high power variables 
    var offscreenBuffer			= null;
    var curClip					= null;
    var fullScreenRefresh		= null;
    var isAwake					= null;

	// Settings from CIQ mobile app
    var appStore_theme 			= null;
    var appStore_calorieGoal 	= null;
	var appStore_timeoffset		= null;
	var appStore_bottomDigi		= null;
    
 	// Must declare globals here, but apparetnly can't call certain system functions yet.     
    var mid_x					= null; // center horizontal
    var mid_y					= null; // center vertical
    var SCALE					= null; // scale based on size of fenix 5
	var c_digitalBG				= null;
	var c_digitalBorder			= null;	
	var c_digitalText			= null;
	var c_screen				= null; // screen color
	var c_line					= null; // used for outline of hands and ticks
	var c_fill					= null; // used for fill of hands and ticks
	var c_text					= null; // screen text
	var c_second				= null; // second hand
	var c_secondTip				= null; // tip of second hand
	var c_arbor					= null; // arbor	
	var c_trans					= null; // shorthand for Transparent	
	var c_minor					= null; // minor ticks and inside circle cutout
	var c_mainoutline			= null; // outline around watchface
	var c_minoutline			= null; // crease around watchface
	var digitalFont				= null;
	var digitalSmallFont		= null;
	var logoFont				= null;
	var logoDateFont			= null;	
	var nameFont				= null;


	/////////////////////////////////////////////////////////////
	// Initialize watch face and metrics variables
	/////////////////////////////////////////////////////////////
    function initialize() {
        WatchFace.initialize();
        partialUpdatesAllowed = true;		// since all watches I'm supporting have this capability, set it to true
    }
	/////////////////////////////////////////////////////////////
	// end of Initialize function
	/////////////////////////////////////////////////////////////	


	/////////////////////////////////////////////////////////////
    // onLayout function. Load resources here
	/////////////////////////////////////////////////////////////
    function onLayout(dc) {
        
		// load fonts and set "global" variables
		curClip				= null;
		mid_x				= dc.getWidth() / 2;
		mid_y				= dc.getHeight() / 2; 
		SCALE				= mid_x / 120.0; // scaling factor based on fenix 5  
		// load font size appropriate to resolution
		if (mid_x < 120) {
	        digitalFont		= Ui.loadResource(Rez.Fonts.digital5S_font);		
		} else {
    	    digitalFont		= Ui.loadResource(Rez.Fonts.digital_font);		
		}
		digitalSmallFont	= Ui.loadResource(Rez.Fonts.digitalsmall_font);
        logoFont			= Ui.loadResource(Rez.Fonts.logo_font); 
        logoDateFont		= Ui.loadResource(Rez.Fonts.logodate_font);
        nameFont			= Ui.loadResource(Rez.Fonts.name_font);  


        // Only supporting SDK 2.3 and above, so assuming BufferedBitmap is supported
		// I would have used partial palette for this buffer to save significant memory; however,
		// anti-aliased fonts AND bitmaps require full palette. I could have created multiple
		// buffers (at least three), but the memory savings reduced to less than 10%. Not worth
		// the added complexity UNLESS I run into memory limitations in the future
        offscreenBuffer = new Graphics.BufferedBitmap({
            :width=>dc.getWidth(),
            :height=>dc.getHeight()
        });

    }
	/////////////////////////////////////////////////////////////
    // end of onLayout function
	/////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////
    // onUpdate - updates once per minute
	/////////////////////////////////////////////////////////////
    function onUpdate(dc) {

        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

		// clear clip region and set targetDc to offscreenBuffer
        dc.clearClip();
        curClip = null;
        var targetDc = offscreenBuffer.getDc();
                
 		// retrieve user settings from mobile app store
		appStore_theme			= App.getApp().getProperty("theme_prop");
	    appStore_calorieGoal 	= App.getApp().getProperty("cals_prop");
		appStore_bottomDigi		= App.getApp().getProperty("digital_prop");
	    appStore_timeoffset		= App.getApp().getProperty("timeoffset_prop") % 24;  // converts numbers greater than +/- 24 from affecting calculations

		switch (appStore_theme) {
		
			// Default Yellow
			case 1:
				c_screen	= Gfx.COLOR_YELLOW;
				c_line		= Gfx.COLOR_BLACK;
				c_fill		= Gfx.COLOR_WHITE;
				c_text		= Gfx.COLOR_BLACK;
				c_second	= Gfx.COLOR_DK_GRAY;
				c_minor		= Gfx.COLOR_DK_GRAY;
				c_secondTip	= Gfx.COLOR_DK_RED;
				c_arbor		= Gfx.COLOR_LT_GRAY;
				c_trans		= Gfx.COLOR_TRANSPARENT;
        		c_digitalBG		= Gfx.COLOR_LT_GRAY;
        		c_digitalBorder	= Gfx.COLOR_DK_GRAY;
        		c_digitalText	= Gfx.COLOR_BLACK;
        		c_mainoutline	= c_arbor;
        		c_minoutline	= c_minor;				
			break;
			
			// White
			case 2:
				c_screen	= Gfx.COLOR_WHITE;
				c_line		= Gfx.COLOR_BLACK;
				c_fill		= Gfx.COLOR_YELLOW;
				c_text		= Gfx.COLOR_BLACK;
				c_second	= Gfx.COLOR_DK_GRAY;
				c_minor		= Gfx.COLOR_DK_GRAY;
				c_secondTip	= Gfx.COLOR_RED;
				c_arbor		= Gfx.COLOR_LT_GRAY;
				c_trans		= Gfx.COLOR_TRANSPARENT;
        		c_digitalBG		= Gfx.COLOR_LT_GRAY;
        		c_digitalBorder	= Gfx.COLOR_DK_GRAY;
        		c_digitalText	= Gfx.COLOR_BLACK;							
        		c_mainoutline	= c_arbor;
        		c_minoutline	= c_minor;				
			break;
			
			// Black with Blue Digital
			case 3:
				c_screen	= Gfx.COLOR_BLACK;
				c_line		= Gfx.COLOR_YELLOW;
				c_fill		= Gfx.COLOR_WHITE;
				c_text		= Gfx.COLOR_LT_GRAY;
				c_second	= Gfx.COLOR_WHITE;
				c_minor		= Gfx.COLOR_LT_GRAY;
				c_secondTip	= Gfx.COLOR_RED;
				c_arbor		= Gfx.COLOR_DK_GRAY;
				c_trans		= Gfx.COLOR_TRANSPARENT;			
        		c_digitalBG		= Gfx.COLOR_BLUE;
        		c_digitalBorder	= Gfx.COLOR_LT_GRAY;
        		c_digitalText	= Gfx.COLOR_BLACK;							
        		c_mainoutline	= c_arbor;
        		c_minoutline	= c_minor;				
			break;

			// Black with Standard Digital
			case 4:
				c_screen	= Gfx.COLOR_BLACK;
				c_line		= Gfx.COLOR_YELLOW;
				c_fill		= Gfx.COLOR_WHITE;
				c_text		= Gfx.COLOR_LT_GRAY;
				c_second	= Gfx.COLOR_WHITE;
				c_minor		= Gfx.COLOR_LT_GRAY;
				c_secondTip	= Gfx.COLOR_RED;
				c_arbor		= Gfx.COLOR_DK_GRAY;
				c_trans		= Gfx.COLOR_TRANSPARENT;			
        		c_digitalBG		= Gfx.COLOR_LT_GRAY;
        		c_digitalBorder	= Gfx.COLOR_DK_GRAY;
        		c_digitalText	= Gfx.COLOR_BLACK;						
        		c_mainoutline	= c_arbor;
        		c_minoutline	= c_minor;				
			break;
			
			// Orange
			case 5:
				c_screen	= Gfx.COLOR_ORANGE;
				c_line		= Gfx.COLOR_BLACK;
				c_fill		= Gfx.COLOR_WHITE;
				c_text		= Gfx.COLOR_BLACK;
				c_second	= Gfx.COLOR_WHITE;
				c_minor		= Gfx.COLOR_DK_GRAY;
				c_secondTip	= Gfx.COLOR_DK_RED;
				c_arbor		= Gfx.COLOR_LT_GRAY;
				c_trans		= Gfx.COLOR_TRANSPARENT;
        		c_digitalBG		= Gfx.COLOR_LT_GRAY;
        		c_digitalBorder	= Gfx.COLOR_DK_GRAY;
        		c_digitalText	= Gfx.COLOR_BLACK;							
        		c_mainoutline	= c_arbor;
        		c_minoutline	= c_minor;				
			break;			
			
			// Dark Green
			case 6:
				c_screen	= Gfx.COLOR_DK_GREEN;
				c_line		= Gfx.COLOR_BLACK;
				c_fill		= Gfx.COLOR_WHITE;
				c_text		= Gfx.COLOR_BLACK;
				c_second	= Gfx.COLOR_WHITE;
				c_minor		= Gfx.COLOR_DK_GRAY;
				c_secondTip	= Gfx.COLOR_DK_RED;
				c_arbor		= Gfx.COLOR_LT_GRAY;
				c_trans		= Gfx.COLOR_TRANSPARENT;
        		c_digitalBG		= Gfx.COLOR_LT_GRAY;
        		c_digitalBorder	= Gfx.COLOR_DK_GRAY;
        		c_digitalText	= Gfx.COLOR_BLACK;							
        		c_mainoutline	= c_arbor;
        		c_minoutline	= c_minor;				
			break;			
			
			// Black "Easy Read"
			case 7:
				c_screen	= Gfx.COLOR_BLACK;
				c_line		= Gfx.COLOR_WHITE;
				c_fill		= Gfx.COLOR_DK_GRAY;
				c_text		= Gfx.COLOR_LT_GRAY;
				c_second	= Gfx.COLOR_LT_GRAY;
				c_minor		= Gfx.COLOR_WHITE;
				c_secondTip	= Gfx.COLOR_YELLOW;
				c_arbor		= Gfx.COLOR_YELLOW;
				c_trans		= Gfx.COLOR_TRANSPARENT;			
        		c_digitalBG		= Gfx.COLOR_BLACK;
        		c_digitalBorder	= Gfx.COLOR_DK_GRAY;
        		c_digitalText	= Gfx.COLOR_WHITE;						
        		c_mainoutline	= Gfx.COLOR_LT_GRAY;
        		c_minoutline	= Gfx.COLOR_WHITE;				
			break;			
			
		
		}


		// set remainder of hour, min hand variables; arc stats variables
		var timer				= Sys.getTimer();
        var now         		= Sys.getClockTime();
        var hour        		= now.hour;
        var minute      		= now.min;
		var battery	 			= Sys.getSystemStats().battery;	
		var n,x					= null; // general use variables for numerical calculations

		// set angles for hour and minute
		var h_fraction 			= minute / 60.0;
		var m_angle 			= h_fraction * (2*Math.PI);
		var h_angle 			= (((hour % 12) / 12.0) + (h_fraction / 12.0)) * (2*Math.PI);        


		/////////////////////////////////////////////////////////////////////
		// Begin to draw the watch face
		/////////////////////////////////////////////////////////////////////
        // Clear screen

        targetDc.setColor(c_screen, c_screen);
		targetDc.clear();
        
        
		// draw inside "crease"
		targetDc.setPenWidth(5);
		targetDc.setColor(c_mainoutline, c_trans);
		targetDc.drawCircle(mid_x, mid_y, (mid_x - 8));
		targetDc.setPenWidth(1);	
		targetDc.setColor(c_minoutline, c_trans);
		targetDc.drawCircle(mid_x, mid_y, (mid_x - 11));		

		// draw customized tick marks for this watch face
		drawTicks(targetDc);


		/////////////////////////////////////////////////////////////////////
		// draw bottom rectangle for digital entries
		/////////////////////////////////////////////////////////////////////
		var xStart = mid_x * 0.45;		// x start for digital area
		var yStart = mid_y  * 1.40;
		var len = (mid_x * 2.0) - (2.0 * xStart);
		var height = targetDc.getFontHeight(digitalFont) - 6;
		targetDc.setColor(c_digitalBorder, c_digitalBorder);
		targetDc.fillRoundedRectangle(xStart - 2, yStart+2, len + 2, height+4, Math.PI);
		targetDc.setColor(c_digitalBG, c_digitalText);
		targetDc.fillRoundedRectangle(xStart, yStart+4, len - 2, height, Math.PI);	
		displayStats (targetDc, appStore_bottomDigi, xStart, yStart, battery, timer);

		// draw brand and style name
		targetDc.setColor(c_text, c_trans);
		targetDc.drawText(mid_x, mid_y*0.5, logoFont, "VESUVIO", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		targetDc.drawText(mid_x, mid_y*0.5+20, logoDateFont, "2017", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);		
		targetDc.drawText(mid_x+(targetDc.getFontHeight(nameFont)/2),  yStart-(targetDc.getFontHeight(nameFont)/2), nameFont, "SCOUT", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

		// draw circle with cross hair logo
		var logoX = mid_x-(targetDc.getFontHeight(nameFont)*1.3);
		var logoY = yStart-(targetDc.getFontHeight(nameFont)/2);
		var logoRadius = targetDc.getFontHeight(nameFont)/2.3;
		targetDc.setColor(Gfx.COLOR_WHITE, c_trans);
		targetDc.fillCircle(logoX, logoY, logoRadius);
		targetDc.setColor(Gfx.COLOR_RED, c_trans);
		targetDc.setPenWidth(2);
		targetDc.drawCircle(logoX, logoY, logoRadius);
		targetDc.drawLine(logoX-logoRadius+1, logoY, logoX+logoRadius, logoY);
		targetDc.drawLine(logoX, logoY-logoRadius+1, logoX, logoY+logoRadius);		
		targetDc.setPenWidth(1);


		////////////////////////////////////////////////////
		// draw hour & min hands
		////////////////////////////////////////////////////
		drawHands(targetDc, h_angle, m_angle);

        // Output the offscreen buffers to the main display
		dc.drawBitmap(0, 0, offscreenBuffer);



        // Since I am assuming all devices supported will support
        // partial updates, I will let the onPartialUpdate method handle
        // the 1Hz printing operations
        onPartialUpdate( dc );

	
       fullScreenRefresh = false; // this is necessary, because onPartialUpdate checks this variable
    }
	/////////////////////////////////////////////////////////////
    // end of onUpdate function
	/////////////////////////////////////////////////////////////





	/////////////////////////////////////////////////////////////
    // onPartialUpdate Function - partial update request every 1 Hz
	/////////////////////////////////////////////////////////////
    function onPartialUpdate( dc ) {
        // If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.
 		var timer = System.getTimer();
		var battery = System.getSystemStats().battery;   
		
		// the only time fullScreenRefersh is true is when onPartialUpdate is called
		// from onUpdate method. If we are coming from onUpdate, we don't need to 
		// redraw cached background, because we just created a new one and displayed it 		
        if(!fullScreenRefresh) {	
			dc.drawBitmap(0, 0, offscreenBuffer);
        }

		// capture current second and calculate associated angle
        var now         		= Sys.getClockTime();
        var second      		= now.sec;
        var secAngle			= (second / 60.0) * (2*Math.PI);

		// second hand definition      
        var x0 = -20 * SCALE;
        var x1 = 113 * SCALE;			// length
        var x2 = x1-15 * SCALE;
        var yOff = 2;
        var secHandDef			= [	[x0, yOff], [x1, yOff], [x1, -yOff], [x0, -yOff] ];
        var secTipDef			= [ [x1, yOff], [x2, yOff], [x2, -yOff], [x1, -yOff] ];

		// transform to angle 
        var secHandX			= generateCoords(mid_x, mid_y, 1, 1, secAngle, secHandDef);
        var secTipX				= generateCoords(mid_x, mid_y, 1, 1, secAngle, secTipDef);

		// set clip region
        curClip = getBoundingBox(secHandX);
        var bboxWidth = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);

        dc.setColor(c_second, c_trans);
        dc.fillPolygon(secHandX);
        dc.setColor(c_secondTip, c_trans);
        dc.fillPolygon(secTipX);

		dc.setColor(c_arbor, c_trans);
		dc.fillCircle(mid_x, mid_y, 4);

    }
	/////////////////////////////////////////////////////////////
    // end of onPartialUpdate function
	/////////////////////////////////////////////////////////////




	/////////////////////////////////////////////////////////////////////////////////
	// function to display desired stats in top or bottom digital display
	/////////////////////////////////////////////////////////////////////////////////
	function displayStats(dc, index, x, y, battery, timer) {

        var now         	= Sys.getClockTime();
        var hour        	= now.hour;
        var minute      	= now.min;
        var second      	= now.sec;	
		var actInfo 		= ActivityMonitor.getInfo(); 
		var dateString 		= Time.Gregorian.info( Time.now(), Time.FORMAT_MEDIUM);		
		var dayOfWeek 		= dateString.day_of_week.substring(0,2);
		var day				= (dateString.day.toString().length() == 1) ? "0" + dateString.day : dateString.day;
		var xEnd			= (mid_x + (mid_x - x)) - 4;
		var labely			= null;
		var labely2			= null;
		var toGoal, n1, n2	= null;       

		// for all cases
		dc.setColor(c_digitalText, c_trans);
		battery = (battery > 99.0) ? 99 : battery;
		if (mid_y < 120) {
			labely 	= y+2;
			labely2	= labely+dc.getFontHeight(digitalSmallFont)/2+5;
			y 		= y + 1;
		} else {
			labely 	= y+3;
			labely2	= labely+dc.getFontHeight(digitalSmallFont)/2+5;
			y 		= y - 1;
		}		

		switch(index) {

			///////////////////////////////////////////////			
			// display digital time with offset and day/date			
			///////////////////////////////////////////////			
			case 1:
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
				stringMin = (stringMin.length()==1) ? "0"+stringMin : stringMin;
				stringHr = (stringHr.length() == 1) ? "0"+stringHr : stringHr;
				n1 = dc.getTextWidthInPixels(stringHr, digitalFont);
				n2 = dc.getTextWidthInPixels(stringMin, digitalFont);
				dc.drawText (mid_x-5, y, digitalFont, stringMin, Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText (mid_x-(n2+1), y, digitalFont, ":", Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText (mid_x-(n2+10), y, digitalFont, stringHr, Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText(mid_x+4, y, digitalFont, dayOfWeek.toUpper() + day, Gfx.TEXT_JUSTIFY_LEFT);				
			break;
		
			///////////////////////////////////////////////
			// display altitude in feet and battery %
			///////////////////////////////////////////////						
			case 2:
				var altitude = (Activity.getActivityInfo().altitude * 3.28).toNumber(); // convert from meters to feet and to integer (i.e., strip decimals)
				dc.drawText(x, labely, digitalSmallFont, "A", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x, labely2, digitalSmallFont, "L", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x+10, y, digitalFont, altitude.format("%0.0f"), Gfx.TEXT_JUSTIFY_LEFT );
				dc.drawText(mid_x+20, y, digitalFont, battery.format("%0.0f")+"%", Gfx.TEXT_JUSTIFY_LEFT );				
			break;

			///////////////////////////////////////////////
			// display steps and % of goal			
			///////////////////////////////////////////////			
			case 3:
				var steps 	= actInfo.steps;
				toGoal		= ((steps.toFloat() / actInfo.stepGoal) * 100).toNumber();
				dc.drawText(x, labely, digitalSmallFont, "S", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x, labely2, digitalSmallFont, "T", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x+10, y, digitalFont, steps, Gfx.TEXT_JUSTIFY_LEFT);
				if (toGoal >= 100.0) {
					dc.drawText(mid_x+20, y, digitalFont, "GL!", Gfx.TEXT_JUSTIFY_LEFT);
				} else {
					dc.drawText(mid_x+20, y, digitalFont, toGoal.format("%0.0f")+"%", Gfx.TEXT_JUSTIFY_LEFT);
				}
			break;

			///////////////////////////////////////////////
			// display kcals and % of goal			
			///////////////////////////////////////////////			
			case 4:
				var cals	= actInfo.calories;
				toGoal		= ((cals.toFloat() / appStore_calorieGoal) * 100).toNumber();	
				dc.drawText(x, labely, digitalSmallFont, "C", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x, labely2, digitalSmallFont, "A", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x+10, y, digitalFont, cals, Gfx.TEXT_JUSTIFY_LEFT);
				if (toGoal >= 100.0) {
					dc.drawText(mid_x+20, y, digitalFont, "GL!", Gfx.TEXT_JUSTIFY_LEFT);
				} else {
					dc.drawText(mid_x+20, y, digitalFont, toGoal.format("%0.0f")+"%", Gfx.TEXT_JUSTIFY_LEFT);
				}
			break;

			///////////////////////////////////////////////			
			// display day/date and battery remaining			
			///////////////////////////////////////////////	
			case 5:
				dc.drawText(mid_x-20, y, digitalFont, battery.format("%0.0f")+"%", Gfx.TEXT_JUSTIFY_RIGHT );	
				dc.drawText(mid_x+4, y, digitalFont, dayOfWeek.toUpper() + day, Gfx.TEXT_JUSTIFY_LEFT);		
			break;

			///////////////////////////////////////////////
			// display heart rate and battery %
			///////////////////////////////////////////////						
			case 6:
				var heartRate = Activity.getActivityInfo().currentHeartRate;
				if (heartRate == null) {
					heartRate = "--";
				}
				dc.drawText(x, labely, digitalSmallFont, "H", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x, labely2, digitalSmallFont, "R", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(x+10, y, digitalFont, heartRate, Gfx.TEXT_JUSTIFY_LEFT );
				dc.drawText(xEnd, y, digitalFont, battery.format("%0.0f")+"%", Gfx.TEXT_JUSTIFY_RIGHT );				
			break;

			////////////////////////////////////////////////
			// error out here
			////////////////////////////////////////////////
			default:
				dc.drawText(mid_x, y, digitalFont, "----", Gfx.TEXT_JUSTIFY_CENTER);
			break;
		} // end of Switch Test
	} 
	/////////////////////////////////////////////////////////////////////////////////
	// end of function to display desired stats in top or bottom digital display
	/////////////////////////////////////////////////////////////////////////////////




	////////////////////////////////////////////////////////////////
	// drawTicks function (tick marks for update02 watch face
	////////////////////////////////////////////////////////////////
	function drawTicks(dc) {
		// define sections of arm
		var tickEnd 	= mid_x - 5;
		var tickStart 	= tickEnd - 20;
		var tickMid 	= (tickStart + (tickEnd - tickStart)/2) + 4;
		var yOff 		= 2;	// width of colored portion of tick mark
		var tick 		= null;
		var t_angle 	= null;
		var tickX 		= null;
		var sin, cos, x1, y1, x2, y2 = null;	
		// full sized tick
		var tickdef		= [ [tickStart, yOff], [tickStart, -yOff], [tickEnd, -yOff], [tickEnd, yOff], [tickStart, yOff]    ];
		// half sized tick
		var tick2def	= [ [tickStart, yOff], [tickStart, -yOff], [tickMid, -yOff], [tickMid, yOff], [tickStart, yOff]    ];		
		// 35 min position tick
		var tick3def	= [ [tickStart+10, yOff], [tickStart+7, -yOff], [tickEnd, -yOff], [tickEnd, yOff], [tickStart+10, yOff]    ];
		// 25 min position tick
		var tick4def	= [ [tickStart+7, yOff], [tickStart+10, -yOff], [tickEnd, -yOff], [tickEnd, yOff], [tickStart+7, yOff]    ];
		// minor one-line tick
		var tick5def 	= [ [tickStart+4, 0], [tickMid, 0] ];	

		// loop through each "minute" position
		for (var n = 0; n < 60; n+=1) {
			tick 	= n / 60.0;
			t_angle = tick * (2*Math.PI);
			if (n % 5 == 0) {	// if n is an increment of 5
				if (n == 25 || n == 35) {
					if (n == 35) {	// if n = 35
						tickDisp(dc, t_angle, tick3def);
					} else {	// if n = 25
						tickDisp(dc, t_angle, tick4def);					
					}
				} else if (n % 10 == 0) { // if n is an increment of 10, then shorter
					tickDisp(dc, t_angle, tick2def);				
				} else { // else, display long tick
					tickDisp(dc, t_angle, tickdef);
				}
			} else {	// display minor tick mark
				dc.setColor(c_minor, c_trans);
				sin = Math.sin(t_angle - Math.PI/2);
				cos = Math.cos(t_angle - Math.PI/2);
				x1 = (tick5def[0][0] * cos) - (tick5def[0][1] * sin) + mid_x;
				y1 = (tick5def[0][0] * sin) + (tick5def[0][1] * cos) + mid_y;
				x2 = (tick5def[1][0] * cos) - (tick5def[1][1] * sin) + mid_x;
				y2 = (tick5def[1][0] * sin) + (tick5def[1][1] * cos) + mid_y;
				dc.setPenWidth(2);
				dc.drawLine(x1, y1, x2, y2);
				dc.setPenWidth(1);			
			}
		} // end for loop

	} // end drawTicks function				
	////////////////////////////////////////////////////////////////
	// end of drawTicks function
	////////////////////////////////////////////////////////////////
	function tickDisp (dc, t_angle, tickdef) {
		var tickX = null;
		// draw black tick base
		tickX = generateCoords(mid_x, mid_y, 1, 1, t_angle, tickdef);
		dc.setColor(c_line, c_trans);
		dc.setPenWidth(4);
		drawPolyOutline(dc, tickX);	
		// draw colored tick overlay with black "border"
		tickX = generateCoords(mid_x, mid_y, 1, 1, t_angle, tickdef);
		dc.setPenWidth(1);
		dc.setColor(c_fill, c_trans);
		dc.fillPolygon(tickX);	
	}
	////////////////////////////////////////////////////////////////
	// end of drawTicks helper function
	////////////////////////////////////////////////////////////////



	/////////////////////////////////////////////////////////////////////////////////
	// draw hour and minute hands 
	/////////////////////////////////////////////////////////////////////////////////
	function drawHands(dc, hrAngle, minAngle) {

		// define minute hand	
		var y1 = 6 * SCALE;
		var y2 = 14 * SCALE;
		var x2 = 18 * SCALE;
		var x3 = x2+4 * SCALE;
		var x4 = x3+4 * SCALE;
		var x5 = x4+12 * SCALE;
		var len = 90 * SCALE;
/*
		var minDef		= [	[0, y1 ], [x2, y1 ], [x3, y2], [len, y1], [len, y1/2.0], [len, -(y1/2.0)],
							[len-5, -(y1/2.0)], [len-5, y1/2.0], [x4, y1/2.0], [x4, -(y1/2.0)],
							[len, -(y1/2.0)], [len, -y1], [x3, -y2], [x2, -y1], [0, -y1], 
							[0, y1]   ]; 
*/
		var minDef		= [	[0, y1 ], [x2, y1 ], [x3, y2], [len, y1], [len, -y1], [x3, -y2], [x2, -y1], [0, -y1], [0, y1]   ]; 

		var minTopInset	= [	[x5, y1/2.0], [len-4, y1/2.0], [len-4, -(y1/2.0)], [x5, -(y1/2.0)] ];
		var minBotInset = [	[x4, y1/2.0], [x5-3, y1/2.0], [x5-3, -(y1/2.0)], [x4, -(y1/2.0)] ];
//		var minBar		= [ [x5, y1/2.0], [x5, -(y1/2.0)] ];

		// define hour hand
		len = 65 * SCALE; 
/*
		var hrDef		= [	[0, y1 ], [x2, y1 ], [x3, y2], [len, y1], [len, y1/2.0], [len, -y1/2.0],
							[len-5, -y1/2.0], [len-5, y1/2.0], [x4, y1/2.0], [x4, -y1/2.0],
							[len, -y1/2.0], [len, -y1], [x3, -y2], [x2, -y1], [0, -y1], 
							[0, y1]   ]; 
*/
		var hrDef		= [	[0, y1 ], [x2, y1 ], [x3, y2], [len, y1], [len, -y1], [x3, -y2], [x2, -y1], [0, -y1], [0, y1]   ]; 

		var hrTopInset	= [	[x5, y1/2.0], [len-4, y1/2.0], [len-4, -(y1/2.0)], [x5, -(y1/2.0)] ];
		var hrBotInset 	= [	[x4, y1/2.0], [x5-3, y1/2.0], [x5-3, -(y1/2.0)], [x4, -(y1/2.0)] ];
//		var hrBar		= [ [x5, y1/2.0], [x5, -(y1/2.0)] ];

		// transform defined shapes based on angles
		var minX		= generateCoords(mid_x, mid_y, 1, 1, minAngle, minDef);					
		var hrX			= generateCoords(mid_x, mid_y, 1, 1, hrAngle, hrDef);
		var minTopInX	= generateCoords(mid_x, mid_y, 1, 1, minAngle, minTopInset);
		var minBotInX	= generateCoords(mid_x, mid_y, 1, 1, minAngle, minBotInset);		
		var hrTopInX	= generateCoords(mid_x, mid_y, 1, 1, hrAngle, hrTopInset);
		var hrBotInX	= generateCoords(mid_x, mid_y, 1, 1, hrAngle, hrBotInset);
//		var minBarX		= generateCoords(mid_x, mid_y, 1, 1, minAngle, minBar);
//		var hrBarX		= generateCoords(mid_x, mid_y, 1, 1, hrAngle, hrBar);

		// draw hour hand
		dc.setColor(c_line, c_trans);
		dc.fillPolygon(hrX);
//		dc.setPenWidth(5);
//		drawPolyOutline (dc, hrBarX);	
//		dc.setPenWidth(1);
		dc.setColor(c_screen, c_trans);
		dc.fillPolygon(hrBotInX);
		dc.setColor(c_fill, c_trans);		
		dc.fillPolygon(hrTopInX);
					
		
		// draw minute hand
		dc.setColor(c_line, c_trans);		
		dc.fillPolygon(minX);
//		dc.setPenWidth(5);
//		drawPolyOutline (dc, minBarX);
//		dc.setPenWidth(1);
		dc.setColor(c_screen, c_trans);
		dc.fillPolygon(minBotInX);		
		dc.setColor(c_fill, c_trans);		
		dc.fillPolygon(minTopInX);

		// draw arbor and pin
		dc.setColor(c_line, c_trans);	
		dc.fillCircle(mid_x, mid_y, 14*SCALE);
		dc.setColor(c_arbor, c_trans);
		dc.fillCircle(mid_x, mid_y, 4*SCALE);
		
	}
	/////////////////////////////////////////////////////////////////////////////////
	// end of draw hour and minute hands 
	/////////////////////////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////
    // Compute a bounding box from the passed in points
    // CREDITS: This function is copied directly from ConnectIQ SDK Analog Sample
	/////////////////////////////////////////////////////////////////////////////////
    function getBoundingBox( points ) {
        var min = [9999,9999];
        var max = [0,0];
        for (var i = 0; i < points.size(); ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }
            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }
            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }
            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }
        return [min, max];
    }
	/////////////////////////////////////////////////////////////////////////////////
    // End of Compute a bounding box from the passed in points
	/////////////////////////////////////////////////////////////////////////////////
    
    

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

/*
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
*/



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

    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
    }

}


class AdventurerScoutDelegate extends Ui.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }

}
