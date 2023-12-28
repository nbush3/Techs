$moduleroot = $PSScriptRoot

Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-DellUpdate       
{
    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function."

    # Older 64-bit version of Dell Command Update
    # $dcu_regkey = "{5EBBC1DA-975F-44A0-B438-F325BCD45577}"

    # Newer 32-bit version of Dell Command Update (Jul 2018)
    # $dcu_regkey = "{289899DB-189C-4B8E-A160-C6D146B5C74A}"

    # Newer 32-bit version of Dell Command Update (Oct 2023)
    # $dcu_regkey = "{612F7720-D28A-473F-8FB9-C8D300B5F534}"
    $dcu_regkey = "0277F216A82DF374F89B8C3D005B5F43"

    $dcu_regpath = "HKLM:\SOFTWARE\Classes\Installer\Products\$dcu_regkey"

    Write-Log -String "     Registry key for DCU (hardcoded): $dcu_regkey"
    
    $dcu_test = Test-Path $dcu_regpath -PathType Container

    if  ($dcu_test)     {Write-Log -String "     Registry key was found on system. DCU is presumably installed."}
    else                {Write-Log -String "     Registry key not found on system. DCU is presumably not installed."}

    

    if ($dcu_test)    
    {
        $dellupdate_checkorx = Get-CheckOrX -Var $True
        Write-Log -String "     "
    }
    else            {$dellupdate_checkorx = Get-CheckOrX -Var $False}

    $dellupdate_string = $dellupdate_checkorx + ' ' + $dcu_test

    $return_dellupdate = @{
        "dcu_string"        =       $dellupdate_string
        "dcu_test"          =       $dcu_test
        "dcu_regkey"        =       $dcu_regkey
        "dcu_regpath"       =       $dcu_regpath
    }

    Write-Log -String "End function $current_function."

    return $return_dellupdate

}