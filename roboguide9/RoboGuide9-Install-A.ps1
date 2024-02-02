# Install Phase A 
# Tasks:
# 1. Set up scheduled task for Phase B
# 2. Copy Roboguide9 installer files to C:\Windows\Temp
# 3. Copy CERT cart files to C:\Users\Public\Desktop
# 4. Copy installer scripts to C:\Windows\Temp
# 5. Restart

$roboguide_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\RoboGuide 9 Rev ZH"
$roboguide_local = "C:\Windows\Temp\RoboGuide-9-Rev-ZH\"
$certcart_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\LR Mate 200iD-4S Fenceless CERT Cart V9_40.zip"
$certcart_local = "C:\FANUC\"
$certcart_filename = "LR Mate 200iD-4S Fenceless CERT Cart V9_40.frw"
$regkey = "HKLM:\system\CurrentControlSet\control\Session Manager"
$regvalue = "PendingFileRenameOperations"



# Create Scheduled Task for B
# Must be a one liner or else it will launch immediately upon definition
Register-ScheduledTask -Action $(New-ScheduledTaskAction -Execute powershell.exe -Argument "-windowstyle normal -nologo -noprofile -noexit -command `"$roboguide_local\RoboGuide9-Install-B.ps1`" -Verb RunAs") -Trigger $(New-ScheduledTaskTrigger -AtLogOn) -RunLevel Highest -TaskName "RoboGuide Install B"

# Copy RoboGuide installer to local
Write-Host "`nCopying RoboGuide 9 to '$roboguide_local'... " -NoNewline
Copy-Item -Path "$roboguide_remote\*" -Destination $roboguide_local -Recurse -Force
Write-Host "Done!"

# Copy CERT cart files to local
Write-Host "Copying CERT Cart files to $certcart_local..." -NoNewline
Copy-Item $certcart_remote $certcart_local
Expand-Archive "$certcart_local/LR Mate 200iD-4S Fenceless CERT Cart V9_40.zip" -DestinationPath $certcart_local -Force
Remove-Item "$certcart_local/LR Mate 200iD-4S Fenceless CERT Cart V9_40.zip"
Write-Host "Done!"

# Restart
write-host "Restarting in 10s..."
Start-Sleep -s 10
Restart-Computer -Force