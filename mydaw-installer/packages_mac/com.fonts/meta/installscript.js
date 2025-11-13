function Component()
{
}

Component.prototype.createOperationsForArchive = function(archive)
{
    component.addOperation("Extract", archive, "@TargetDir@/fonts");
    
    if (systemInfo.productType === "windows") {
        // Windows: Copy to Fonts folder and register in registry
        var fontFiles = installer.execute("cmd", ["/c", "dir", "/b", "@TargetDir@/fonts/*.ttf"])[0].split("\n");
        
        component.addElevatedOperation("Execute", 
            "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
            "$fonts = Get-ChildItem '@TargetDir@/fonts' -Include *.ttf,*.otf -Recurse; " +
            "foreach ($font in $fonts) { " +
            "Copy-Item $font.FullName 'C:\\Windows\\Fonts\\' -Force; " +
            "$name = $font.BaseName + ' (TrueType)'; " +
            "New-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts' " +
            "-Name $name -PropertyType String -Value $font.Name -Force " +
            "}"
        );
    } 
    else if (systemInfo.kernelType === "darwin") {
        // macOS: Copy to system Fonts folder
        component.addElevatedOperation("Execute", 
            "sh", "-c", 
            "cp '@TargetDir@/fonts'/*.ttf '@TargetDir@/fonts'/*.otf /Library/Fonts/ 2>/dev/null || true"
        );
		
    }

     component.addElevatedOperation("Delete", "@TargetDir@/fonts", "UNDOOPERATION", "");



}