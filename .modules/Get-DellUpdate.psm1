$moduleroot = $PSScriptRoot
$dcuroot = "S:\Techs\script\wup\dcu\"

Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-DellUpdate       
{
    param($logflag)

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    # Find local version of DCU
    $dcu_flag = $False
    $keydirs = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
    )

    foreach ($keydir in $keydirs) 
    {

        $keylist = (Get-ChildItem $keydir).name | ForEach-Object {($_ -split "\\")[($_ -split "\\").Length - 1]}

        foreach ($key in $keylist)
        {
            
            $keypath = "$keydir\$key"
            $keyprop = Get-ItemProperty $keypath
            
            if ($keyprop.DisplayName -like "*dell*update*")
            {
                $dcu_flag = $True
                $dcu_regkey = $key
                $dcu_regpath = $keypath
                
                Write-Log -String "     Registry key found for DCU: $dcu_regkey" -logflag $logflag
                
                $dcu_local_version = (Get-ItemProperty $dcu_regpath).DisplayVersion
                
                Write-Log -String "     Registry key was found on system. Local version: $dcu_local_version." -logflag $logflag
            }
        }
    }

    if (!$dcu_flag)
    {
        Write-Log -String "     Registry key not found on system. DCU is presumably not installed. Setting local version to null." -logflag $logflag
        $dcu_local_version = $null
        $dcu_regpath = $null
        $dcu_regkey = $null
    }

    # Find remote version of DCU
    If (Test-Path "$dcuroot\*Dell*Command*Update*.msi")
    {
        $dcu_remote_filename = (get-childitem "$dcuroot\*Dell*Command*Update*.msi" | select-object -last 1).BaseName
        $dcu_remote_version = ($dcu_remote_filename -split "_")[1]

        Write-Log -string "     Dell MSI installer found, version $dell_remote_version" -logflag $logflag
    }
    else
    {
        $dcu_remote_version = $null
        Write-Log -string "     No remote DCU installer found. Setting remote version to null." -logflag $logflag
    }

    $dcu_test = $dcu_local_version -ge $dcu_remote_version

    if ($dcu_test)  {$dcu_checkorx = Get-CheckOrX -Var $True}
    else            {$dcu_checkorx = Get-CheckOrX -Var $False}

    $dcu_string = $dcu_checkorx + ' ' + $dcu_local_version
  

    $return_dcu = @{
        "dcu_string"                =           $dcu_string
        "dcu_flag"                  =           $dcu_test
        "dcu_regkey"                =           $dcu_regkey
        "dcu_regpath"               =           $dcu_regpath
        "dcu_local_version"         =           $dcu_local_version
        "dcu_remote_version"        =           $dcu_remote_version
    }

    Write-Log -String "End function $current_function." -logflag $logflag

    return $return_dcu
}