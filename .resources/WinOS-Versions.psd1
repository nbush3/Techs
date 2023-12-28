# Build num info available at https://learn.microsoft.com/en-us/windows/release-health/release-information
# 
# Should be called like so:
# $winosver = Import-PowerShellDataFile -Path "$resource_root\WinOS-Versions.psd1"
# $winosver.GetEnumerator() | foreach-object{
#    if ($initial_entry.DeviceOSBuild -like "10.0."+$_.Key+"*")      {$DeviceOSVersion = $_.Value}
# }

@{
    "10240" = "Windows 10 1507"
    "10586" = "Windows 10 1511"
    "14393" = "Windows 10 1607"
    "15063" = "Windows 10 1703"
    "16299" = "Windows 10 1709"
    "17134" = "Windows 10 1803"
    "17763" = "Windows 10 1809"
    "18362" = "Windows 10 1903 (19H1)"
    "18363" = "Windows 10 1909 (19H2)"
    "19041" = "Windows 10 2004 (20H1)"
    "19042" = "Windows 10 20H2"
    "19043" = "Windows 10 21H1"
    "19044" = "Windows 10 21H2"
    "19045" = "Windows 10 22H2"
    
    "22000" = "Windows 11 21H2"
    "22621" = "Windows 11 22H2"
    "22631" = "Windows 11 23H2"
}