function Format-Response
{
    param ($Var)

    if ($Var)   {$return_string = (Get-CheckOrX -Var $True) + ' Present'}
    else        {$return_string = (Get-CheckOrX -Var $False) + ' Absent'}

    return $return_string
}

function Remove-ADComp
{
    param(
        [Parameter(Position=0,Mandatory)]
        $Comp,

        [Parameter(Position=1,Mandatory)]
        $TestResult
    )

    if ($TestResult)
    {
        Remove-ADComputer -Identity $Comp -Confirm:$False
        Write-Host "Comp deleted from AD."
    }
    else    {Write-Host "Comp is not listed in AD."}
}

function Remove-CMComp
{
    param(
        [Parameter(Position=0,Mandatory)]
        $Comp,

        [Parameter(Position=1,Mandatory)]
        $TestResult
    )

    Connect-SCCM

    if ($TestResult)
    {
        Remove-CMDevice -Name $Comp -Force
        Write-Host "Comp deleted from SCCM."
    }
    else    {Write-Host "Comp is not listed in SCCM under this name."}

    Set-Location $currentdir
}

function Test-ADComp
{
    param ($Comp)

    try {
        if (Get-ADComputer -Identity $Comp)             {return $True}
        else                                            {return $False}
        
    }
    catch {
        return $False
    }
}

function Test-CMComp
{
    param ($Comp)

    Connect-SCCM

    try {
        if (Get-CMDevice -Name $Comp)   {$test_return = $True}
        else                            {$test_return = $False}
    }
    catch {
        $test_return = $False
    }

    Set-Location $currentdir

    return $test_return
}

# Initial variable setting
$currentdir = Get-Location
$script_root = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
$module_root = "$script_root\.modules"
$flag_global = $True
$clearance_group = "Technicians"
$splashscreen = "
             _____              _____   __  __            _____           _          _                              __ 
     /\     |  __ \            / ____| |  \/  |          |  __ \         | |        | |                            /_ |
    /  \    | |  | |  ______  | |      | \  / |  ______  | |  | |   ___  | |   ___  | |_    ___       _ __    ___   | |
   / /\ \   | |  | | |______| | |      | |\/| | |______| | |  | |  / _ \ | |  / _ \ | __|  / _ \     | '_ \  / __|  | |
  / ____ \  | |__| |          | |____  | |  | |          | |__| | |  __/ | | |  __/ | |_  |  __/  _  | |_) | \__ \  | |
 /_/    \_\ |_____/            \_____| |_|  |_|          |_____/   \___| |_|  \___|  \__|  \___| (_) | .__/  |___/  |_|
                                                                                                     | |               
                                                                                                     |_|               
                             RCS Tech script for deleting computers from AD and SCCM
                                        Only for use by RCS Technicians
"

# Module import
Import-Module "$module_root\Connect-SCCM.psm1"
Import-Module "$module_root\Get-CheckOrX.psm1"
Import-Module "$module_root\Group-Check.psm1"
Import-Module "$module_root\Request-YesNo.psm1"

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

while($flag_global)
{
    $Comp = Read-Host -Prompt "`nEnter comp name"

    $adstatus = Test-ADComp -Comp $Comp
    $cmstatus = Test-CMComp -Comp $Comp

    $adresponse = Format-Response -Var $adstatus
    $cmresponse = Format-Response -Var $cmstatus

    Write-Host "AD status: $adresponse"
    Write-Host "CM status: $cmresponse"

    if ($adstatus -or $cmstatus)
    {
        $yn = Request-YesNo "`nRemove comp?"
        if ($yn)
        {
            if ($adstatus) {Remove-ADComp -Comp $Comp -TestResult $adstatus}
            if ($cmstatus) {Remove-CMComp -Comp $Comp -TestResult $cmstatus}   
        }
    }
}