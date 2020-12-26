using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class firstAnalogWatchfaceCleanApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

	////////////////////////////////////////////////////////////////
	// Function to request refresh when ConnectIQ mobile app makes changes
	////////////////////////////////////////////////////////////////
    function onSettingsChanged() {
    	Ui.requestUpdate();
    }
    /////////////////////////////////////////
    // End onSettingsChanged function
	/////////////////////////////////////////


    // Return the initial view of your application here
    function getInitialView() {
        return [ new firstAnalogWatchfaceCleanView() ];
    }

}