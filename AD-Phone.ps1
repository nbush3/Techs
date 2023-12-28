
# Initial variable setting
$script_root = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
$module_root = "$script_root\.modules"
$flag_global = $True
$flag_invalid = $False
$workdir = Get-Location
$counter = 1
$clearance_group = "Technicians"

# Module import
Import-Module "$module_root\Clear-PhoneInfo.psm1"
Import-Module "$module_root\Get-ADUserInfo.psm1"
Import-Module "$module_root\Group-Check.psm1"
Import-Module "$module_root\Set-PhoneInfo.psm1"



$menu_main = @(
    "1. Get AD Phone info"
    "2. Set AD phone info"
    "3. Wipe AD phone info"
    "4. Quit"
)


$splashscreen = "
============================================================================================
             _____             _____    _                                                __ 
     /\     |  __ \           |  __ \  | |                                              /_ |
    /  \    | |  | |  ______  | |__) | | |__     ___    _ __     ___       _ __    ___   | |
   / /\ \   | |  | | |______| |  ___/  | '_ \   / _ \  | '_ \   / _ \     | '_ \  / __|  | |
  / ____ \  | |__| |          | |      | | | | | (_) | | | | | |  __/  _  | |_) | \__ \  | |
 /_/    \_\ |_____/           |_|      |_| |_|  \___/  |_| |_|  \___| (_) | .__/  |___/  |_|
                                                                          | |               
                                                                          |_|               
                RCS Tech script for modifying user phone fields within AD
                            Only for use by RCS Technicians
============================================================================================
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
}


# Real program begin
while ($flag_global)
{
    # Print main menu
    $menu_main

    # Normal read host prompt (if previous input was not invalid)
    if      ($flag_invalid -eq $False)       {$MenuInput = Read-Host "`nEnter option"}
    else    {$flag_invalid = $False}

    write-host("`n")

    # Any option other than "4. Quit"
    if ($MenuInput -ne "4"){

        $flag_option = $True
        

        # 1. Get phone info
        if ($MenuInput -eq "1"){
            
            while ($flag_option){
                
                $User = Read-Host -Prompt "Enter User name(s) (type 'q' to quit)"

                if  ($User.ToLower() -eq 'q')   {$flag_option = $False}
                else {
                    $Users = $User.Split(' ')
                    ForEach ($CurrentUser in $Users) {

                        $realcounter = $counter.ToString('000')
                        write-host "`n[$realcounter] ==================================================================`n"

                        try                 {$adcheck = Get-ADUser -Identity $CurrentUser}
                        catch               {$adcheck = $null}
                        
                        if  ($adcheck)      {Get-ADUserInfo -User $CurrentUser -ListGroups $False}
                        else                {Write-Host "User '$CurrentUser' not found in system."}

                        $counter++
                    }
                }
            }
        }



        # 2. Set phone info
        elseif ($MenuInput -eq "2"){
            
            $User = Read-Host -Prompt "Enter User name(s) (type 'q' to quit)"

            if      ($User.ToLower() -eq 'q')       {$flag_option = $False}
            else
            {
                $Users = $User.Split(' ')
                ForEach ($CurrentUser in $Users) {

                    $realcounter = $counter.ToString('000')
                    write-host "`n[$realcounter] ==================================================================`n"

                    try         {$adcheck = Get-ADUser -Identity $CurrentUser}
                    catch       {$adcheck = $null}
                    
                    if  ($adcheck)
                    {
                        $userloop = $True
                        Get-ADUserInfo -User $CurrentUser -ListGroups $False

                        while ($userloop)
                        {
                            $queryloop = $False

                            Write-Host "Leave value blank to prevent overwriting. Type '.' to wipe the field."
                                                    
                            $set4digit = Read-Host -Prompt "Enter extension"
                            if      ($set4digit.trim() -eq '')          {$set10digit = ''; $display10digit = "<unchanged>"; $display4digit = "<unchanged>"}
                            elseif  ($set4digit.trim() -eq '.')         {$set10digit = '.'; $display10digit = "<deleted>"; $display4digit = "<deleted>"}
                            else                                        {$set10digit = "248-726-$set4digit"; ; $display10digit = $set10digit; $display4digit = $set4digit}
                            
                            $setrole = Read-Host -Prompt "Enter phone role"
                            if      ($setrole.trim() -eq "")            {$displayrole = "<unchanged>"}
                            elseif  ($setrole.trim() -eq ".")           {$displayrole = "<deleted>"}
                            else                                        {$displayrole = $setrole}

                            $setmobile = Read-Host -Prompt "Enter mobile phone (if applicable)"
                            if      ($setmobile.trim() -eq "")          {$displaymobile = "<unchanged>"}
                            elseif  ($setmobile.trim() -eq ".")         {$displaymobile = "<deleted>"}
                            else                                        {$displaymobile = $setmobile}

                            $setlocation = Read-Host -Prompt "Enter location/building"
                            if      ($setlocation.trim() -eq "")        {$displaylocation = "<unchanged>"}
                            elseif  ($setlocation.trim() -eq ".")       {$displaylocation = "<deleted>"}
                            else                                        {$displaylocation = $setlocation}

                            $setjob = Read-Host -Prompt "Enter job role/position"
                            if      ($setjob.trim() -eq "")             {$displayjob = "<unchanged>"}
                            elseif  ($setjob.trim() -eq ".")            {$displayjob = "<deleted>"}
                            else                                        {$displayjob = $setjob}

                            $displayparams = [Ordered]@{
                                "Extension"     =       $display4digit
                                "DID Number"    =       $display10digit
                                "Mobile Phone"  =       $displaymobile
                                "MiCollab Role" =       $displayrole
                                "Location"      =       $displaylocation
                                "Job Role"      =       $displayjob
                            }

                            if (!$queryloop){      

                                $displayparams | Format-Table -HideTableHeaders
                                $setquery = Read-Host -Prompt "Are you sure you want to set these values for user $CurrentUser`? (y/n/q)"

                                if ($setquery -eq "y")
                                {
                                    $userparams = @{ 
                                        identity            =       "$CurrentUser"
                                        TelephoneNumber     =       "$set4digit"
                                        ipPhone             =       "$set10digit";                                
                                        wWWHomePage         =       "$setrole"
                                        mobile              =       "$setmobile"
                                        Pager               =       "$setlocation"
                                        postOfficeBox       =       "$setjob"
                                        
                                    }

                                    Set-PhoneInfo -ParamBlock $userparams
                                    $userloop = $False
                                }
                                
                                elseif  ($setquery -eq "n") 
                                {
                                    $queryloop = $True
                                    Write-Host "`nStarting over for user $CurrentUser."
                                }
                                elseif  ($setquery -eq "q")
                                {
                                    $userloop = $False
                                    Write-Host "Exiting process for user $CurrentUser."
                                }

                                else {$setquery = (Read-Host -Prompt "Invalid input, try again").ToLower()}
                            }
                        }
                    }
                    else {Write-Host "User '$CurrentUser' not found in system."}
                }

            $counter++

            }
        }

        # 3. Wipe phone info
        elseif ($MenuInput -eq "3"){

            $User = Read-Host -Prompt "Enter User name(s) (type 'q' to quit)"

            if  ($User.ToLower() -eq 'q')    {$flag_option = $False}
            else 
            {
                $adcheck = $null
                $queryloop = $False
                $Users = $User.Split(' ')
                ForEach ($CurrentUser in $Users) 
                {

                    $realcounter = $counter.ToString('000')
                    write-host "`n[$realcounter] ==================================================================`n"

                    $queryloop = $False

                    try         {$adcheck = Get-ADUser -Identity $CurrentUser}
                    catch       {$adcheck = $null}

                    if ($adcheck)
                    {
                        Get-ADUserInfo -User $CurrentUser -ListGroups $False

                        if (!$queryloop)
                        {
                            $wipeprompt = (Read-Host -Prompt "Are you sure you want to wipe this user's phone fields? (Ext, DID, MiCollab Role, Mobile, Building, Job Role) (y/n)").ToLower()
                            if ($wipeprompt -eq "y")
                            {
                                Clear-PhoneInfo -User $CurrentUser
                                $queryloop = $True
                            }
                            
                            elseif  ($wipeprompt -eq "n") {$queryloop = $True}
                            else    {$wipeprompt = (Read-Host -Prompt "Invalid input, try again").ToLower()}
                        }
                    }
                    else {Write-Host "User '$CurrentUser' not found in system."}
                }
            }    
        }

        $counter++

    }
    

    # 4. Quit
    elseif ($MenuInput -eq "4")
    {
        $flag_global = $False
        Set-Location $workdir
    }


    # Menu input - invalid
    else
    {
        $flag_invalid = $True
        $MenuInput = Read-Host "Invalid input, try again"
    }
}