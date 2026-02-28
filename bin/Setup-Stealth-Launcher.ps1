<#
.SYNOPSIS
    Creates a "Fake Folder" shortcut on the USB root that secretly launches ORION.
    This is the safest software-only method to trick users into launching ORION
    on a new PC without needing AutoRun or Hardware flashing.

.DESCRIPTION
    1. Sets the actual launcher (Start-Orion-Portable.bat) and the backend folder to Hidden.
    2. Creates a Windows Shortcut (.lnk) disguised as a normal File Explorer folder.
    3. Clicking the folder silently executes the batch file.
#>

$UsbRoot = "G:\"  # Ensure this is the correct drive letter for the pendrive

Write-Host "========================================="
Write-Host " Setting up ORION Stealth 'Plug & Play'  "
Write-Host "========================================="

# 1. Hide the actual files so the user doesn't get confused
$FilesToHide = @("Start-Orion-Portable.bat", "ORION_USB", "autorun.inf")

foreach ($File in $FilesToHide) {
    $Path = Join-Path $UsbRoot $File
    if (Test-Path $Path) {
        Write-Host "Hiding true system file: $File"
        $Item = Get-Item $Path
        # Toggle the Hidden attribute
        if (-not $Item.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)) {
            $Item.Attributes = $Item.Attributes -bor [System.IO.FileAttributes]::Hidden
        }
    }
}

# 2. Create the "Fake Folder" Shortcut
$ShortcutName = "ORION_System"
$ShortcutPath = Join-Path $UsbRoot "$ShortcutName.lnk"

Write-Host "Generating Fake Folder Shortcut..."
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

# Fix: We must use PowerShell or Explorer to launch it because shortcuts launched
# from the root of a drive sometimes have their WorkingDirectory default to System32
# instead of the USB Root, causing "Start-Orion-Portable.bat" to not be found.
# By passing %~dp0 implicitly via powershell, we guarantee it finds the file.

$Shortcut.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"& { Start-Process (Join-Path `$PSScriptRoot 'Start-Orion-Portable.bat' -Resolve) }`""

# Make the window minimized
$Shortcut.WindowStyle = 7

# Start in the directory where the shortcut resides (the USB root).
$Shortcut.WorkingDirectory = ""

# 3. SET THE FAKE FOLDER ICON
$Shortcut.IconLocation = "$env:WINDIR\System32\shell32.dll,3"

$Shortcut.Save()

Write-Host "=========================================" -ForegroundColor Green
Write-Host "✅ SUCCESS! Stealth Shortcut Created." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "When you plug this into any new computer:"
Write-Host "1. Open the Drive."
Write-Host "2. You will see a normal-looking folder named '$ShortcutName'."
Write-Host "3. Double-clicking that 'folder' will instantly boot ORION."
Write-Host ""
Write-Host "Note: To see your hidden files, go to View > Show > Hidden items in File Explorer." -ForegroundColor Yellow
Pause
