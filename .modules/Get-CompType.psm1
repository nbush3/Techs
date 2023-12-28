$moduleroot = $PSScriptRoot
Import-Module -name "$moduleroot\Write-Log.psm1"

function Get-CompType 
{
    param(
        $model
    )

    # WMI check for model, to determine whether current machine is a laptop or a desktop (for the purposes of BIOS updates, to determine if a charger check via Check-Power is necessary)

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function."

    # $model = (Get-WmiObject Win32_ComputerSystem).Model
    $desktop_makes = @("OptiPlex", "Precision") | ForEach-Object {
        if  (($model.split(' '))[0] -eq $_){
            $return_var = "Desktop"
        }
    }

    $laptop_makes = @("Latitude") | ForEach-Object {
        if  (($model.split(' '))[0] -eq $_)     {
            $return_var = "Laptop"
        }
    }

    Write-Log -String "     Computer type: $return_var"
    Write-Log -String "End function $current_function."

    return $return_var

}