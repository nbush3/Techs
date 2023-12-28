function Get-SN         
{
    # WMI check for serial number

    $sn = (Get-WmiObject -Class Win32_SystemEnclosure).SerialNumber
    $sn_string = '  ' + $sn

    $sn_return = @{
        "sn" = $sn
        "sn_string" = $sn_string
    }

    return $sn_return
}