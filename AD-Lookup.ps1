# Initial variable setting
$script_root = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
$module_root = "$script_root\.modules"
$flag_global = $True
$clearance_group = "Technicians"

# Module import
Import-Module "$module_root\Get-ADUserInfo.psm1"
Import-Module "$module_root\Group-Check.psm1"


$splashscreen = "
====================================================================================================


             _____             _                        _                                        __ 
     /\     |  __ \           | |                      | |                                      /_ |
    /  \    | |  | |  ______  | |        ___     ___   | | __  _   _   _ __        _ __    ___   | |
   / /\ \   | |  | | |______| | |       / _ \   / _ \  | |/ / | | | | | '_ \      | '_ \  / __|  | |
  / ____ \  | |__| |          | |____  | (_) | | (_) | |   <  | |_| | | |_) |  _  | |_) | \__ \  | |
 /_/    \_\ |_____/           |______|  \___/   \___/  |_|\_\  \__,_| | .__/  (_) | .__/  |___/  |_|
                                                                      | |         | |               
                                                                      |_|         |_|               
                        RCS Tech script for looking up user attributes in AD
                                  Only for use by RCS Technicians
====================================================================================================
"

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

    Write-Host "This script will loop forever. Ctrl+C to exit."
}

# Look up users in an endless loop. No exit state, Ctrl+C to exit.
while($flag_global)
{
    $User = Read-Host -Prompt "`nEnter User name"

    $Users = $User.Split(' ')
    ForEach ($CurrentUser in $Users) {
        try         {$adcheck = Get-ADUser -Identity $CurrentUser}
        catch       {$adcheck = $null}
        
        if  ($adcheck)      {Get-ADUserInfo -User $CurrentUser -ListGroups -ListDevices}
        else                {Write-Host "User '$CurrentUser' not found in system."}
    }

}