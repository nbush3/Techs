# Install Phase C
# Tasks:
# 1. Remove scheduled task for Phase C
# 2. Open CERT cart file in RoboGuide
# 3. Clean up files in C:\Windows\Temp

$roboguide_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\RoboGuide 9 Rev ZH"
$roboguide_local = "C:\Windows\Temp\RoboGuide-9-Rev-ZH"
$certcart_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\LR Mate 200iD-4S Fenceless CERT Cart V9_40.zip"
$certcart_local = "C:\Users\Public\Desktop\My Workcells\"
$certcart_filename = "LR Mate 200iD-4S Fenceless CERT Cart V9_40.frw"
$regkey = "HKLM:\system\CurrentControlSet\control\Session Manager"
$regvalue = "PendingFileRenameOperations"



# Remove Scheduled Task for B
Write-Host "Clearing previous scheduled task..." -NoNewline
Unregister-ScheduledTask -TaskName "RoboGuide Install C" -Confirm:$false
Write-Host "Done!"

# Open CERT cart file
# Write-Host "Opening CERT Cart file..." -NoNewline
# Invoke-Item "$certcart_local\LR Mate 200iD-4S Fenceless CERT Cart V9_40\$certcart_filename" 
# Write-Host "Done!"

# Clean up temp files
Write-Host "Cleaning up temp files..." -NoNewline
Remove-Item $roboguide_local -Recurse -Force

# Open webpage
Start-Process "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList "https://myportal.fanucamerica.com --guest"