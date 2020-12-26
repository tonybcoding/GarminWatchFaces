using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class SpecialOpsApp extends App.AppBase {

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

    // Return the initial view of your application here
    function getInitialView() {
        return [ new SpecialOpsView() ];
    }

}