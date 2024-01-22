# Install Master script
# Tasks:
# 1. Copy installer scripts to C:\Windows\Temp
# 2. Call Installer Phase A

$roboguide_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\RoboGuide 9 Rev ZH"
$roboguide_local = "C:\Windows\Temp\RoboGuide-9-Rev-ZH"
$certcart_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\LR Mate 200iD-4S Fenceless CERT Cart V9_40.zip"
$certcart_local = "C:\Users\Public\Desktop\My Workcells\"
$certcart_filename = "LR Mate 200iD-4S Fenceless CERT Cart V9_40.frw"
$regkey = "HKLM:\system\CurrentControlSet\control\Session Manager"
$regvalue = "PendingFileRenameOperations"

$install_remote = "S:\Techs\script\roboguide9\"

# Create local dirs
New-Item -Path $roboguide_local -ItemType Directory -Force
New-Item -Path $certcart_local -ItemType Directory -Force

# Copy installer scripts
# Must be local, otherwise PowerShell won't be able to find the scripts upon login
Write-Host "Copying installer scripts to $roboguide_local..." -NoNewline
Copy-Item "$install_remote\*" "$roboguide_local" -Force -ErrorAction SilentlyContinue
Write-Host "Done!"

# 2. Call A; begin install process
Start-Process powershell.exe -ArgumentList "-windowstyle normal -nologo -noprofile -noexit -command `"$roboguide_local\RoboGuide9-Install-A.ps1`" -Verb RunAs"