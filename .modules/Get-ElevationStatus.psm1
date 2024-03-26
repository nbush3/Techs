$moduleroot = $PSScriptRoot

Import-Module -name "$moduleroot\Write-Log.psm1"

function Get-ElevationStatus
{
    # Check if currently running in an elevated prompt (certain functions can only work with admin rights)

    Param ( $logflag )

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    $elevation_check = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Log -String "     Elevation check: $elevation_check." -logflag $logflag

    Write-Log -String "End function $current_function." -logflag $logflag

    return ($elevation_check)
}