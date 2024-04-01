# Initial variable setting
$script_root = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
$module_root = "$script_root\.modules"
$resource_root = "$script_root\.resources"
$clearance_group = "Technicians"

# Module import
Import-Module "$module_root\Group-Check.psm1"

# Resource import
$winosver = Import-PowerShellDataFile -Path "$resource_root\WinOS-Versions.psd1"


# Hashtable holding quantities (upper limits) of sets of machines (labs, carts, loaners). For looking up dropped machines in SCCM using wildcards.
$comp_set_quants = @{
    # ACE
    "10-RCARTA-SL" = 38
    "10-RCARTB-SL" = 38
    "10-RCARTC-SL" = 40
    
    # North Hill
    "16-CARTA-SL" = 17
    "16-CARTB-SL" = 21
    "16-CARTC-SL" = 15
    "16-CARTD-SL" = 15
    "16-MC-SL" = 40

    # Brewster
    "20-MC-SL" = 39
    
    # Delta Kelly
    "24-MC-SL" = 40

    # West
    "41-L402-SL" = 40

    # Van Hoosen
    "42-LABC-SL" = 40
    "42-MC-SL" = 39

    # Reuther
    "43-L130-SL" = 39
    
    # Hart
    "44-B2-SL" = 40
    "44-CARTA-SL" = 40

    # RHS
    "50-CTE4-SL" = 15
    "50-CTE5-SL" = 40
    "50-D118L-SL" = 35
    "50-ICBLUE-SL" = 40
    "50-ICWHITE-SL" = 40
    "50-LANGL-SL" = 40
    "50-PHYSICS-SL" = 20
    "50-PHYS-SL" = 20

    # AHS
    "51-CART1-SL" = 40
    "51-CART2-SL" = 40
    "51-CART3-SL" = 40
    "51-CART4-SL" = 40
    "51-CTE1-SL" = 40
    "51-PHYSICS-SL" = 24

    # SCHS
    "52-C269-SL" = 40
    "52-CART1-SL" = 40
    "52-CARTA-SL" = 40
    "52-CTE2-SL" = 35
    "52-CTE3-SL" = 20
    




}





# ===============================================================================================

function Connect-SCCM
{
    Import-Module ConfigurationManager
    Set-Location RCS:
}




function Get-BIOS-SCCM
{
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $CompName
    )

    
    $initial_entry = Get-CMDevice -Name $Compname | Select-Object Name, SerialNumber, ResourceID

    $resourceid = $initial_entry.ResourceID

    $biosver = (Get-WmiObject -namespace root/SMS/site_RCS -computer "rcs-sc-01" -query "select SMBIOSBIOSVersion from SMS_G_System_PC_BIOS where SMS_G_System_PC_BIOS.ResourceID=$resourceid").SMBIOSBIOSVersion

    # Query SCCM database for computer model number
    $compmodel = (Get-WmiObject -namespace root/SMS/site_RCS -computer "rcs-sc-01" -query "select Model from SMS_G_System_COMPUTER_SYSTEM where SMS_G_System_COMPUTER_SYSTEM.Name = '$CompName'").Model

    $list_entry = $initial_entry | Select-Object Name, @{Name = "Model Number"; Expression = {$compmodel}}, SerialNumber, @{Name= "Bios Ver."; Expression = {$biosver}}

    # $bios_links.getenumerator() | foreach-object{
        # if ($compmodel -eq $_.Key)  {(Invoke-RestMethod $_.Value).Links}
    # }




    return $list_entry
    
    

    

}




# ===============================================================================================

function Get-SCCM-HWOS
{
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $CompName
    )
    
    
    # Initial SCCM variable retreival
    $initial_entry = Get-CMDevice -Name $CompName | select-object Name, SerialNumber, MACAddress, DeviceOsBuild, ResourceID

    $resource_id = $initial_entry.ResourceID
    
    # Determine Win10 version number based on build number in SCCM    
    $winosver.GetEnumerator() | foreach-object{
        if ($initial_entry.DeviceOSBuild -like "10.0."+$_.Key+"*")      {$DeviceOSVersion = $_.Value}
    }
 
    # Query SCCM database for computer model number
    $compmodel = (Get-WmiObject -namespace root/SMS/site_RCS -computer "rcs-sc-01" -query "select Model from SMS_G_System_COMPUTER_SYSTEM where SMS_G_System_COMPUTER_SYSTEM.Name = '$CompName'").Model

    # Query SCCM database for asset tag
    $asset_unparsed = (Get-WmiObject -Namespace root/SMS/site_RCS -computer "rcs-sc-01" -query "select SMBIOSAssetTag from SMS_G_System_System_Enclosure where SMS_G_System_System_Enclosure.ResourceID = $resource_id").SMBIOSAssetTag

    # Further parse asset tag using regex
    if  ($asset_unparsed -ne "00000000")    {$asset_parsed = $asset_unparsed -replace '^0{0,8}'}
    else                                    {$asset_parsed = $asset_unparsed}
    
 
    # Add new fields to existing instantiated object
    $list_entry = $initial_entry | Select-Object Name, @{Name = "Asset Tag"; Expression = {$asset_parsed}}, SerialNumber, @{Name = "Model Number"; Expression = {$compmodel}}, MACAddress, @{Name = "OS Version"; Expression = {$DeviceOSVersion}}

    return $list_entry
}

# ================================================================================================









function Parse-Input
{
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $Comp,

        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $Funct
    )

    

    if($Comp){

        Connect-SCCM

        $reallist = @()
        $notfound = @()

        ForEach($a in $Comps)
        {
            
            # If SCCM returns null for comp search (meaning no results found) -- add comp name to the list of not found comps.
            if ($null -eq (Get-CMDevice -Name $a)) {$notfound+= $a}
            
            # If SCCM returns any results:
            else
            {
                
                # If a wildcard is used in search (ex: *D118*) -- we will need to filter each return individually to make sure Windows version definitions are accurate
                if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($a))
                {
                    
                    # Get name for each comp name returned by wildcard and store its to be further manipulated.
                    $wildcard_names = Get-CMDevice -Name $a | Select-Object "Name"

                    # For each individual name found in the wildcard search:
                    foreach ($individual in $wildcard_names)
                    {
                        # Wildcards - Hardware/OS Info:
                        if ($Funct -eq "Hardware")      {$list_entry = Get-SCCM-HWOS -CompName $individual.Name}

                        # Wildcards - Login Info:
                        elseif ($Funct -eq "Logins")        {$list_entry = Get-CMDevice -Name $individual.Name | select-object Name, CNIsOnline, PrimaryUser, CurrentLogonUser, LastLogonUser, LastActiveTime}

                        # No wildcards - BIOS Info
                        elseif ($Funct -eq "BIOS")      {$list_entry = Get-BIOS-SCCM -CompName $individual.Name}
                        
                        # Wildcard - append single object to final output list
                        $reallist += $list_entry

                    }

                }
                    
                # No wildcard detected in search
                else
                {
                    # No wildcards - Hardware/OS Info
                    if ($Funct -eq "Hardware")      {$list_entry = Get-SCCM-HWOS -CompName $a}

                    # No wildcards - Login Info
                    elseif ($Funct -eq "Logins")    {$list_entry = Get-CMDevice -Name $a | select-object Name, CNIsOnline, PrimaryUser, CurrentLogonUser, LastLogonUser, LastActiveTime}
                    
                    # No wildcards - BIOS Info
                    elseif ($Funct -eq "BIOS")      {$list_entry = Get-BIOS-SCCM -CompName $a}

                    $reallist += $list_entry
                }

                
            }
        }
        
        Print-Output -ValidComps $reallist -InvalidComps $notfound

        if ($Funct -eq "Hardware")
        {
            Write-Host "Note: OS build numbers are pulled from SCCM and can be out of date, causing the listed OS version to be wrong. If you suspect a mistake, run a SCCM Hardware Scan on the computer in question and run this again."
        }
        elseif ($Funct -eq "BIOS")
        {
            Write-Host "Note: BIOS version numbers are pulled from SCCM and can be out of date. By default they're refreshed weekly. If you suspect a mistake, run a SCCM Hardware Scan on the computer in question and run this again."
        }
    }
    
    else {Write-Host "No input detected, try again."}

}







# ================================================================================================










function Print-Output
{
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $ValidComps,

        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $InvalidComps
    )

    Write-Host `n'Comps Found in System:'
    
    if ($ValidComps.Length -gt 0){$ValidComps | Sort-Object -Property Name | Format-Table -Autosize -Wrap}
        else {Write-Host 'none'}

    if ($InvalidComps.Length -gt 0) {
        Write-Host `n'Comps Not Found in System:'`
        $InvalidComps | ForEach-Object {Write-Output $_.ToUpper()}
    }
}


# ===============================================================================================



$splashscreen = "


  _____                                        _                        _                                        __ 
 / ____|                                      | |                      | |                                      /_ |
| |        ___    _ __ ___    _ __    ______  | |        ___     ___   | | __  _   _   _ __        _ __    ___   | |
| |       / _ \  | '_ ` _  \  | '_ \  |______| | |       / _ \   / _ \  | |/ / | | | | | '_ \      | '_ \  / __|  | |
| |____  | (_) | | | | | | | | |_) |          | |____  | (_) | | (_) | |   <  | |_| | | |_) |  _  | |_) | \__ \  | |
 \_____|  \___/  |_| |_| |_| | .__/           |______|  \___/   \___/  |_|\_\  \__,_| | .__/  (_) | .__/  |___/  |_|
                             | |                                                      | |         | |               
                             |_|                                                      |_|         |_|               
                            RCS Tech script for looking up computer attributes in SCCM
                                          Only for use by RCS Technicians
"


$menu_main = @(
    "1. Hardware/OS Info"
    "2. Login Info"
    "3. BIOS Info"
    "Type 'q' at anytime to Quit"
)






$MenuBool = $True
$OGDir = Get-Location
$InputRules = "Wildcards (*) supported. Seperate multiple hostnames with spaces. Must be valid hosts within SCCM. Type 'q' to quit."





# Current user clearance check
if (!(Group-Check -check_group $clearance_group))
{
    # Fail out of script
    $MenuBool = $False
    Write-Warning "Invalid group membership. Aborting."
}
else 
{
    # Print splash screen
    $splashscreen
}





# Main Program
while ($MenuBool)
{
    $InputBool = $True
    $menu_main
    $MenuInput = Read-Host -Prompt "`nEnter option"

    
    # 1. Hardware Info
    
    if ($MenuInput -eq "1")
    {
        while($InputBool)
        {
            Write-Host "`n=======================================================================================================================`n"
            Write-Host $InputRules
            $Comp = Read-Host -Prompt "Enter Comp name(s)"
            
            If ($Comp -eq "q")
            {
                Write-Host ''
                $InputBool = $False
            }
            else
            {
                $Comps = $Comp.Split(' ')
                Parse-Input -Comp $Comps -Funct "Hardware"
            }
        }

        
    }
    
    # 2. Login Info
    elseif ($MenuInput -eq "2")
    {
        while($InputBool)
        {
            "`n=======================================================================================================================`n"
            Write-Host $InputRules
            $Comp = Read-Host -Prompt "Enter Comp name(s)"
            
            If ($Comp -eq "q")
            {
                Write-Host ''
                $InputBool = $False
            }
            else
            {
                $Comps = $Comp.Split(' ')
                Parse-Input -Comp $Comps -Funct "Logins"
            }
        }
    }

    # 3. BIOS Info
    elseif ($MenuInput -eq "3")
    {
        while($InputBool)
        {
            "`n=======================================================================================================================`n"
            Write-Host $InputRules
            $Comp = Read-Host -Prompt "Enter Comp name(s)"
            
            If ($Comp -eq "q")
            {
                Write-Host ''
                $InputBool = $False
            }
            else
            {
                $Comps = $Comp.Split(' ')
                Parse-Input -Comp $Comps -Funct "BIOS"
            }
        }
    }







    
    # q - Quit
    elseif ($MenuInput -eq "q")
    {
        $MenuBool = $False
        Set-Location $OGDir
    }
    
    # Invalid input
    else {Write-Host "Bad input, try again`n"}

} 
