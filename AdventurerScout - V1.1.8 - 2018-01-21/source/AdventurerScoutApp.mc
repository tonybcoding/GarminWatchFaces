using Toybox.Application as App;
using Toybox.WatchUi;

class AdventurerScoutApp extends App.AppBase {

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
    	WatchUi.requestUpdate();
    }

    // Return the initial view of your application here
    function getInitialView() {
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [new AdventurerScoutView(), new AdventurerScoutDelegate()];
        } else {
            return [new AdventurerScoutView()];
        }
    }

}