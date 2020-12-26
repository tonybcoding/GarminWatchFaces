using Toybox.WatchUi as Ui;

class proAnWatchFaceDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
    }
    
    function onStop() {
    	// exit app
    }
    
	// set indicator to next screen. If greater than last screen in rotation, go to first screen
    function onNextPage() {

    }    

	// set indicator to previous screen. If less than 1, go to last screen in rotation
    function onPreviousPage() {

    }  
    
	// alternate indicator to show battery and latency stats (on/off)
    function onSelect() {
    	buttonSelect = (buttonSelect) ? false : true;
    }

}