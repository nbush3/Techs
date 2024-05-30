# Initial variable setting
$script_root = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
$module_root = "$script_root\.modules"
$clearance_group = "Technicians"

# Module import
Import-Module "$module_root\Get-ADUserInfo.psm1"
Import-Module "$moduleroot\Get-CheckOrX.psm1"
Import-Module "$module_root\Group-Check.psm1"
Import-Module "$module_root\Test-DomainLogin.psm1"

# Current user clearance check
if (!(Group-Check -check_group $clearance_group))
{
    # Fail out of script
    $flag_global = $False
    Write-Warning "Invalid group membership. Aborting."
}
else 
{
    # Print splash screen
    $splashscreen
}

# Test AD login
$return = Test-DomainLogin
$checkorx = Get-CheckOrX -Var $return

write-host "$checkorx $return"