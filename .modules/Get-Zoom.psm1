$moduleroot = $PSScriptRoot

$temproot = $Env:tmp
$wuptemp = "$temproot\wup\"
$biosroot = "S:\Techs\script\wup\bios\"

Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-Zoom
{
    Param ( $logflag )

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    # List of different known regkeys for Zoom
    $zoom_regkey = @(
        "{3B21D66C-F004-4CC5-8DCD-0BC9F66515AC}"
        "{8339CEEA-7547-4C1C-8C18-5BC89E431FBB}"
        "{C6095BA2-96D7-478C-922F-01849BD21AFD}"
        "{130C5F26-7D81-4285-9F6C-C18D91503887}"
        "{334503B4-0A36-45A2-8206-A6B37A1F8B5B}"
        )

    $zoom_flag = $False

    # Find local version of Zoom
    foreach ($key in $zoom_regkey)
    {
        $zoom_regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$key"

        if (Test-Path $zoom_regpath -PathType Container)     
        {
            $key = $zoom_regkey_final
            Write-Log -String "     Registry key found for Zoom: $zoom_regkey_final" -logflag $logflag
            $zoom_flag = $True
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
    If (Test-Path "$biosroot\*Zoom*.msi")
    {
        $zoom_remote_query = "$biosroot"+"*Zoom*.msi"
        
        $zoom_remote_filename_ext = (get-childitem $zoom_remote_query).Name
        $zoom_installer_path1 = "$biosroot"+"$zoom_remote_filename_ext"
        $zoom_installer_path2 = "$wuptemp"+"$zoom_remote_filename_ext"
        
        $zoom_remote_filename = (get-childitem $zoom_remote_query).BaseName
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
        "zoom_regkey"               =       $zoom_regkey_final
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