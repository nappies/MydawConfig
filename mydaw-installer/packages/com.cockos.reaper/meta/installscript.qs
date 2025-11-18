// Global variables
var reaperVersion = "7.42"; // Update as needed
var ReapackRepoUrl = "https://github.com/cfillion/reapack/releases/latest/download/";
var RprRepoUrl = "https://www.reaper.fm/files/7.x/";

var eulaText = "";
var tempDir = "";
var installPath = "";
var instOffline = false;


function LogOut(output) {
    console.log(output);
}


function Component() {
    // Constructor
    installer.setDefaultPageVisible(QInstaller.Introduction, true);
    installer.setDefaultPageVisible(QInstaller.TargetDirectory, true);
    installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
    installer.setDefaultPageVisible(QInstaller.LicenseCheck, true);
    installer.setDefaultPageVisible(QInstaller.ReadyForInstallation, true);
    installer.setDefaultPageVisible(QInstaller.PerformInstallation, true);
    installer.setDefaultPageVisible(QInstaller.FinishedPage, true);
	
	
	
	
	
	
}

Component.prototype.createOperations = function() {
    try {
        component.createOperations();

        // Get installation path
        installPath = installer.value("TargetDir");


        // Get proper temp directory
        tempDir = installer.environmentVariable("TEMP");
        if (tempDir === "") {
            tempDir = installer.environmentVariable("TMP");
        }
        if (tempDir === "") {
            tempDir = installer.environmentVariable("TMPDIR");
        }
        if (tempDir === "") {
            // Fallback for macOS/Linux
            tempDir = "/tmp";
        }


        LogOut("Installing to: " + installPath);
        LogOut("Using temp directory: " + tempDir);

        // Perform installation
        performInstallation();

    } catch (e) {
        LogOut("Error during installation: " + e);
        QMessageBox.critical("installer.error", "Installation Error",
            "An error occurred during installation:\n\n" + e,
            QMessageBox.Ok);
    }
}



// In your controller.qs or component script
function checkInternetConnection() {
    try {
        // Try to fetch a small resource with 5 second timeout
        var exitCode = installer.execute("curl", [
            "-s",
            "--connect-timeout", "5",
            "--max-time", "10",
            "-o", "/dev/null",
            "-w", "%{http_code}",
            "https://www.google.com"
        ])[0];
        LogOut(exitCode);
        if (exitCode === "200")
            return true;
        else
            return false;


    } catch (e) {
        LogOut("Curl check failed: " + e);
        return false;
    }
}

function CheckIntDialog() {
    if (!checkInternetConnection()) {

        // Show EULA dialog
        var buttons = QMessageBox.Retry | QMessageBox.Open | QMessageBox.Cancel;
        var result = QMessageBox.information("CheckInternet",
            "No Internet Connection",
            "Retry - Try Again, Open - Install Offline Reaper "+reaperVersion+" version" ,
            buttons);

        if (result == QMessageBox.Retry) {

            installer.setValue("FinishedText",
                "<font color='green' size=3>Try to reconnect</font>");

            return 0;

        } else if (result == QMessageBox.Open) {

            return 2;

        } else if (result == QMessageBox.Cancel)

        {


            installer.setValue("FinishedText", "<font color='red' size=3>The installer was quit.</font>");
            installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
            installer.setDefaultPageVisible(QInstaller.ReadyForInstallation, false);
            installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
            installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);
            installer.setDefaultPageVisible(QInstaller.PerformInstallation, false);
            installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);
            gui.clickButton(buttons.NextButton);

            return -1;
        }

    }
    return 1;
}


function GetMacOsPath(LongPath)
{
	
        
       // On macOS, truncate the .app bundle path
        if (systemInfo.productType === "osx" || systemInfo.kernelType === "darwin") {
           return LongPath.replace(/\/[^\/]+\.app\/.*$/, '/');

        }


	return LongPath;
}




function checkFileExists(filePath) {
    while (true) {
         
        
		
		
        // Check if file exists
        if (installer.fileExists(filePath)) {
            console.log("File found: " + filePath);
            return true;
        }
        
        // File doesn't exist, show message box
        var result = QMessageBox.question(
            "qmb.fileNotFound",
            "File Not Found",
            getReaperInstallerFileName(getPlatform())+" was not found near installer:\n" + "\n\nWould you like to retry?",
            QMessageBox.Retry | QMessageBox.Cancel,
            QMessageBox.Retry
        );
        
        // Check user's choice
        if (result === QMessageBox.Cancel) {
            console.log("User cancelled installation due to missing file: " + filePath);
            installer.setDefaultPageVisible(QInstaller.Introduction, false);
            installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
            installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
            installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);
            gui.clickButton(buttons.CancelButton);
            return false;
        }
        
        // If Retry was clicked, loop continues
        console.log("Retrying file check for: " + filePath);
    }
}






function performInstallation() {
    
var installerPath;

var dialogResult = CheckIntDialog();  // Call ONCE and store the result
    
    if (dialogResult == -1) {
        return;  // User cancelled
    } else if (dialogResult == 0) {
        // User wants to retry - recursively call this function
        performInstallation();
        return;
    } else if (dialogResult == 2) {
        // User chose offline installation
        instOffline = true;
        
    }

    

    if (!instOffline)
	{
		// Download REAPER installer
        LogOut("Downloading REAPER installer...");
		installerPath = downloadReaperInstaller();
		
	}
	else
	{
		installerPath = installer.value("InstallerDirPath");
		var pathToCheck = GetMacOsPath(installerPath);
		installerPath = pathToCheck + "/" + getReaperInstallerFileName(getPlatform());
	
	}
        

    
	if (checkFileExists(installerPath))
	{
		// Extract REAPER to temp folder
    LogOut("Extracting REAPER...");
	 var extractedPath = extractReaper(installerPath);
		
	}
   

   
   downloadReaPack();

    if (!instOffline)
	component.addElevatedOperation("Delete", installerPath, "UNDOOPERATION", "");




    LogOut("Installation completed successfully");
}



function ToBackslash(path) {
    if (installer.value("os") === "win")
        return path.replace(/\//g, '\\');
    return path;
};



function downloadReaperInstaller() {
    var platform = getPlatform();
    var fileName = getReaperInstallerFileName(platform);
    var url = RprRepoUrl + fileName;
    var destPath = tempDir + "/" + fileName;

    LogOut("Downloading REAPER from: " + url);
    LogOut("Destination: " + destPath);

    downloadFile(url, destPath);

    return destPath;
}


function downloadReaPack() {
    var platform = getPlatform();
    var fileName = getReaPackFileName(platform);
    var url = ReapackRepoUrl + fileName;
	var destFolder = installer.value("TargetDir")+ "/" + "UserPlugins" ;
    var destPath = destFolder + "/" + fileName;

    LogOut("Downloading Reapack from: " + url);
    LogOut("Destination: " + destPath);

    downloadFileAfter(url, destPath);

    return destPath;
}




function extractReaper(installerPath) {
    var platform = getPlatform();
    var extractDir = ToBackslash(installPath);

    LogOut("Extracting from: " + installerPath);
    LogOut("Extract to: " + installPath);

    LogOut("Platform " + platform);

    if (platform === "windows-x64") {
        extractReaperWindows(installerPath, extractDir);
    } else if (platform === "macos") {
        extractReaperMacOS(installerPath, extractDir);
    } else if (platform.indexOf("linux") === 0) {
        extractReaperLinux(installerPath, extractDir);
    }
	
	
	component.addElevatedOperation("Delete", extractDir + "Effects", "UNDOOPERATION", "");
	

    return installPath;
}


function extractReaperWindows(installerPath, destDir) {


    // REAPER installer needs forward slashes in the /D parameter
    var ClnInstallDir = ToBackslash(destDir);

    console.log("Running REAPER installer in portable mode...");
    console.log("Path: " + installerPath + " Dir: " + ClnInstallDir);

    installer.execute(installerPath, ["/S", "/PORTABLE", "/D=" + ClnInstallDir]);
}



function extractReaperMacOS(dmgPath, destDir) {
    // 1. Convert DMG to CDR format (REAPER DMG has license dialog)
    var imgPath = dmgPath.replace(/\.dmg$/i, ".cdr");
    LogOut("Converting REAPER DMG to CDR format: " + imgPath);

    installer.execute("hdiutil", ["convert", dmgPath, "-format", "UDTO", "-o", imgPath.replace(/\.cdr$/, "")]);

    // 2. Mount the converted CDR file
    var mountPoint = tempDir + "/reaper-mount";
    LogOut("Mounting REAPER image to " + mountPoint);

    // Create mount point directory first
    installer.execute("mkdir", ["-p", mountPoint]);

    installer.execute("hdiutil", ["attach", "-nobrowse", "-mountpoint", mountPoint, imgPath]);

    // 2.5 DEBUG: List what's actually in the mount point
    installer.execute("ls", ["-la", mountPoint]);

    // 3. Ensure destination directory exists
    installer.execute("mkdir", ["-p", destDir]);

    // 4. Copy REAPER.app from mounted volume
    // Try without the REAPER_INSTALL_UNIVERSAL subdirectory first
    var sourceApp = mountPoint + "/REAPER.app";
    var destApp = destDir + "/REAPER.app";
    LogOut("Copying REAPER.app from " + sourceApp + " to " + destApp);

    installer.execute("cp", ["-R", sourceApp, destApp]);

    // 5. Detach the mounted volume
    installer.execute("hdiutil", ["detach", mountPoint]);

    // 6. Clean up the CDR file
    installer.execute("rm", ["-f", imgPath]);
}

function extractReaperLinux(tarPath, destDir) {
    // Extract tar.xz archive
    var tmpExtract = tempDir + "/reaper-extract";

    // Create temp extract directory
    installer.execute("mkdir", ["-p", tmpExtract]);

    // Unpack tar into a temporary directory
    installer.execute("tar", ["-xf", tarPath, "-C", tmpExtract]);

    // Move/copy the REAPER directory contents to destDir
    var sourcePath = tmpExtract + "/reaper_linux_x86_64/REAPER";
    // Use cp -r from source/. to preserve contents
    installer.execute("cp", ["-r", sourcePath + "/.", destDir]);
}



function downloadFile(url, destPath) {
    // Use platform-specific download method
    if (systemInfo.kernelType === "winnt") {
        // Windows: use PowerShell
        installer.execute("powershell", ["-Command",
            "(New-Object System.Net.WebClient).DownloadFile('" + url + "', '" + destPath + "')"
        ]);
    } else {

        installer.execute("curl", ["-L", "-o", destPath, url]);

    }

    return destPath;
}



function downloadFileAfter(url, destPath) {
    // Use platform-specific download method
    if (systemInfo.kernelType === "winnt") {
        // Windows: use PowerShell
        component.addElevatedOperation("Execute", "powershell", "-Command",
            "(New-Object System.Net.WebClient).DownloadFile('" + url + "', '" + destPath + "')");
    } else {
        // Unix-like: use curl
        component.addElevatedOperation("Execute", "{0,5,6,7}", "curl", "-L", "-o", destPath, url);
    }
    
    return destPath;
}

function getPlatform() {
    if (systemInfo.kernelType === "winnt") {
        if (systemInfo.currentCpuArchitecture === "x86_64") {
            return "windows-x64";
        } else {
            return "windows-x86";
        }
    } else if (systemInfo.kernelType === "darwin") {
        return "macos";
    } else if (systemInfo.kernelType === "linux") {
        if (systemInfo.currentCpuArchitecture === "x86_64") {
            return "linux-x86_64";
        } else if (systemInfo.currentCpuArchitecture === "aarch64") {
            return "linux-aarch64";
        } else if (systemInfo.currentCpuArchitecture === "armv7l") {
            return "linux-armv7l";
        } else {
            return "linux-i686";
        }
    }
    return "unknown";
}

function getReaperInstallerFileName(platform) {
    var version = reaperVersion.replace(/\./g, "");

    switch (platform) {
        case "windows-x64":
            return "reaper" + version + "_x64-install.exe";
        case "windows-x86":
            return "reaper" + version + "-install.exe";
        case "macos":
            return "reaper" + version + "_universal.dmg";
        case "linux-x86_64":
            return "reaper" + version + "_linux_x86_64.tar.xz";
        case "linux-aarch64":
            return "reaper" + version + "_linux_aarch64.tar.xz";
        case "linux-armv7l":
            return "reaper" + version + "_linux_armv7l.tar.xz";
        case "linux-i686":
            return "reaper" + version + "_linux_i686.tar.xz";
        default:
            throw "Unsupported platform: " + platform;
    }
}





function getReaPackFileName(platform) {
    
    switch (platform) {
        case "windows-x64":
            return "reaper_reapack-x64.dll";
        case "macos":
        {
			

			  return "reaper_reapack-arm64.dylib";
			
			
		}
        default:
            throw "Unsupported platform: " + platform;
    }
}