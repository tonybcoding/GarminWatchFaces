using Toybox.WatchUi 		as Ui;
using Toybox.Graphics 		as Gfx;
using Toybox.System 		as Sys;
using Toybox.Lang 			as Lang;
using Toybox.Time 			as Time;
using Toybox.Math 			as Math;
using Toybox.Application 	as App;
using Toybox.ActivityMonitor;

class firstAnalogWatchfaceCleanView extends Ui.WatchFace {

	// Settings from CIQ mobile app
    var appStore_schemeTheme 	= null;
    var appStore_showBattGauge 	= null;
    var appStore_showStepGauge 	= null;
    var appStore_switchGauges 	= null;
    var appStore_gaugeType		= null;
	var appStore_gaugeHandPlain	= null;    
    var appStore_showFullDay 	= null;
    var appStore_showTicks		= null;
    var appStore_secondType		= null;

	// Must declare globals here, but apparetnly can't call certain system functions yet. 
    var fast_updates 		= false;
	var screenShape			= null;
    var mid_x				= null; // center horizontal
    var mid_y				= null; // center vertical
    var deviceType 			= null;
    var mainFont			= null;
    enum {	F5 			= 1,
    		F3HR 		= 2,
    		FR235 		= 3,
    		schemeWhite = 100,
    		schemeBlack = 101,
    		secStandard	= 200,
    		secRed		= 201,
    		secNone		= 202,
    		gaugeArc	= 300,
    		gaugeDialW	= 301,
    		gaugeDialB	= 302,
    		gaugeNone	= 303
    } // end of enum

	// global color variables
	var	c_screen			= null;
	var c_primary			= null;
	var c_shade				= null;
	var c_battFill			= null;
	var c_stepFill			= null;
	var c_secHand			= null;

	// variables that just need set once, so no need to repeatedly set in onUpdate()
	var arcDir 				= null;
	var arcWidth 			= null;
	var arcStart 			= null;
	var arcEnd 				= null;
	var arcRad 				= null;	
	var inGauge_x			= null;
	var outGauge_x			= null;	
	var dcW 				= null;
	var dcH 				= null;
	var smallFont			= null;

	////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////
	// Function runs every minute (or every second in high power mode)
	////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////
    function onUpdate(dc) {

		// Retrieve settings from ConnectIQ mobile app
	    appStore_schemeTheme 	= App.getApp().getProperty("scheme_prop");
	    appStore_showBattGauge 	= App.getApp().getProperty("battery_prop");
	    appStore_showStepGauge 	= App.getApp().getProperty("steps_prop");
	    appStore_switchGauges 	= App.getApp().getProperty("switch_prop");
	    appStore_gaugeType		= App.getApp().getProperty("gaugetype_prop");
		appStore_gaugeHandPlain = App.getApp().getProperty("gaugehand_prop");
	    appStore_showFullDay 	= App.getApp().getProperty("fullday_prop");
	    appStore_showTicks		= App.getApp().getProperty("ticks_prop");
	    appStore_secondType 	= App.getApp().getProperty("second_prop");

		// set colors based on scheme desired	
		if (appStore_schemeTheme==schemeBlack) {
			c_screen	= Gfx.COLOR_BLACK;
			c_shade		= Gfx.COLOR_LT_GRAY;
			c_primary 	= Gfx.COLOR_WHITE;
			c_battFill	= Gfx.COLOR_DK_RED;
			c_stepFill	= Gfx.COLOR_DK_GREEN;
			c_secHand	= Gfx.COLOR_YELLOW;
		} else {	// default color scheme is White
			c_screen	= Gfx.COLOR_WHITE;		
			c_shade		= Gfx.COLOR_DK_GRAY;
			c_primary 	= Gfx.COLOR_BLACK;
			c_battFill	= Gfx.COLOR_DK_RED;
			c_stepFill	= Gfx.COLOR_DK_GREEN;
			c_secHand	= Gfx.COLOR_DK_GRAY;			
		} // end if to set colors based on scheme
		if (appStore_secondType == secRed) {
			c_secHand 	= Gfx.COLOR_DK_RED;
		} 

		// Set calendar/day and time variables
		var dateString 	= Time.Gregorian.info( Time.now(), Time.FORMAT_MEDIUM);
        var now         = Sys.getClockTime();
		var dayOfWeek 	= dateString.day_of_week.substring(0,2);
		var day 		= dateString.day;
        var hour        = now.hour;
        var minute      = now.min;
        var second      = now.sec;

		// Declare and set gauge variables
		var stepInfo 		= ActivityMonitor.getInfo();
		var stepPerc 		= 1.0 * stepInfo.steps / stepInfo.stepGoal;
		var battery	 		= Sys.getSystemStats().battery;
		var midBattArc_x 	= null;
		var midStepArc_x 	= null;
		var midBattArc_y 	= null;
		var midStepArc_y 	= null;

		// Declare and set hand angles, widths, radii
		var h_fraction 		= minute / 60.0;
		var s_angle 		= (second/60.0 ) * (2*Math.PI);
		var m_angle 		= h_fraction * (2*Math.PI);
		var h_angle 		= (((hour % 12) / 12.0) + (h_fraction / 12.0)) * (2*Math.PI);
        var s_radius 		= 0.95 * mid_y; 	
        var h_radius 		= (0.73 * s_radius); 	
        var m_radius 		= (0.95 * s_radius); 	
		var s_backradius 	= 0.30 * mid_y; 	
		var h_backradius 	= (0.66 * s_backradius); 	
		var m_backradius 	= (0.83 * s_backradius); 
		var h_width 		= 14; 				
		var m_width 		= 12; 				
		var s_width 		= 4;  			

		/////////////////////////////////////////////////////////
		// Clear screen and draw tic marks
		/////////////////////////////////////////////////////////
		dc.setColor(c_screen, c_screen);
		dc.clear();
		drawTicMarks(dc);

		////////////////////////////////////////////
		// draw numbers if show tickmarks not selected 
		////////////////////////////////////////////
		if (!appStore_showTicks) {
			var numFont 	= Gfx.FONT_SYSTEM_LARGE;
			var yOffTop		= (Gfx.getFontHeight(numFont) * (-0.10));
			var yOffBottom	= (dcH - (Gfx.getFontHeight(numFont) * 0.90));			
			var xOffNine 	= (dc.getTextWidthInPixels("9", numFont)*0.15); 
		    dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);		
		    dc.drawText(mid_x, yOffTop, numFont, "12", Graphics.TEXT_JUSTIFY_CENTER);
		    dc.drawText(mid_x, yOffBottom, numFont, "6", Graphics.TEXT_JUSTIFY_CENTER);
		    dc.drawText(xOffNine, mid_y, numFont, "9", Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
		}
		
		/////////////////////////////////////////////////////////
		// draw day of week and day
		/////////////////////////////////////////////////////////
		var dateBorder 	= 3;
		var dayPad 		= (day < 10) ? "  " : " ";
		var n 			= (appStore_showFullDay) ? 
						  ((dc.getTextWidthInPixels((" " + dayOfWeek.toUpper() + " " + dayPad + day + " "), mainFont)) + dateBorder * 2) :
						  ((dc.getTextWidthInPixels((dayPad + day + " "), mainFont)) + dateBorder * 2);		
		var x 			= dcW - (n + 8);
		var y 			= dcH/2 - (Gfx.getFontHeight(mainFont)/2+dateBorder);

		dc.setColor(c_shade, Gfx.COLOR_TRANSPARENT);
		dc.fillRectangle(x, (y+1), (n+1), (Gfx.getFontHeight(mainFont)+dateBorder*2) );
		if (appStore_showFullDay) {
			dc.setColor(c_primary, c_screen);
		    dc.drawText(x+dateBorder, y+dateBorder, mainFont, (" " + dayOfWeek.toUpper() + " "), Gfx.TEXT_JUSTIFY_LEFT);
		}
		dc.setColor(c_screen, c_primary);
		dc.drawText(x+n-dateBorder, y+dateBorder, mainFont, (dayPad + day + " "), Gfx.TEXT_JUSTIFY_RIGHT); 

		/////////////////////////////////////////////////////////
		// Draw gauges based on either dial or arc from mobile app
		/////////////////////////////////////////////////////////
		if (appStore_gaugeType == gaugeDialW || appStore_gaugeType == gaugeDialB) {
			drawStatGauges(dc, stepPerc, battery);
		} 
		else if (appStore_gaugeType == gaugeArc) {
			if (!appStore_switchGauges) {
				midStepArc_x = inGauge_x;
				midBattArc_x = outGauge_x;
			} else {
				midBattArc_x = inGauge_x;
				midStepArc_x = outGauge_x;
			}	
			if (appStore_showBattGauge) {
			    drawStatArcs(dc, midBattArc_x, arcRad, arcWidth, arcDir, c_battFill, arcStart, arcEnd, (battery/100));
			}
			if (appStore_showStepGauge) {
			    drawStatArcs(dc, midStepArc_x, arcRad, arcWidth, arcDir, c_stepFill, arcStart, arcEnd, stepPerc);
			}		
		}

		/////////////////////////////////////////////
		// Draw clock hands and arbor
		/////////////////////////////////////////////
		// Hour Hand
		// outline
        dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateHandCoordinates([mid_x, mid_y], h_angle, h_radius+1, h_backradius+1, h_width+2));
		// hand and fill
        dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateHandCoordinates([mid_x, mid_y], h_angle, h_radius, h_backradius, h_width));
		dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateHandCoordinates([mid_x, mid_y], h_angle, h_radius*0.90, -(h_radius*0.20), h_width*0.40));

		// Minute Hand
		// outline
        dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateHandCoordinates([mid_x, mid_y], m_angle, m_radius+1, m_backradius+1, m_width+2));
		// hand and fill
        dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateHandCoordinates([mid_x, mid_y], m_angle, m_radius, m_backradius, m_width));
		dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateHandCoordinates([mid_x, mid_y], m_angle, m_radius*0.90, -(m_radius*0.20), m_width*0.35));

		// Draw bottom arbor (connector) in center
		dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
    	dc.fillCircle(mid_x, mid_y, 9);	
		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
    	dc.fillCircle(mid_x, mid_y, 8);	

		// If in high power mode, add seconds, etc.
		if (fast_updates) {
			if (appStore_secondType != secNone) {
	        	dc.setColor(c_secHand, Gfx.COLOR_TRANSPARENT);
				dc.fillPolygon(generateHandCoordinates([mid_x, mid_y], s_angle, s_radius, s_backradius, s_width));
			}
		} // end if fast update test
	
		// Draw top arbor (connector) in center
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    	dc.fillCircle(mid_x, mid_y, 5);	
    	dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
    	dc.fillCircle(mid_x, mid_y, 4);	
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    	dc.fillCircle(mid_x, mid_y, 2);	

    }
	////////////////////////////////////////////////////////////////
	// End of onUpdate function
	////////////////////////////////////////////////////////////////



	////////////////////////////////////////////////////////////////
	// Credit: Function used directly from AnalogView.mc SDK Analog Example
    // This function is used to generate the coordinates of the 4 corners of the polygon
    // used to draw a watch hand. The coordinates are generated with specified length,
    // tail length, and width and rotated around the center point at the provided angle.
    // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
	////////////////////////////////////////////////////////////////
    function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), tailLength], [-(width / 2), -handLength], [width / 2, -handLength], [width / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    } // end of generateHandCoordinates


	////////////////////////////////////////////////////////////////
	// Credit: Function modified heavily from generateHandCoordinates from AnalogView.mc SDK Analog Example
    // This function is used to generate the coordinates of the 3 corners of the "triangle"
    // used to draw guage. The coordinates are generated with specified length and
    // base width and rotated around the center point at the provided angle.
    // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
	////////////////////////////////////////////////////////////////
    function generateDialHandCoordinates(centerPoint, angle, length, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), 0], [0, -length], [0, -length], [width / 2, 0]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    } // end of generateHandCoordinates


	////////////////////////////////////////////////////////////////
	// drawTicMarks function
	// Credit: modified heavily from AnalogView.mc in SDK Samples
	////////////////////////////////////////////////////////////////
    function drawTicMarks(dc) {

		dc.setColor(c_primary, c_screen);
		dc.setPenWidth(3);

		//////////////////////////////////////////////		
		// Draw for circular watchface
		//////////////////////////////////////////////
        if (System.SCREEN_SHAPE_ROUND == screenShape) {
            var sX, sY;
            var eX, eY;
            var outterRad = (mid_x);
            var innerRad = null;

			// Loop through each sec or 6 degree mark, starting at 3 o'clock position
			for (var n = 2; n < 59; n++) {
			var test = (appStore_showTicks) ? n : n+1;
 				if ( !((test) % 15 == 0) ) { // skip two tick marks before & after number, or one before and after major tick
					var hashAngle = n * Math.PI/30;
					if (!((n % 5) == 0) || ((n-1) %5 == 0) || ((n+1) %5 == 0)) {		// set every second properties
						dc.setColor(c_shade, c_screen);
						dc.setPenWidth(1);
						innerRad = outterRad -10;	                
	                } else {					// set major tick properties (every five minutes)
						dc.setColor(c_primary, c_screen);
						dc.setPenWidth(3);	
						innerRad = outterRad -15;              
	                }
	                if (n % 15 != 0) {			// ignore 15 mins, and date (by virtue of starting n at 2 and ending at 58--3 o'clock position is '0'
		                sY = outterRad + innerRad * Math.sin(hashAngle);
		                eY = outterRad + outterRad * Math.sin(hashAngle);
		                sX = outterRad + innerRad * Math.cos(hashAngle);
		                eX = outterRad + outterRad * Math.cos(hashAngle);
						dc.drawLine(sX, sY, eX, eY);
					}
				} else {
					if (!appStore_showTicks) {
						n+=2;
					}
				} // end check to make sure we do not draw tick mark before and after number
				
			} // end for
			
			// if showTicks, then add additional tick marks			
			if (appStore_showTicks) {
				var penWidth 	= 4;
				var tickLength	= mid_x * 0.20;
				dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
				dc.setPenWidth(penWidth);
				dc.drawLine(mid_x-penWidth, 0, mid_x-penWidth, tickLength);			// 12 position
				dc.drawLine(mid_x+penWidth, 0, mid_x+penWidth, tickLength);			// 12 position
				dc.drawLine(mid_x-penWidth, dcH-tickLength, mid_x-penWidth, dcH);	// 6 position
				dc.drawLine(mid_x+penWidth, dcH-tickLength, mid_x+penWidth, dcH);	// 6 position				
				dc.drawLine(0, mid_y-penWidth, tickLength, mid_y-penWidth);			// 9 position
				dc.drawLine(0, mid_y+penWidth, tickLength, mid_y+penWidth);			// 9 position				
				dc.setPenWidth(1);	
			} // end of adding additional tick marks
/*			
			// clear edge of screen--create some space
			dc.setColor(c_screen, c_screen);
			dc.setPenWidth(10);
			dc.drawCircle(mid_x, mid_y, mid_x + 2);
			dc.setPenWidth(1);
*/
        } // end of drawing tick marks for round watchface

		//////////////////////////////////////////////		
		// Draw for non-circular watchface
		//////////////////////////////////////////////
        else { 

			var hashRadius = mid_y;
			if (mid_x > mid_y) {
			    hashRadius = mid_x;
			}

			// tick marks that need less "visibility"--more "clear out"
			dc.setPenWidth(3);	
			dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
			for (var n = 1; n < 12; n++) {
				var hashAngle = (n * (Math.PI/6));
				if ( !(n % 3 == 0) && (n % 2 != 0) ) {
					dc.drawLine(mid_x, 
							    mid_y, 
							    mid_x + (hashRadius+2) * Math.cos(hashAngle),
							    mid_y + (hashRadius+2) * Math.sin(hashAngle));
				}
				
			}
			// clear out middle for shorter ticks
			dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
			dc.setPenWidth(1);
			dc.fillCircle(mid_x, mid_y, hashRadius-10);

			// tick marks that need more "visibility"--less "clear out"
			dc.setPenWidth(3);	
			dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
			for (var n = 1; n < 12; n++) {
				var hashAngle = (n * (Math.PI/6));
				if ( !(n % 3 == 0) && (n % 2 == 0) ) {
					dc.drawLine(mid_x, 
							    mid_y, 
							    mid_x + (hashRadius+2) * Math.cos(hashAngle),
							    mid_y + (hashRadius+2) * Math.sin(hashAngle));
				}
				
			}
			// clear out middle for shorter ticks
			dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
			dc.setPenWidth(1);
			dc.fillCircle(mid_x, mid_y, hashRadius-15);

			// if showTicks, then add additional tick marks			
			if (appStore_showTicks) {
				var penWidth 	= 4;
				dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
				dc.setPenWidth(penWidth);
				dc.drawLine(mid_x-penWidth, 0, mid_x-penWidth, 12);			// 12 position
				dc.drawLine(mid_x+penWidth, 0, mid_x+penWidth, 12);			// 12 position
				dc.drawLine(mid_x-penWidth, dcH-12, mid_x-penWidth, dcH);	// 6 position
				dc.drawLine(mid_x+penWidth, dcH-12, mid_x+penWidth, dcH);	// 6 position				
				dc.drawLine(0, mid_y-penWidth, 15, mid_y-penWidth);			// 9 position
				dc.drawLine(0, mid_y+penWidth, 15, mid_y+penWidth);			// 9 position				
				dc.setPenWidth(1);	
			}
 
		} // end of else (drawing tick marks for non-round devices)
		
    }
	////////////////////////////////////////////////////////////////
	// End drawTicMarks function
	////////////////////////////////////////////////////////////////


    /////////////////////////////////////////
    // drawStatArcs function
	/////////////////////////////////////////
	function drawStatArcs(dc, x, r, width, dir, color, start, end, metric) {

		var arcFull = (end - start);
		var y = mid_y;
		var n = null;
		
		// draw "borders" by drawing arcs of primary color and smaller arcs for screen color to "blank" them out
		dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
		for (n = 0; n <= (width+3); n++) {
			dc.drawArc(x - n + 2, y, r, dir, start - 1, end + 1);
		}
		dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
		for (n = 0; n <= (width); n++) {
			dc.drawArc(x - n + 1, y, r, dir, start, end);
		}

		// draw arc fill
	    if (metric <=1) {
		    arcFull = (end-start)*(metric);
		} else {
		    arcFull = (end-start);		
		}
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);
		if (arcFull > 1) {
			for (n = 0; n <= width; n++) {
			    dc.drawArc(x - n + 1, y, r, dir, end-arcFull, end);
			}
		}

	}
    /////////////////////////////////////////
    // End drawStatArcs function
	/////////////////////////////////////////


    /////////////////////////////////////////
    // drawStatGauges function
	/////////////////////////////////////////
	function drawStatGauges (dc, sMetric, bMetric) {

		var x0 			= mid_x * 0.65;			// beginning x position for gauges
		var yOff 		= 0.32*(240.0/dcH);		// move y up or down this percentage from mid
		var topMetric	= null;
		var botMetric	= null;
		var topFill		= null;
		var botFill		= null;
		var topLabel	= null;
		var botLabel	= null;
		
		// Set metric parameters and determine positions
		sMetric 		= (sMetric > 1) ? 1 : sMetric;	// if sMetric (stepPer) > 100%, then set to 100%
		bMetric			= bMetric / 100;				// transform into "percentage"
		if (!appStore_switchGauges) {
			if (appStore_showBattGauge) {
				topMetric 	= bMetric;
				topFill		= c_battFill;
				topLabel	= "bat";
			}
			if (appStore_showStepGauge) {
				botMetric 	= sMetric;
				botFill		= c_stepFill;
				botLabel	= "stp";
			}
		} else {
			if (appStore_showStepGauge) {
				topMetric = sMetric;
				topFill		= c_stepFill;
				topLabel	= "stp";
			}
			if (appStore_showBattGauge) {
				botMetric = bMetric;
				botFill		= c_battFill;
				botLabel	= "bat";
			}
		}

		// if only showing one gauge, then set y-Offset and x position in center on left side of watch face
		if (topMetric == null || botMetric == null) {
			yOff 	= 0;
			x0		= mid_x * 0.55;
		}

		if (topMetric != null) {		
			drawGauge(dc, x0, mid_y*(1-yOff), topLabel, topMetric, topFill);
		}
		if (botMetric != null) {		
			drawGauge(dc, x0, mid_y*(1+yOff), botLabel, botMetric, botFill);
		}
	}
    /////////////////////////////////////////
    // End drawStatGauges function
	/////////////////////////////////////////

	//////////////////////////////////////////////////////////
	// drawGauge - helper function of drawStatGauges
	//////////////////////////////////////////////////////////

	function drawGauge (dc, x, y, label, metric, fill) {
		var rad 		= 6;					// radius of dial hand at base (circle)
		var len 		= 30;					// length of dial hand
		var dialRad		= 34;
		var start 		= Math.toRadians(-40.0) - Math.toRadians(90.0);	
		var end 		= Math.toRadians(220.0) - Math.toRadians(90.0);
		var angle_adj 	= null;
		var fullLabel	= null;
		var zeroLabel	= null;
		var colFace		= null;
		var colOutline	= null;
		var colHand		= null;
		var colLabel	= null;
		var colMetric	= null;
		var label_yOff	= 0.50;
		var label_xOff	= 0.65;
		
		
		if (label.toString().equals("bat")){
			fullLabel = "F";
			zeroLabel = "0";
		} else {
			fullLabel = "G";
			zeroLabel = "0";
		}

		if (appStore_gaugeType == gaugeDialW) {
			colFace		= Gfx.COLOR_WHITE;
			colOutline	= (appStore_schemeTheme==schemeBlack) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
			colHand		= Gfx.COLOR_BLACK;
			colLabel	= Gfx.COLOR_DK_GRAY;
			colMetric	= Gfx.COLOR_BLACK;
		}
		else if (appStore_gaugeType == gaugeDialB) {
			colFace		= Gfx.COLOR_BLACK;
			colOutline	= (appStore_schemeTheme==schemeBlack) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
			colHand		= Gfx.COLOR_WHITE;
			colLabel	= Gfx.COLOR_LT_GRAY;
			colMetric	= Gfx.COLOR_WHITE;
		}
		
		if (!appStore_gaugeHandPlain) {
			colHand		= fill;		
		}

		dc.setColor(colFace, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(2);
		dc.fillCircle(x, y, dialRad);
		dc.setPenWidth(1);

		// draw circle around dial
		dc.setColor(colOutline, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(2);
		dc.drawCircle(x, y, dialRad);
		dc.setPenWidth(1);
		
		// draw guage labels				
		dc.setColor(colMetric, Gfx.COLOR_TRANSPARENT);
		dc.drawText(x, y+(dialRad*0.40), smallFont, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.setColor(colLabel, Gfx.COLOR_TRANSPARENT);
		dc.drawText(x, y-(dialRad*0.80), smallFont, "50", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x-(dialRad*label_xOff), y-(dialRad*0.30), smallFont, "25", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x+(dialRad*label_xOff), y-(dialRad*0.30), smallFont, "75", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x+(dialRad*label_xOff), y+(dialRad*(1-label_yOff)), smallFont, fullLabel, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x-(dialRad*label_xOff), y+(dialRad*(1-label_yOff)), smallFont, zeroLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

		// draw guage ticks
		dc.setColor(colMetric, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(x-(len-2), y+6, 2); 	// 12.5%
		dc.fillCircle(x+(len-2), y+6, 2); 	// 87.5%		
		dc.fillCircle(x-(len-14), y-24, 2);	// 37.5%		
		dc.fillCircle(x+(len-14), y-24, 2);	// 62.5%		
		
		// Display gauge
		angle_adj = start + ((metric) * (end - start));	
		dc.setColor(colHand, Gfx.COLOR_TRANSPARENT);
    	dc.fillCircle(x, y, rad);
    	dc.fillPolygon(generateDialHandCoordinates([x, y], angle_adj, len, rad*2));
		dc.setColor(colFace, Gfx.COLOR_TRANSPARENT);
		dc.drawCircle(x, y, 2);    	
	}



/*
	function drawGauge (dc, x, y, label, metric, fill) {
		var wid 		= 8;							// Width of base of hand
		var len 		= 40;							// length of dial hand
		var gaugeRad	= 34;							// radius of gauge dials
		var angStart 	= Math.PI/4.0 - Math.PI/2.0;	// percentage of circle to start with 0%/100% being 12 o'clock
		var angEnd 		= 3.0*Math.PI/4.0 - Math.PI/2.0;// end relative to start
		var angle_adj 	= null;							// used to determine how much to offset angle based on relevant metric	
		var fullLabel		= null;
		var zeroLabel		= null;
		var colFace		= null;
		var colOutline	= null;
		var colHand		= null;
		var colLabel	= null;
		var colMetric	= null;
		
		
		if (label.toString().equals("batt")){
			fullLabel = "F";
			zeroLabel = "E";
		} else {
			fullLabel = "G";
			zeroLabel = "0";
		}

		if (appStore_gaugeType == gaugeDialW) {
			colFace		= Gfx.COLOR_WHITE;
			colOutline	= (appStore_schemeTheme==schemeBlack) ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_BLACK;
			colHand		= Gfx.COLOR_BLACK;
			colLabel	= Gfx.COLOR_DK_GRAY;
			colMetric	= Gfx.COLOR_BLACK;
		}
		else if (appStore_gaugeType == gaugeDialB) {
			colFace		= Gfx.COLOR_BLACK;
			colOutline	= (appStore_schemeTheme==schemeBlack) ? Gfx.COLOR_WHITE : Gfx.COLOR_LT_GRAY;
			colHand		= Gfx.COLOR_WHITE;
			colLabel	= Gfx.COLOR_LT_GRAY;
			colMetric	= Gfx.COLOR_WHITE;
		}
		
		if (!appStore_gaugeHandPlain) {
			colHand		= fill;		
		}


		// Draw gauge fill and outline
		dc.setColor(colFace, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(x, y, gaugeRad);
		dc.setColor(colOutline, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(2);
		dc.drawCircle(x, y, gaugeRad);
		dc.setPenWidth(1);


		// draw guage labels				
		dc.setColor(colLabel, Gfx.COLOR_TRANSPARENT);
		dc.drawText(x-(gaugeRad+6-9), y, smallFont, zeroLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x+(gaugeRad+6-9), y, smallFont, fullLabel, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x, y-15, smallFont, "50", Graphics.TEXT_JUSTIFY_CENTER); 
		dc.setColor(colMetric, Gfx.COLOR_TRANSPARENT);
		dc.drawText(x, y-33, smallFont, label, Graphics.TEXT_JUSTIFY_CENTER);

		
		// Display gauge
		angle_adj = (angStart + ((metric) * (angEnd - angStart)));	// angle goes from 60 to 90 degrees
		dc.setColor(colHand, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateDialHandCoordinates([x, y + (gaugeRad * 0.80)], angle_adj, len, wid));
		dc.fillCircle(x, y + (gaugeRad * 0.80), wid/2);
		dc.setColor(colFace, Gfx.COLOR_TRANSPARENT);
		dc.drawCircle(x, y + (gaugeRad * 0.80), 2);
	}
*/
/*
	function drawGauge (dc, x, y, label, metric, fill) {
		var wid 		= 10;							// Width of base of hand
		var len 		= 51;							// length of dial hand
		var gaugeRad	= 34;							// radius of gauge dials
		var angStart 	= Math.PI/3.0 - Math.PI/2.0;	// percentage of circle to start with 0%/100% being 12 o'clock
		var angEnd 		= (Math.PI/1.5) - Math.PI/2.0;	// end relative to start
		var angle_adj 	= null;							// used to determine how much to offset angle based on relevant metric	
		var fullLabel		= null;
		var zeroLabel		= null;
		var colFace		= null;
		var colOutline	= null;
		var colHand		= null;
		var colLabel	= null;
		var colMetric	= null;
		
		
		if (label.toString().equals("batt")){
			fullLabel = "F";
			zeroLabel = "E";
		} else {
			fullLabel = "G";
			zeroLabel = "0";
		}

		if (appStore_gaugeType == gaugeDialW) {
			colFace		= Gfx.COLOR_WHITE;
			colOutline	= (appStore_schemeTheme==schemeBlack) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY;
			colHand		= Gfx.COLOR_BLACK;
			colLabel	= Gfx.COLOR_DK_GRAY;
			colMetric	= Gfx.COLOR_BLACK;
		}
		else if (appStore_gaugeType == gaugeDialB) {
			colFace		= Gfx.COLOR_BLACK;
			colOutline	= (appStore_schemeTheme==schemeBlack) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY;
			colHand		= Gfx.COLOR_WHITE;
			colLabel	= Gfx.COLOR_LT_GRAY;
			colMetric	= Gfx.COLOR_WHITE;
		}
		
		if (!appStore_gaugeHandPlain) {
			colHand		= fill;		
		}


		// Draw gauge fill
		dc.setColor(colFace, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(x, y, gaugeRad);
		dc.setColor(colOutline, Gfx.COLOR_TRANSPARENT);



		// draw guage labels				
		dc.setColor(colLabel, Gfx.COLOR_TRANSPARENT);
		dc.drawText(x-(gaugeRad-9), y-13, smallFont, zeroLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x+(gaugeRad-9), y-13, smallFont, fullLabel, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(x, y-25, smallFont, "50", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER); 

		
		// Display gauge
		angle_adj = (angStart + ((metric) * (angEnd - angStart)));	// angle goes from 60 to 90 degrees
		dc.setColor(colHand, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon(generateDialHandCoordinates([x, y + (gaugeRad * 0.80)], angle_adj, len, wid));



		// draw gauge outline
		dc.setColor(colOutline, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(2);
		dc.drawCircle(x, y, gaugeRad);
		dc.drawLine(x-30, y+13, x+30, y+13);
		dc.setPenWidth(1);

		// Blank out bottom of gauge and draw metric identifier
		dc.setColor(c_screen, Gfx.COLOR_TRANSPARENT);
		dc.fillRectangle(x-32, y+14, 64, 21);
		dc.setColor(c_primary, Gfx.COLOR_TRANSPARENT);
		dc.drawText(x, y+20, smallFont, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
*/
    /////////////////////////////////////////
    // End drawGauge helper function
	/////////////////////////////////////////



	////////////////////////////////////////////////////////////////
	// Initialize watchface
	////////////////////////////////////////////////////////////////
    function initialize() {
        WatchFace.initialize();
        screenShape = System.getDeviceSettings().screenShape;
    }

	////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////
	// Function runs only when layout is initially selected
	////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////
    function onLayout(dc) {

		// set globals here
		dcW 				= dc.getWidth();
		dcH 				= dc.getHeight();
		mid_x				= dcW / 2;
		mid_y				= dcH / 2;        
        screenShape 		= Sys.getDeviceSettings().screenShape;
        smallFont			= Ui.loadResource(Rez.Fonts.proan_font);        
		 
		// Determine Device Type
		// Set device-specific settings based on device type, which is determined by width (need better way)
		arcDir 		= Gfx.ARC_COUNTER_CLOCKWISE;
		arcStart 	= 145;
		arcEnd 		= 215;
		arcWidth 	= 7;
		if (mid_x == 120) {
			deviceType = F5;					// Fenix5, Fenix 5S
			mainFont = Gfx.FONT_XTINY;
			outGauge_x 	= mid_x*1.20;
			inGauge_x 	= mid_x*1.36;
			arcRad 		= 96;
		} else if (mid_x == 109) {		    
			deviceType = F3HR;					// Fenix3 HR, Fenix 3, Fenix 5S, Fenix Chronos
			mainFont = Gfx.FONT_SMALL;
			outGauge_x 	= mid_x*1.27;
			inGauge_x 	= mid_x*1.45;		
			arcRad 		= 94;
		} else {
			deviceType = FR235;					// FR235/230 or similar
			mainFont = Gfx.FONT_MEDIUM;
			outGauge_x 	= mid_x*1.15;
			inGauge_x 	= mid_x*1.33;		
			arcRad 		= 90;		
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

	////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////
	// Not using these functions
	////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////    
	function onShow() {
    }
    
    function onHide() {
    }
    
    
}
