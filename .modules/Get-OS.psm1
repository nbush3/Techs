# Initial variable setting
$scriptroot = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
$moduleroot = "$scriptroot\.modules"
$resourceroot = "$scriptroot\.resources"

# Module import
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

# Resource import
$winosver = Import-PowerShellDataFile -Path "$resourceroot\WinOS-Versions.psd1"

function Get-OS
{
    
    param (
        $model
    )

    $buildnum = (Get-WmiObject -class Win32_OperatingSystem).BuildNumber
    $osver = ""
    $foundflag = $False

    $winosver.GetEnumerator() | foreach-object{
        if ($buildnum -eq $_.Key)      {
            $osver = $_.Value
            $foundflag = $True
        }
    }

    if($foundflag -eq $False)      {$osver = $null}

    # 3380s and 3070s only seem to be able to reach 21H1 (since rescinded, all computers should reach 22H2 now)
    # if ($model -eq "Latitude 3380" -or $model -eq "OptiPlex 3070")          {$maxver = "Win10 21H1"}
    # else                                                                    {$maxver = "Win10 22H2"}

    # if ($osver -lt $maxver)     {$osver_checkorx = Get-CheckOrX -Var $False}
    if ($osver -lt "Windows 10 22H2")           {$osver_checkorx = Get-CheckOrX -Var $False}
    else                                        {$osver_checkorx = Get-CheckOrX -Var $True}
    
    $osver_string = $osver_checkorx + ' ' + $osver

    $osver_return = @{
        "build_number" = $buildnum
        "osver" = $osver
        "osver_string" = $osver_string
    }

    return $osver_return
}