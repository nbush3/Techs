# Install Phase B
# Tasks:
# 1. Remove scheduled task for Phase B
# 2. Set up scheduled task for Phase C
# 2. Automate installer for RoboGuide9
# 3. Restart

$roboguide_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\RoboGuide 9 Rev ZH"
$roboguide_local = "C:\Windows\Temp\RoboGuide-9-Rev-ZH"
$certcart_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\LR Mate 200iD-4S Fenceless CERT Cart V9_40.zip"
$certcart_local = "C:\FANUC\"
$certcart_filename = "LR Mate 200iD-4S Fenceless CERT Cart V9_40.frw"
$regkey = "HKLM:\system\CurrentControlSet\control\Session Manager"
$regvalue = "PendingFileRenameOperations"




# Remove Scheduled Task for B
Write-Host "Clearing previous scheduled task..." -NoNewline
Unregister-ScheduledTask -TaskName "RoboGuide Install B" -Confirm:$false | Out-Null
Write-Host "Done!"

# Create Scheduled Task for C
# Must be a one liner or else it will launch immediately upon definition
Write-Host "Setting up next scheduled task..." -NoNewline
Register-ScheduledTask -Action $(New-ScheduledTaskAction -Execute powershell.exe -Argument "-windowstyle normal -nologo -noprofile -noexit -command `"$roboguide_local\RoboGuide9-Install-C.ps1`" -Verb RunAs") -Trigger $(New-ScheduledTaskTrigger -AtLogOn) -RunLevel Highest -TaskName "RoboGuide Install C"
Write-Host "Done!"


Start-Sleep -s 10

# Create shell object for keyboard emulation
# https://www.vbsedit.com/html/4b032417-ebda-4d30-88a4-2b56c24affdd.asp
$WShell = New-Object -com "Wscript.Shell"

# Create WinAP class for window manipulation
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WinAp {
      [DllImport("user32.dll")]
      [return: MarshalAs(UnmanagedType.Bool)]
      public static extern bool SetForegroundWindow(IntPtr hWnd);

      [DllImport("user32.dll")]
      [return: MarshalAs(UnmanagedType.Bool)]
      public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@

# Run installer
Write-Host "Launching '$roboguide_local\setup.exe'... " -NoNewline
# Start-Process -FilePath "$roboguide_local\setup.exe" -Verb RunAs -Wait
Start-Process -FilePath "$roboguide_local\setup.exe" -Verb RunAs

Start-Sleep -s 20

$roboguide_pf = "C:\Windows\Program Files (x86)\FANUC\"
If (Test-Path $roboguide_pf) {Remove-Item $roboguide_pf -Force -Recurse -ErrorAction SilentlyContinue}

# Bootstrapper
$bootstrap_process = (Get-Process | Where-Object {$_.mainWindowTitle -match "Roboguide Bootstrapper Setup"})

if ($bootstrap_process)
{
    $bootstrap_id = $bootstrap_process.Id
    $bootstrap_handle = $bootstrap_process.MainWindowHandle

    [void] [WinAp]::SetForegroundWindow($bootstrap_handle)
    [void] [winap]::ShowWindow($bootstrap_handle,1)
    $null = (New-Object -ComObject WScript.Shell).AppActivate($bootstrap_id)

    Start-Sleep -s 5

    $WShell.sendkeys("{LEFT}"); Start-Sleep -s 1; $WShell.sendkeys("{ENTER}")
}
else {Write-Warning "Bootstrapper setup not launched. Curious."}

Start-Sleep -s 10

$fanuc_process = (Get-Process | Where-Object {$_.mainWindowTitle -match "FANUC ROBOGUIDE"})

# Installer proper
if ($fanuc_process)
{
    $fanuc_id = $fanuc_process.Id
    $fanuc_handle = $fanuc_process.MainWindowHandle

    [void] [WinAp]::SetForegroundWindow($fanuc_handle)
    [void] [winap]::ShowWindow($fanuc_handle,1)
    $null = (New-Object -ComObject WScript.Shell).AppActivate($fanuc_id)

    # Welcome screen - Next >
    $WShell.sendkeys("{ENTER}")
    Start-Sleep -s 2

    # License agreement - YES
    $WShell.sendkeys("{ENTER}")
    Start-Sleep -s 2

    # Choose destination location - Next >
    $WShell.sendkeys("{ENTER}")
    Start-Sleep -s 2

    # Choose which Process Plug-ins to install
    # Check Handling Pro
    # Uncheck all others
    $WShell.sendkeys(" "); Start-Sleep -s 2
    $WShell.sendkeys("{DOWN 3} "); Start-Sleep -s 2

    $WShell.sendkeys("{ENTER}"); Start-Sleep -s 2

    # Check which Utility Plugins to install
    # Check 4D Editor, Auto Place, Duty Estimation, Life Estimation, Machine Tool, Power Estimation, TP Program Edit, Vision Setup, Weld Conditions
    # Uncheck all others
    $WShell.sendkeys(" "); Start-Sleep -s 2
    $WShell.sendkeys("4 "); Start-Sleep -s 2
    $WShell.sendkeys("A "); Start-Sleep -s 2
    $WShell.sendkeys("D "); Start-Sleep -s 2
    $WShell.sendkeys("L "); Start-Sleep -s 2
    $WShell.sendkeys("M "); Start-Sleep -s 2
    $WShell.sendkeys("P "); Start-Sleep -s 2
    $WShell.sendkeys("T "); Start-Sleep -s 2
    $WShell.sendkeys("V "); Start-Sleep -s 2
    $WShell.sendkeys("W "); Start-Sleep -s 2
    
    $WShell.sendkeys("{ENTER}"); Start-Sleep -s 4

    # Check which addiitonal application features you want to
    # Check HandlingPro
    # Uncheck ROBOGUIDE, uncheck Sample Workcells
    $WShell.sendkeys("D "); Start-Sleep -s 2
    $WShell.sendkeys("H "); Start-Sleep -s 2
    $WShell.sendkeys("S "); Start-Sleep -s 2

    $WShell.sendkeys("{ENTER}"); Start-Sleep -s 2

    # FANUC Robotics Virtual Robot Selection
    # Check 9.40, 9.30, 9.10, 8.30, 8.20
    $WShell.sendkeys("{DOWN} "); Start-Sleep -s 1
    $WShell.sendkeys("{DOWN} "); Start-Sleep -s 1
    $WShell.sendkeys("{DOWN} "); Start-Sleep -s 1
    $WShell.sendkeys("{DOWN} "); Start-Sleep -s 1
    $WShell.sendkeys("{TAB 4}"); Start-Sleep -s 1
    $WShell.sendkeys("{ENTER}"); Start-Sleep -s 1

    # Start copying files - Next >
    $WShell.sendkeys("{ENTER}")

    # Installer for all components will run - this is automated, takes about 10m in my testing
    start-sleep -Seconds 600

    # View readme? -NO
    $WShell.sendkeys(" {ENTER}"); Start-Sleep -s 1

    # Restart? - Yes
    $WShell.sendkeys("{ENTER}"); Start-Sleep -s 1
}

# Failover restart
if (!(Get-Process | Where-Object {$_.mainwindowtitle -match "FANUC"}))
{
    write-host "Restarting in 10s..."
    Start-Sleep -s 10
    Restart-Computer -Force
}