$moduleroot = $PSScriptRoot

Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-DellUpdate       
{

    param($logflag)

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    # DCU v5.2.0 (Jan 2024)
    # $dcu_regkey = "{E40C2C69-CA25-454A-AB4D-C675988EC101}"
    # $dcu_regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$dcu_regkey"

    # Find local version of Zoom

    $dcu_flag = $False
    $keydir = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $keylist = (Get-ChildItem $keydir).name | ForEach-Object {($_ -split "\\")[6]}

    foreach ($key in $keylist)
    {
        
        $keypath = "$keydir\$key"
        $keyprop = Get-ItemProperty $keypath
        
        if ($keyprop.DisplayName -like "*dell*command*")
        {
            $dcu_flag = $True
            $dcu_regkey = $key
            $dcu_regpath = $keypath
            
            Write-Log -String "     Registry key found for DCU: $dcu_regkey" -logflag $logflag
            $dcu_version = (Get-ItemProperty $dcu_regpath).DisplayVersion
            Write-Log -String "     Registry key was found on system. Local version: $dcu_version." -logflag $logflag
        }
    }

    if (!$dcu_flag)
    {
        Write-Log -String "     Registry key not found on system. Zoom is presumably not installed. Setting local version to null." -logflag $logflag
        $dcu_version = $null
        $dcu_regpath = $null
        $dcu_regkey = $null
    }

    if ($dcu_flag)  {$dellupdate_checkorx = Get-CheckOrX -Var $True}
    else            {$dellupdate_checkorx = Get-CheckOrX -Var $False}

    $dellupdate_string = $dellupdate_checkorx + ' ' + $dcu_flag

    $return_dellupdate = @{
        "dcu_string"        =       $dellupdate_string
        "dcu_flag"          =       $dcu_flag
        "dcu_regkey"        =       $dcu_regkey
        "dcu_regpath"       =       $dcu_regpath
    }

    Write-Log -String "End function $current_function." -logflag $logflag

    return $return_dellupdate

}