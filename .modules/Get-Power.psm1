$moduleroot = $PSScriptRoot

# Import-Module "$moduleroot\Get-Model.psm1"
Import-Module "$moduleroot\Get-CompType.psm1"
Import-Module "$moduleroot\Get-CheckOrX.psm1"
Import-Module "$moduleroot\Write-Log.psm1"

function Get-Power
{
    
    param(
        $comptype
    )
    
    # Return charger status, battery charge and battery health

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function."


    # $comptype = Get-CompType

    # WMI check for battery charge
    try
    {
        $battery_check = (Get-WmiObject Win32_Battery).EstimatedChargeRemaining
        Write-Log -String "     Estimated battery charge remaining via WMI: $battery_check"
        
        if ($battery_check -gt "100") {
            $battery_check = "100"
            Write-Log -String "     Battery charge greater than 100%. Setting battery charge to 100%."
        }
    }

    catch
    {
        $battery_check = $null
        Write-Log -String "     Error reading battery charge. Battery is either bad or not installed. Setting battery charge to null."
    }

    if ($battery_check)
    {
        if ($battery_check -lt "10")
        {
            $charge_checkorx = Get-CheckOrX -Var $False
            $battery_check = $battery_check.ToString() + '%'

        }
        if ($battery_check -ge "10")
        {
            $charge_checkorx = Get-CheckOrX -Var $True
            Write-Log -String "     Battery charge greater than 10%. Get-CheckOrX value is 'check'."
            $battery_check = $battery_check.ToString() + '%'
        }
    }
    else
    {
        $charge_checkorx = Get-CheckOrX -Var $False
        $battery_check = "No battery detected"
        Write-Log -string "     No battery detected."
    }
    
    $charge_string = $charge_checkorx + ' ' + $battery_check
    
    
    # WMI check for battery's design capacity vs current capacity to determine current battery health (if the computer's a laptop)

    if ($comptype -eq "laptop")
    {
        Write-Log -String "     Computer type is laptop. Proceeding with battery health check."
        $battery_design = (Get-WmiObject -Namespace ROOT\WMI -query 'SELECT DesignedCapacity FROM BatteryStaticData').DesignedCapacity 
        Write-Log -String "     Battery design capacity: $battery_design"
        
        $battery_capacity = (Get-WmiObject -Namespace ROOT\WMI -query 'SELECT FullChargedCapacity FROM BatteryFullChargedCapacity').FullChargedCapacity 
        Write-Log -String "     Battery current capacity: $battery_capacity"

        if ($battery_capacity -gt 0 -and $battery_design -gt 0)
        {
            $battery_health = ($battery_capacity / $battery_design).ToString("P")
        }
        else {$battery_health = 0}

        Write-Log -String "     Battery health (capacity / design): $battery_health"

        if ($battery_health)
        {
            if ($battery_health -gt $battery_health_good)
            {
                $battery_checkorx = Get-CheckOrX -Var $True
                Write-Log -String "     Battery health greater than $battery_health_good. Get-CheckOrX value is 'check'."
            }
            else
            {
                $battery_checkorx = Get-CheckOrX -Var $False
                Write-Log -String "     Battery health less than $battery_health_good. Get-CheckOrX value is 'x'."
            }
        }
        else
        {
            $battery_health = $null
            $battery_checkorx = Get-CheckOrX -Var $False
            Write-Log -String "     Battery not found."
        } 

    }
    else
    {
        $battery_health = $null
        Write-Log -String "     Computer type is not laptop. Setting battery health to null."
    }

 
    # WMI check for a currently-connected charger (for the purposes of BIOS updates - BIOS updates cannot occur on a Dell laptop without a charger)
    if ($comptype -eq "Laptop")
    {
        Write-Log -String "     Computer type is laptop. Checking charger status."  
        $charger_status = (Get-WmiObject -Class BatteryStatus -Namespace root\wmi).PowerOnline
        Write-Log -String "     Charger status: $charger_status"

        if (!$charger_status -and !$battery_status)
        {
            Write-Log -String "     Both charger status and battery status are false. Forcing charger status to True."
            $charger_status = $True
        }

        if ($charger_status)
        {
            $charger_checkorx = Get-CheckOrX -Var $True
            Write-Log -String "     Charger exists. Get-CheckOrX value is 'check'."
        }
        else
        {
            $charger_checkorx = Get-CheckOrX -Var $False
            Write-Log -String " Charger does not exist. Get-CheckOrX value is 'x'."
        } 

        


        # Finally, set and return var array
        $power_return = @{
            "battery_charge"        =       $battery_check
            "charge_string"         =       $charge_string
            "battery_health"        =       $battery_health
            "health_string"         =       $battery_checkorx + ' ' + $battery_health
            "charger_status"        =       $charger_status
            "charger_string"        =       $charger_checkorx + ' ' + $charger_status
        }
    }
    else
    {
        Write-Log -String " Computer type is not laptop. Not checking charger/battery status."

        $power_return = $null
    }


    Write-Log -String "End function $current_function."

    return $power_return
}