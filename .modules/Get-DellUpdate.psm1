$moduleroot = $PSScriptRoot

Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-DellUpdate       
{

    param($logflag)

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    # DCU v5.2.0 (Jan 2024)
    $dcu_regkey = "{E40C2C69-CA25-454A-AB4D-C675988EC101}"
    $dcu_regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$dcu_regkey"

    Write-Log -String "     Registry key for DCU (hardcoded): $dcu_regkey" -logflag $logflag
    Write-Log -String "     Looking for regkey at $dcu_regpath" -logflag $logflag
    
    $dcu_test = Test-Path $dcu_regpath -PathType Container

    if  ($dcu_test)     {Write-Log -String "     Regkey found on system. Assuming DCU is installed." -logflag $logflag}
    else                {Write-Log -String "     Regkey not found on system. Assuming DCU is not installed." -logflag $logflag}

    

    if ($dcu_test)  {$dellupdate_checkorx = Get-CheckOrX -Var $True}
    else            {$dellupdate_checkorx = Get-CheckOrX -Var $False}

    $dellupdate_string = $dellupdate_checkorx + ' ' + $dcu_test

    $return_dellupdate = @{
        "dcu_string"        =       $dellupdate_string
        "dcu_test"          =       $dcu_test
        "dcu_regkey"        =       $dcu_regkey
        "dcu_regpath"       =       $dcu_regpath
    }

    Write-Log -String "End function $current_function." -logflag $logflag

    return $return_dellupdate

}