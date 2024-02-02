# Install Phase B
# Tasks:
# 1. Remove scheduled task for Phase B
# 2. Set up scheduled task for Phase C
# 2. Run installer for RoboGuide9
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


# Run installer
Write-Host "Launching '$roboguide_local\setup.exe'... " -NoNewline
Start-Process -FilePath "$roboguide_local\setup.exe" -Verb RunAs -Wait
Write-Host "Done!"

# Restart
write-host "Restarting in 10s..."
Start-Sleep -s 10
Restart-Computer -Force