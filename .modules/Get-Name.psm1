function Get-Name
{
    # WMi check for current hostname

    $name = (Get-WmiObject Win32_ComputerSystem).Name
    $name_string = '  ' + $name

    $return_name = @{
        "name" = $name
        "name_string" = $name_string
    }

    return $return_name
}