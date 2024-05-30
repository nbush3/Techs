$moduleroot = $PSScriptRoot

$temproot = $Env:tmp
$wuptemp = "$temproot\wup\"
$zoomroot = "S:\Techs\script\wup\zoom\"

Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-Zoom
{
    Param ( $logflag )

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag


    # Find local version of Zoom

    $zoom_flag = $False
    $keydir = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $keylist = (Get-ChildItem $keydir).name | ForEach-Object {($_ -split "\\")[6]}

    foreach ($key in $keylist)
    {
        
        $keypath = "$keydir\$key"
        $keyprop = Get-ItemProperty $keypath
        
        if ($keyprop.DisplayName -like "*zoom*")
        {
            $zoom_flag = $True
            $zoom_regkey = $key
            $zoom_regpath = $keypath
            
            Write-Log -String "     Registry key found for Zoom: $zoom_regkey" -logflag $logflag
            $zoom_local_version = (Get-ItemProperty $zoom_regpath).DisplayVersion
            Write-Log -String "     Registry key was found on system. Local version: $zoom_local_version." -logflag $logflag
        }
    }
    
    if (!$zoom_flag)
    {
        Write-Log -String "     Registry key not found on system. Zoom is presumably not installed. Setting local version to null." -logflag $logflag
        $zoom_local_version = $null
    }



    
    # Find remote version of Zoom
    If (Test-Path "$zoomroot\*Zoom*.msi")
    {
        $zoom_remote_query = "$zoomroot"+"*Zoom*.msi"
        
        $zoom_remote_filename_ext = (get-childitem $zoom_remote_query | select-object -last 1).Name
        $zoom_installer_path1 = "$zoomroot"+"$zoom_remote_filename_ext"
        $zoom_installer_path2 = "$wuptemp"+"$zoom_remote_filename_ext"
        
        $zoom_remote_filename = (get-childitem $zoom_remote_query | select-object -last 1).BaseName
        $zoom_remote_version = ($zoom_remote_filename -split "-")[1]
        
        Write-Log -string "     Zoom MSI installer found, version $zoom_remote_version" -logflag $logflag
    }
    else
    {
        $zoom_remote_version = $null
        Write-Log -string "     No remote Zoom installer found. Setting remote version to null." -logflag $logflag
    }

    $zoom_test = $zoom_local_version -ge $zoom_remote_version

    if ($zoom_test)    
    {
        $zoom_checkorx = Get-CheckOrX -Var $True
        Write-Log -String " "
    }
    else            {$zoom_checkorx = Get-CheckOrX -Var $False}

    $zoom_string = $zoom_checkorx + ' ' + $zoom_local_version

    $return_zoom = @{
        "zoom_string"               =       $zoom_string
        "zoom_test"                 =       $zoom_test
        "zoom_flag"                 =       $zoom_flag
        "zoom_regkey"               =       $zoom_regkey
        "zoom_regpath"              =       $zoom_regpath
        "zoom_local_version"        =       $zoom_local_version
        "zoom_remote_version"       =       $zoom_remote_version
        "zoom_installer_path1"      =       $zoom_installer_path1
        "zoom_installer_path2"      =       $zoom_installer_path2
    }

    # Write-Log -hashtable $return_zoom
    Write-Log -String "End function $current_function." -logflag $logflag

    return $return_zoom
}