$temproot = $Env:tmp
$wuptemp = "$temproot\wup\"
$wuplog = "$temproot\wup.log"
$clearance_group = "Technicians"

$scriptroot = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
$wuproot = $scriptroot+"\wup\"
$biosroot = $wuproot+"bios\"

$moduleroot = "$scriptroot\.modules"

# Module import
Import-Module "$moduleroot\Get-Asset.psm1"
Import-Module "$moduleroot\Get-BIOS.psm1"
Import-Module "$moduleroot\Get-CheckOrX.psm1"
Import-Module "$moduleroot\Get-CompType.psm1"
Import-Module "$moduleroot\Get-DellUpdate.psm1"
Import-Module "$moduleroot\Get-ElevationStatus.psm1"
Import-Module "$moduleroot\Get-ImageType.psm1"
Import-Module "$moduleroot\Get-Model.psm1"
Import-Module "$moduleroot\Get-Name.psm1"
Import-Module "$moduleroot\Get-OS.psm1"
Import-Module "$moduleroot\Get-Power.psm1"
Import-Module "$moduleroot\Get-PSVersion.psm1"
Import-Module "$moduleroot\Get-SN.psm1"
Import-Module "$moduleroot\Group-Check.psm1"
Import-Module "$moduleroot\Write-Loading.psm1"
Import-Module "$moduleroot\Write-Log.psm1"

$splashscreen = "
===================================================
                                               __ 
                                              /_ |
 __      __  _   _   _ __        _ __    ___   | |
 \ \ /\ / / | | | | | '_ \      | '_ \  / __|  | |
  \ V  V /  | |_| | | |_) |  _  | |_) | \__ \  | |
   \_/\_/    \__,_| | .__/  (_) | .__/  |___/  |_|
                    | |         | |               
                    |_|         |_|                       
       RCS Tech script for updating machines
          Only for use by RCS Technicians
===================================================
"

$mainmenu = @(
    "0. Start 'Set Dell Asset Tag' utility"
    ""
    "1. Run SCCM Actions script, open Software Center"
    "2. Run SCCM Client Repair"
    ""
    "3. Update BIOS"
    ""
    "4. Scan for Windows Updates, open Windows Update"
    ""
    "5. Install/run Dell Command Update utility"
    "6. Clean up"
    ""
    "7. Quit"
)

try
{
    $dcucli_params = ("-userConsent=disable", "-biosPassword=6210", "-scheduleManual", "-updatesNotification=disable")

    $flag_global = $True
    $flag_invalid = $False
    $workdir = Get-Location
    $flash_valid = $False
    $flag_refresh = $False
    
    $counter = 1
    $battery_health_good = .70

    Write-Log -String "`n======================================================="

    Write-Log -String "Setting initial parameters:
    Local temp directory: $temproot
    Local wup folder: $wuptemp
    Local wup log: $wuplog
    Tech scripts directory: $scriptroot
    Wup working directory: $wuproot
    BIOS directory: $biosroot
    Current working directory: $workdir
    dcu-cli parameters: $dcucli_params
    Computer type: $comptype
    Battery acceptable health (hardcoded): $battery_health_good
    Global flag: $flag_global
    "

    $get_name = Get-Name
    $get_model = Get-Model
    $get_comptype = Get-CompType -model $get_model.model
    $get_power = Get-Power -comptype $get_comptype
    $get_bios = Get-BIOS -wuproot $wuproot -model $get_model.model
    $get_os = Get-OS -model $get_model.model
    $get_dellupdate = Get-DellUpdate
    $get_sn = Get-SN
    $get_imagetype = Get-ImageType
    $get_asset = Get-Asset 
    $get_elevationstatus = Get-ElevationStatus
    $get_groupcheck = Group-Check -check_group $clearance_group
    
    try 
    {
        (Get-ADPrincipalGroupMembership -Identity $check_user | select-object name | sort-object name).getenumerator() | foreach-object {if($_.name -eq $clearance_group) {$get_groupcheck = $True}}
    }
    catch 
    {
        whoami /groups /fo csv | convertfrom-csv | foreach-object {if ($_."Group Name" -like "*RCS\$clearance_group*") {$get_groupcheck = $True}}
    }
    


    if (!(Test-Path $wuptemp))
    {
        Write-Log -String "Local temp directory does not exist. Creating."
        $null = New-Item -Path $wuptemp -itemtype "directory"
    }
    else    {Write-Log -String "Local temp directory already exists. Continuing."}
    
    $startup_array = [Ordered]@{
        "Name"                          =           $get_name.name_string
        "Model"                         =           $get_model.model_string
        "SN"                            =           $get_sn.sn_string
        "Image"                         =           $get_imagetype.image_string
        "Asset Tag"                     =           $get_asset.asset_string
        "BIOS version"                  =           $get_bios.bios_string
        "OS version"                    =           $get_os.osver_string
        "Dell Update installed?"        =           $get_dellupdate.dcu_string
    }

    if ($get_comptype -eq "laptop"){
        $startup_array += [Ordered]@{
            ""                          =           ""
            "Charger connected?"        =           $get_power.charger_string
            "Battery charge"            =           $get_power.charge_string
            "Battery health"            =           $get_power.health_string
        }
    }

    ### For debugging only
    # $get_elevationstatus = $True
    # $get_groupcheck = $True


    if (!$get_elevationstatus)
    {
        $flag_global = $False
        Write-Warning "This script must be run as admin. Exiting."
        Write-Log -String "This script must be run as admin. Exiting."
    } 
    elseif (!$get_groupcheck) 
    {
        $flag_global = $False
        Write-Warning "Script can only be run by Technicians. Exiting."
        Write-Log -String "Script can only be run by Technicians. Exiting."
    }
    else
    {
        # Print splash screen and startup array
        $splashscreen
        
        $startup_array | Format-Table -HideTableHeaders
        Write-Log -String ""
        Write-Log -String "Splash screen output:"
        # Write-Log -hashtable $startup_array

        Write-Host "Log file saved at $wuplog`n"
    }

    #########################################################
    # END PRE LOOP


    while ($flag_global)
    {     
        # Certain variables should be refreshed at the beginning of loops to account for changing conditions like plugging chargers in and uninstalling DCU. Otherwise you will run into issues, see below.
        # Ex: On first loop charger is not plugged in, you realize this, plug charger in. On second loop, script should detect this and change accordingly.
        # Ex: On first loop you uninstall DCU. On second loop you try to reinstall DCU. Second loop should detect that DCU is now uninstalled, instead of throwing errors.

        $refresh_array = @{}
        $flag_refresh = $False
        $get_power = Get-Power -comptype $get_comptype
        $get_dellupdate = Get-DellUpdate
        
        if ($get_power.charger_string -ne $startup_array["Charger connected?"])
        {
            $flag_refresh = $True
            $refresh_array += @{"Charger connected?"    =       $get_power.charger_string}
            $startup_array["Charger connected?"]        =       $get_power.charger_string
        }
        if ($get_dellupdate.dcu_string -ne $startup_array["Dell Update installed?"])
        {
            $flag_refresh = $True
            $refresh_array += @{"Dell Update installed?"    =       $get_dellupdate.dcu_string}
            $startup_array["Dell Update installed?"]        =       $get_dellupdate.dcu_string
        }

        if ($flag_refresh) 
        {
            Write-Host "Refreshed variables:"
            $refresh_array | Format-Table -HideTableHeaders
        }


        Write-Host "`n`n"
        $mainmenu
        
        write-host "`n[$counter] ==================================================================`n"
        Write-Log -string "Opening main menu. Awaiting user input."

        if      ($flag_invalid -eq $False)       {$MenuInput = Read-Host "Enter option"}
        else    {$flag_invalid = $False}

        Write-Log -string "User input: '$MenuInput'"

        write-host("`n")




        # 0. Start 'Set Dell Asset Tag' utility
        if ($MenuInput -eq "0")
        {
            Write-Log -string "Begin option 0 - start 'Dell Asset Tag' utility."
            
            Copy-Item -Path "$scriptroot\Set Dell Asset Tag" -Recurse -Destination $wuptemp -Force
            Set-Location "$wuptemp\Set Dell Asset Tag"
            Start-Process "Set-Dell-Asset-Tag.exe" -Wait
            
            Write-Log -string "End option 0."
        }

        # 1. Run SCCM Actions script, open Software Center
        elseif ($MenuInput -eq "1")
        { 
            Write-Log -string "Begin option 1 - start 'SCCM Actions script."
            
            Write-Log -string "     Starting SCCM Actions script."
            Start-Process powershell "$scriptroot\SCCM_Actions.ps1" -WindowStyle Minimized
            Start-Process softwarecenter: -WindowStyle Maximized
            
            Write-Log -string "End option 1."
        }

        # 2. Run SCCM client repair
        elseif ($MenuInput -eq "2") 
        {
            Write-Log -string "Begin option 2 - run SCCM client repair."

            Write-Log -string "     Starting SCCM client repair."
            Start-Process -FilePath "C:\Windows\CCM\ccmrepair.exe" -Wait -NoNewWindow
            Write-Log -string "     Finished SCCM client repair."

            Write-Log -string "End option 2."
        }

        # 3. Update BIOS
        elseif ($MenuInput -eq "3") 
        {
            Write-Log -string "Begin option 3 - update BIOS."

            if ($get_comptype -eq "Desktop")
            {
                Write-Log -string "     This is a desktop. Skipping battery/charger checks."
                $flash_valid = $True
            }
            
            else
            {
                Write-Log -string "     This is a laptop. Checking for battery/charger..."
                $get_power = Get-Power -comptype $get_comptype
                $wmi_battery = $get_power.battery_charge

                if (!$wmi_battery)
                {
                    Write-Warning 'Battery not found. Aborting.'
                    Write-Host "Returning to main menu in 2s..."; Start-Sleep -Seconds 2
                    Write-Log -string "     Battery not found. Aborting."
                }
                else 
                {
                    Write-Log -string "     Battery found. Remaining charge: $wmi_battery%"
                    
                    if ($wmi_battery -lt 10)
                    {
                        Write-Warning 'Charge less than 10%. Aborting.'
                        Write-Host "Returning to main menu in 2s..."; Start-Sleep -Seconds 2
                        Write-Log -string '     Charge less than 10%. Aborting.'
                    }
                    else 
                    {
                        if (!($get_power.charger_status))
                        {
                            Write-Warning "Charger not found. Aborting."
                            Write-Host "Returning to main menu in 2s..."; Start-Sleep -Seconds 2
                            Write-Log -string "     Charger not found. Aborting."
                        }
                        else 
                        {
                            Write-Log -string "     Charger found."
                            $flash_valid = $True
                        }
                    }
                }
            }

            if ($flash_valid) 
            {
                Write-Log -string "     Flash is a go."

                $bios_current = $get_bios.bios_current
                $bios_upg = $get_bios.bios_upg
                $bios_path = $get_bios.bios_path
                $bios_exe = $get_bios.bios_exe

                if ($null -ne $bios_path){
                    Write-Log -string "     Upgrade exe found!`n    Current version: $bios_current`n       Upgrade version: $bios_upg"

                    if ([System.Version]$bios_current -lt [System.Version]$bios_upg)
                    {
                        Write-Log -string "     Upgrade possible. Copying bios exe to temp directory..."
                        Copy-Item -Path $bios_path -Destination $wuptemp -Force

                        Write-Host "Starting BIOS exe... " -NoNewline
                        Write-Log -string "     Starting bios exe."
                        Start-Process $wuptemp\$bios_exe
                        Write-Host "Done!"

                    }
                    else 
                    {
                        Write-Warning "No upgrade necessary. Aborting."
                        Write-Log -string "     No upgrade necessary. Aborting."
                    }
                }
                else 
                {
                    Write-Warning "Something went wrong. Aborting."
                    Write-Log -string "     Something went wrong. Aborting."
                }
            }  
        }

        # 4. Windows Updates
        elseif ($MenuInput -eq "4") 
        {
            Write-Log -string "Begin option 4 - Run Windows Updates."
            Write-Log -string "     Starting Windows Update scan. Updater service will continue in the background."
            UsoClient StartInteractiveScan                  

            Write-Log -string "     Opening Windows Update window."
            Start-Process 'ms-settings:windowsupdate' -WindowStyle Minimized       
            
            write-host -NoNewLine "Windows Update is opened. Updater service will continue in the background."
        }

        # 5. Update drivers (via dcu-cli)
        elseif ($MenuInput -eq "5")
        {
            # dcu-cli commands: https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/dell-command-|-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us
            
            Write-Log -String "Begin option 5 - update drivers/BIOS via dcu-cli"

            $dcu_installer_file = "DellCommandUpdateApp_2023-10.msi"
            $dcu_installer_path1 = "$biosroot"+"$dcu_installer_file"
            $dcu_installer_path2 = "$wuptemp"+"$dcu_installer_file"

            $get_dellupdate = Get-DellUpdate

            if($get_dellupdate.dcu_test) {
                Write-Log -String "     DCU is already installed."
            }
            else {
                Write-Log -String "     Copying installer to local drive."
                
                # $processflag = $True
                # $processcmd = Copy-Item -Path $dcu_installer_path1 -Destination $wuptemp -Force
                #
                # while($processflag)
                # {
                #     Write-Loading -loopflag $False -activitystring "Copying installer to local drive..."
                #     if (!$processcmd){$processflag = $False}
                # }
                
                Write-Host "Copying installer to local drive..." -NoNewline
                Copy-Item -Path $dcu_installer_path1 -Destination $wuptemp -Force
                Write-Host " Done!"
                
                Write-Log -String "     Installer copied from $dcu_installer_path1 to $dcu_installer_path2"

                Set-Location $wuptemp

                # $processflag = $True
                # $processcmd = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i "DellCommandUpdateApp_2023-10.msi" /qn' -Wait -NoNewWindow 
                # 
                # while ($processflag)
                # {
                #     Write-Loading -loopflag $False -activitystring "Installing Dell Command Update..."
                #     if (!$processcmd){$processflag = $False}
                # }

                Write-Host "Installing Dell Command Update..." -NoNewline
                Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i "DellCommandUpdateApp_2023-10.msi" /qn' -Wait -NoNewWindow 
                Write-Host " Done!"


                Write-Log -String "     DCU installed."
            }

            Write-Host "Configuring Dell Command Update..." -NoNewline
            $dcucli_params | ForEach-Object {
                & 'C:\Program Files\Dell\CommandUpdate\dcu-cli.exe' /configure $_ | Out-Null
                Write-Log -String "     DCU configured with the following parameter: $_"
            }
            Write-Host " Done!"
            
            Write-Host "Launching Dell Command Update..."
            & 'C:\Program Files\Dell\CommandUpdate\dcu-cli.exe' /applyupdates -reboot=enable
            # $processcmd = & 'C:\Program Files\Dell\CommandUpdate\dcu-cli.exe' /applyupdates -reboot=enable
            # $processcode = (($processcmd | findstr "return code") -split " ")[6]
            # Write-Log -string "     Dell Command Update ran succesfully. Exit code: $processcode"
            Write-Log -string "     Dell Command Update ran succesfully"

            
            # if ($processcode -eq "1" )
            # {
            #     shutdown /r
            # }
            
            Write-Log -string "End option 5."
        }

        # 6. Clean-up
        elseif ($MenuInput -eq "6")
        {
            Write-Log -string "Begin option 6 - clean up / uninstall Dell Command Update."
        
            
            
            # Wipe local temp folder
            Write-Log -string "     Checking for temp folder."

            if (Test-Path $wuptemp -PathType Container)
            {
                Write-Log -string "     Temp folder found at $wuptemp."
                Write-Host "Clearing temp folder... " -NoNewline
                try 
                {
                    Remove-Item -Path $wuptemp -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "Done!" 
                    Write-Log -string "     Succesfully deleted $wuptemp."
                }
                catch   
                {
                    Write-Host "Finished, with errors." 
                    Write-Log -string "        Error deleting temp folder. Continuing."
                }
            }
            else
            {
                Write-Log -string "     Temp folder not found."
            }

            # Run DCU check again for updated status within same session
            $get_dellupdate = Get-DellUpdate

            # Uninstall DCU
            Write-Log -string "     Checking for Dell Command Update."

            if (!($get_dellupdate.dcu_test))    
            {
                Write-Log -string "     Dell Command Update does not appear to be installed. Continuing."
            }
            else 
            {
                if (Get-Service -Name "DellClientManagementService") 
                {
                    Write-Host "Killing DellClientManagementService... " -NoNewline
                    try 
                    {
                        Stop-Process (Get-WmiObject Win32_Service -Filter "Name LIKE 'DellClientManagementService'").ProcessId -Force
                        Write-Host "Done!"
                        Write-Log -string "     Successfully killed DellClientManagementService."
                    }
                    catch 
                    {
                        Write-Host "Finished, with errors."
                        Write-Log -string "        Failed to kill DellClientManagementService. Continuing."
                    }
                }
                
                
                $rkey = $get_dellupdate.dcu_regkey
                
                Write-Host "Uninstalling Dell Command Update... " -NoNewline
                try {
                    # Start-Process 'msiexec' -ArgumentList '/x {612F7720-D28A-473F-8FB9-C8D300B5F534} /qn' -Wait -NoNewWindow
                    Start-Process 'msiexec' -ArgumentList "/x $rkey /qn" -Wait -NoNewWindow
                    Write-Host "Done!" 
                    Write-Log -string "     Succesfully uninstalled Dell Command Update."
                }
                catch 
                {
                    Write-Host "Finished, with errors."
                    Write-Log -string "      Failed to uninstall Dell Command Update."

                }

                
                # Invoke-Command -ScriptBlock {
                #     param $rkey
                #     Start-Process 'msiexec' -ArgumentList '/x $rkey /qn' -Wait -NoNewWindow
                # } -ArgumentList $rkey

                if (Test-Path -Path "C:\Program Files (x86)\Dell\Update\DellUpdate.exe" -PathType Leaf) {
                    Get-ChildItem -Path "C:\Program Files (x86)\Dell\Update\" | Remove-Item -Recurse -Force
                    Remove-Item -Path "C:\Program Files (x86)\Dell\Update\" -Force
                    Write-Log -string "     Deleted orphaned Dell Update folder."

                    if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dell\Update\Dell Update.lnk") 
                    {
                        Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dell\Update\Dell Update.lnk"
                        Write-Log -string "     Deleted orphaned Start Menu link."
                    }
                    
                    else{Write-Log -string "    No orphaned Start Menu link found."}
                }

                Write-Log -string "Refreshing Dell Command Update status."
                $get_dellupdate = Get-DellUpdate

                Write-Log -string "End option 6."
            }
        } 

        # 7. Quit
        elseif ($MenuInput -eq "7") 
        {
            $flag_global = $False
            Set-Location $workdir
            Write-Log -String "Begin option 7 - exit."
        }

        # Other input
        else
        {
            $flag_invalid = $True
            Write-Log -String "Invalid input detected."
            $MenuInput = Read-Host "Invalid input, try again"
        }

        $counter +=1
        write-host "`n======================================================================"
    }
    
    Write-Host "Log file saved at $wuplog`n"
    # Write-Log -string "Script ended cleanly."
}

catch {
    Write-Warning "An error occurred, aborting. See error details at $wuplog.`n"
    Write-Host $Error[0]
    Write-Log -string "An error occurred: $_."
}