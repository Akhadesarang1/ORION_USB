<#
.SYNOPSIS
    Sets up a Windows Scheduled Task to automatically start the ORION Portable USB
    system when the pendrive is plugged in.

.DESCRIPTION
    This script creates a Windows Event-triggered Scheduled Task. It listens to
    the Microsoft-Windows-DriverFrameworks-UserMode/Operational event log for Event ID 2003
    (USB device connected). When it detects a connection, it executes a wrapper script
    that searches for the Start-Orion-Portable.bat on all connected drives and launches it.

    NOTE: MUST BE RUN AS ADMINISTRATOR.
#>

$ErrorActionPreference = "Stop"
$TaskName = "AutoLaunchOrionUSB"

# Check if running as Admin
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator to create the Scheduled Task." -ForegroundColor Red
    Pause
    Exit
}

# 1. We need a persistent script on the host machine to search for the USB drive when an event fires
$HostScriptPath = "$env:LOCALAPPDATA\OrionUSBLauncher.ps1"
$HostScriptContent = @"
`$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { `$_.Root -match '^[A-Z]:\\$' }
foreach (`$drive in `$drives) {
    `$targetPath = Join-Path `$drive.Root "Start-Orion-Portable.bat"
    if (Test-Path `$targetPath) {
        # Found it! Launch it and exit the search
        Start-Process -FilePath `$targetPath -WorkingDirectory `$drive.Root
        Exit
    }
}
"@

Set-Content -Path $HostScriptPath -Value $HostScriptContent
Write-Host "Created USB search script on host at: $HostScriptPath" -ForegroundColor Cyan

# 2. Enable the required event log so we can trigger the task
$LogName = "Microsoft-Windows-DriverFrameworks-UserMode/Operational"
$logStatus = wevtutil gl $LogName | Select-String "enabled: true"
if (-not $logStatus) {
    Write-Host "Enabling USB device connection event log..." -ForegroundColor Yellow
    wevtutil sl $LogName /e:true
}

# 3. Create the Scheduled Task
$Trigger = New-ScheduledTaskTrigger -AtLogOn
# We replace the trigger with an Event trigger since New-ScheduledTaskTrigger doesn't natively do Event triggers easily in PSv5
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$HostScriptPath`""
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

# Define the Event Subscription XML string
$Subscription = @"
<QueryList>
  <Query Id="0" Path="$LogName">
    <Select Path="$LogName">*[System[Provider[@Name='Microsoft-Windows-DriverFrameworks-UserMode'] and EventID=2003]]</Select>
  </Query>
</QueryList>
"@

Try {
    # Delete if it already exists
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    $Task = New-ScheduledTask -Action $Action -Principal $Principal -Description "Launches ORION when its USB drive is connected"
    # We must tweak the inner XML to set the Event trigger
    $TaskRoot = "<?xml version=`"1.0`" encoding=`"UTF-16`"?>`n" + $Task.CimClass.CimSystemProperties | Out-Null # suppress dump

    # We use schtasks to create from XML because it's much more reliable for Event triggers
    $xmlPath = "$env:TEMP\OrionTask.xml"

    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Launches ORION when its USB drive is connected</Description>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>$Subscription</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$env:USERDOMAIN\$env:USERNAME</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-WindowStyle Hidden -ExecutionPolicy Bypass -File "$HostScriptPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
    Set-Content -Path $xmlPath -Value $taskXml

    schtasks /create /tn $TaskName /xml $xmlPath /f | Out-Null
    Remove-Item $xmlPath

    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "✅ SUCCESS: ORION USB AutoLaunch Host Setup Complete!" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "Whenever you plug in any USB drive, Windows will now silently check it for Start-Orion-Portable.bat and run it automatically if found." -ForegroundColor Yellow
}
Catch {
    Write-Host "Failed to register Scheduled Task. Error: $_" -ForegroundColor Red
}

Pause
