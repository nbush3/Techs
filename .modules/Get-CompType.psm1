$moduleroot = $PSScriptRoot
Import-Module -name "$moduleroot\Write-Log.psm1"

function Get-CompType 
{
    param(
        $model,
        $logflag
    )

    # WMI check for model, to determine whether current machine is a laptop or a desktop (for the purposes of BIOS updates, to determine if a charger check via Check-Power is necessary)

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    $comp_makes = @{
        "OptiPlex"      =       "Desktop"
        "Precision"     =       "Desktop"
        "Latitude"      =       "Laptop"
    }

    # Extract computer make from model string (usually the first word in the string)
    $comp_make = ($model.split(' '))[0]

    $comp_makes.GetEnumerator() | ForEach-Object {
        if  ($comp_make -eq $_.key)     {$return_var = $_.value}
    }

    Write-Log -String "     Computer type: $return_var" -logflag $logflag
    Write-Log -String "End function $current_function." -logflag $logflag

    return $return_var

}