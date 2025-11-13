function Controller()
{
}

Controller.prototype.IntroductionPageCallback = function()
{
    var warning = "<font color='red' size=4>Carefully select the installation folder to avoid accidental deletion! Do not install Reaper over your existing configuration, it will destroy it!</font>";

    var widget = gui.currentPageWidget(); // get the current wizard page
    if (widget != null) {
        widget.MessageLabel.setText("Welcome to MyDaw Config Setup! 🤗 <br> This installer, in addition to MyDaw Config, also downloads and installs Cockos Reaper. Installation is only in portable mode! This means the program will be stored in a single folder. <br>"+warning); 
    }
}


// Example function to run before the installation page
Controller.prototype.ReadyForInstallationPageCallback = function() {
    

	var defText;

    var widget = gui.currentPageWidget(); // get the current wizard page
    if (widget != null) {
        defText = widget.MessageLabel.getText();
		widget.MessageLabel.setText(defText + " n/ Reaper Downloading... "); 
    }



  
}