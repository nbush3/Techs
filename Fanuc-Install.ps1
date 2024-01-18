
$path_remote = "S:\Techs\FANUC - ROBOGUIDE\Installers\RoboGuide 9 Rev ZH"
$path_local = "C:\Windows\Temp\RoboGuide 9 Rev ZH"
$regkey = "HKLM:\system\CurrentControlSet\control\Session Manager"
$regvalue = "PendingFileRenameOperations"

Write-Host "`nCopying to '$path_local'... " -NoNewline
Copy-Item -Path $path_remote -Destination $path_local -Recurse -Force
Write-Host "Done!"

Write-Host "Resolving regkey... " -NoNewline
try {Remove-ItemProperty -Path "HKLM:\system\CurrentControlSet\control\Session Manager" -name "PendingFileRenameOperations"; write-host "Regkey deleted! Continuing."}
catch {Write-Host "Regkey returned null. Continuing."}


Write-Host "Launching '$path_local\setup.exe'... " -NoNewline
Start-Process -FilePath "$path_local\setup.exe" -Verb RunAs -Wait
Write-Host "Done!"