param 
( 
    [switch]$debug 
)

$temproot = $Env:tmp
$wuptemp = "$temproot\wup\"
$wuplog = "$temproot\wup.log"
$clearance_group = "Technicians"

$scriptroot = "\\rcs-fvs-04\AdminData$\MediaTechnology\Common\Techs\script"
# $scriptroot = "H:\bin\Techs"
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
Import-Module "$moduleroot\Get-Zoom.psm1"
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

             Last updated 2024-05-06
     User must now securely enter BIOS password;
            it is no longer hardcoded
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
    "5. Install/run Dell Command Update utility`n   WARNING: WILL UPDATE BIOS AND AUTO-REBOOT IF NEEDED"
    ""
    "6. Update Zoom client"
    ""
    "7. Clean up"
    ""
    "8. Rename computer`n   WARNING: WILL AUTO-REBOOT"
    ""
    "q. Quit"
)

try
{
    $dcucli_params = ("-userConsent=disable", "-scheduleManual", "-updatesNotification=disable")

    $flag_global = $True
    $flag_invalid = $False
    $workdir = Get-Location
    $flash_valid = $False
    $flag_refresh = $False
    $hostname = hostname
    $user = whoami
    $counter = 1
    $battery_health_good = .70

    Write-Log -String "|| Running on $hostname under $user" -logflag $True

    Write-Log -String "Setting initial parameters:" -logflag $True

    Write-Log -list @(
    "Local temp directory: $temproot",
    "Local wup folder: $wuptemp",
    "Local wup log: $wuplog",
    "Tech scripts directory: $scriptroot",
    "Wup working directory: $wuproot"
    "BIOS directory: $biosroot",
    "Current working directory: $workdir",
    "dcu-cli parameters: $dcucli_params",
    "Battery acceptable health (hardcoded): $battery_health_good",
    "Script global flag: $flag_global"
    ) -logflag $True

    $get_groupcheck = Group-Check -check_group $clearance_group -logflag $debug
    $get_elevationstatus = Get-ElevationStatus -logflag $debug

    ### For debugging only
    # $get_elevationstatus = $True
    # $get_groupcheck = $True


    if (!$get_elevationstatus)
    {
        $flag_global = $False
        Write-Warning "This script must be run as admin. Exiting in 5s."
        Write-Log -String "Aborting: requires admin permissions." -logflag $True
        Start-Sleep -Seconds 5
    } 
    elseif (!$get_groupcheck) 
    {
        $flag_global = $False
        Write-Warning "Script can only be run by $clearance_group. Exiting in 5s."
        Write-Log -String "Aborting: user is not in $clearance_group group." -logflag $True
        Start-Sleep -Seconds 5
    }

    #########################################################
    # END PRE LOOP


    while ($flag_global)
    {    
        
        if (!(Test-Path $wuptemp))
        {
            Write-Log -String "Local temp directory does not exist. Creating." -logflag $True
            $null = New-Item -Path $wuptemp -itemtype "directory"
        }
        else    {Write-Log -String "Local temp directory already exists. Continuing." -logflag $True} 

        # Functions for startup array
        $get_name = Get-Name
        $get_model = Get-Model -logflag $debug
        $get_comptype = Get-CompType -model $get_model.model -logflag $debug
        $get_power = Get-Power -comptype $get_comptype -logflag $debug
        $get_bios = Get-BIOS -wuproot $wuproot -model $get_model.model -logflag $debug
        $get_os = Get-OS -model $get_model.model -logflag $debug
        $get_dellupdate = Get-DellUpdate -logflag $debug
        $get_sn = Get-SN
        $get_imagetype = Get-ImageType -logflag $debug
        $get_asset = Get-Asset -logflag $debug
        $get_zoom = Get-Zoom

        
        # Run on first loop only
        if ($counter -eq 1)
        {
            # Populate startup array
            $startup_array = [Ordered]@{
                "Name"                          =           $get_name.name_string
                "Model"                         =           $get_model.model_string
                "SN"                            =           $get_sn.sn_string
                "Image"                         =           $get_imagetype.image_string
                "Asset Tag"                     =           $get_asset.asset_string
                "BIOS version"                  =           $get_bios.bios_string
                "OS version"                    =           $get_os.osver_string
                "Zoom version"                  =           $get_zoom.zoom_string
                "Dell Update installed?"        =           $get_dellupdate.dcu_string
            }
        
            # Add charge/battery info if it's determined the computer is a laptop
            if ($get_comptype -eq "laptop"){
                $startup_array += [Ordered]@{
                    ""                          =           ""
                    "Charger connected?"        =           $get_power.charger_string
                    "Battery charge"            =           $get_power.charge_string
                    "Battery health"            =           $get_power.health_string
                }
            }
            
            # Print splash screen and startup array
            $splashscreen
            
            $startup_array | Format-Table -HideTableHeaders
            Write-Log -String "Startup array:" -logflag $True
            Write-Log -hashtable $startup_array -logflag $True
            Write-Host "Log file saved at $wuplog`n"
            
        }

        # Run on every loop after the first
        else
        {
            # Certain variables should be refreshed at the beginning of loops to account for changing conditions like plugging chargers in and uninstalling DCU. Otherwise you will run into issues or inaccurate info.

            # Clear existing content in refresh and diff arrays
            $refresh_array = @{}.Clear()
            $diff_array = @{}.Clear()

            # Run module functions a second time
            $refresh_array = [Ordered]@{
                "Name"                          =           $get_name.name_string
                "Model"                         =           $get_model.model_string
                "SN"                            =           $get_sn.sn_string
                "Image"                         =           $get_imagetype.image_string
                "Asset Tag"                     =           $get_asset.asset_string
                "BIOS version"                  =           $get_bios.bios_string
                "OS version"                    =           $get_os.osver_string
                "Zoom version"                  =           $get_zoom.zoom_string
                "Dell Update installed?"        =           $get_dellupdate.dcu_string
            }
        
            if ($get_comptype -eq "laptop")
            {
                $refresh_array += [Ordered]@{
                    ""                          =           ""
                    "Charger connected?"        =           $get_power.charger_string
                    "Battery charge"            =           $get_power.charge_string
                    "Battery health"            =           $get_power.health_string
                }
            }

            # Add changed key+value pairs to diff array
            $refresh_array.GetEnumerator() | ForEach-Object {
                if ($_.value -ne $startup_array[$_.key]) 
                {
                    $diff_array += [Ordered]@{$_.key = $_.value}
                }
            }

            # Only present results if diff array has entries this loop
            if ($diff_array.count -gt 0)
            {
                Write-Host "`nRefreshed variables:"
                $diff_array | Format-Table -HideTableHeaders
                Write-Log -String "Refreshed variables:" -logflag $True
                Write-Log -hashtable $diff_array -logflag $True
            }

            # Overwrite startup array, to use for comparison in the next loop
            $startup_array = $refresh_array

        }

        # Print main menu
        Write-Host "`n`n"
        $mainmenu
        write-host "`n[$counter] ==================================================================`n"

        # Take user input
        if      ($flag_invalid -eq $False)       {$MenuInput = Read-Host "Enter option"}
        else    {$flag_invalid = $False}
        Write-Log -string "User input: '$MenuInput'" -logflag $True



        # 0. Start 'Set Dell Asset Tag' utility
        if ($MenuInput -eq "0")
        {
            Write-Log -string "Begin option 0 - start 'Dell Asset Tag' utility." -logflag $True
            
            Copy-Item -Path "$scriptroot\Set Dell Asset Tag" -Recurse -Destination $wuptemp -Force
            Set-Location "$wuptemp\Set Dell Asset Tag"
            Write-Log -string "     Copied Dell Asset Tag utility to $wuptemp\Set-Dell-Asset-Tag.exe." -logflag $True
            
            Start-Process "Set-Dell-Asset-Tag.exe" -Wait
            Write-Log -string "     Started Dell Asset Tag utility." -logflag $True
            
            Write-Log -string "End option 0."
        }

        # 1. Run SCCM Actions script, open Software Center
        elseif ($MenuInput -eq "1")
        {  
            Write-Log -string "Begin option 1 - start 'SCCM Actions script." -logflag $True
            
            Start-Process powershell "$scriptroot\SCCM_Actions.ps1" -WindowStyle Minimized
            Write-Host "SCCM actions will continue in the background."
            Write-Log -string "     Started SCCM Actions script. Will run in the background" -logflag $True
            
            Start-Process softwarecenter: -WindowStyle Maximized
            Write-Log -string "     Started Software Center." -logflag $True
            
            Write-Log -string "End option 1." -logflag $True
        }

        # 2. Run SCCM client repair
        elseif ($MenuInput -eq "2") 
        {
            Write-Log -string "Begin option 2 - run SCCM client repair." -logflag $True

            Write-Log -string "     Started SCCM client repair." -logflag $True
            Start-Process -FilePath "C:\Windows\CCM\ccmrepair.exe" -Wait -NoNewWindow
            Write-Log -string "     Finished SCCM client repair." -logflag $True

            Write-Log -string "End option 2." -logflag $True
        }

        # 3. Update BIOS
        elseif ($MenuInput -eq "3") 
        {
            Write-Log -string "Begin option 3 - update BIOS." -logflag $True
            $flash_valid = $False

            # Battery check - desktop
            if ($get_comptype -eq "Desktop")
            {
                Write-Log -string "     This is a desktop. Skipping battery/charger checks." -logflag $True
                $flash_valid = $True
            }
            
            # Battery check - laptop
            else
            {
                # Run Get-Power again before any checks
                Write-Log -string "     This is a laptop. Beginning battery/charger checks." -logflag $True
                $get_power = Get-Power -comptype $get_comptype
                $wmi_battery = $get_power.battery_charge
                $wmi_charger = $get_power.charger_status

                # Charger found
                if ($wmi_charger) 
                {
                    Write-Log -string "     Charger found." -logflag $True
                    
                    # Battery found
                    if ($wmi_battery) 
                    {
                        # Charge <10%
                        if ($wmi_battery -lt 10)
                        {
                            Write-Warning 'Charge less than 10%. Aborting.'
                            Write-Host "Returning to main menu in 2s..."; Start-Sleep -Seconds 2
                            Write-Log -string '     Charge less than 10%. Aborting.' -logflag $True
                        }

                        # Charge >10% (true condition)
                        else
                        {
                            Write-Log -string "     Charge greater than 10%. Continuing." -logflag $True
                            $flash_valid = $True
                        }
                    }
                    
                    # No battery (true condition)
                    else
                    {
                        Write-Warning 'Battery not found. Flash will still continue but be careful.'
                        Start-Sleep -Seconds 2
                        Write-Log -string '     Battery not found. Continuing.' -logflag $True
                        $flash_valid = $True
                    }

                }
                
                # No charger
                else        
                {
                    # Charger with no battery (true condition)
                    # Account for rare condition where a laptop has a charger connected and no battery - win32_batterycharge will return null, meaning no battery, but if the laptop is still powered with no battery then it has to be powered by a charger.
                    if (!$wmi_battery) 
                    {
                        Write-Warning 'Battery not found. Flash will still continue but be careful.'
                        Start-Sleep -Seconds 2
                        Write-Log -string '     Battery not found. Continuing.' -logflag $True
                        $flash_valid = $True
                    }

                    # Battery with no charger
                    else 
                    {
                        Write-Log -string "     Charger not found. Aborting." -logflag $True
                        Write-Warning "Charger not found. Returning to main menu in 2s..."; Start-Sleep -Seconds 2
                    }
                }
            }

            if ($flash_valid) 
            {
                Write-Log -string "     Flash is a go." -logflag $True

                $bios_current = $get_bios.bios_current
                $bios_upg = $get_bios.bios_upg
                $bios_path = $get_bios.bios_path
                $bios_exe = $get_bios.bios_exe

                if ($null -ne $bios_path){
                    Write-Log -string "     Upgrade exe found. Current version: $bios_current. Upgrade version: $bios_upg." -logflag $True

                    if ([System.Version]$bios_current -lt [System.Version]$bios_upg)
                    {
                        Write-Log -string "     Upgrade possible. Copying bios exe to temp directory..." -logflag $True
                        Copy-Item -Path $bios_path -Destination $wuptemp -Force

                        Write-Host "Starting BIOS exe... " -NoNewline
                        Write-Log -string "     Starting bios exe." -logflag $True
                        Start-Process $wuptemp\$bios_exe
                        Write-Host "Done!"

                    }
                    else 
                    {
                        Write-Warning "No upgrade necessary. Aborting."
                        Write-Log -string "     No upgrade necessary. Aborting." -logflag $True
                    }
                }

                else 
                {
                    Write-Warning "Something went wrong. Aborting."
                    Write-Log -string "     BIOS exe filepath is null. Either the filepath or the folder auto-generated by Get-BIOS was not found." -logflag $True
                }
            }  

            Write-Log -string "End option 3." -logflag $True
        }

        # 4. Windows Updates
        elseif ($MenuInput -eq "4") 
        {
            Write-Log -string "Begin option 4 - Run Windows Updates." -logflag $True
            Write-Log -string "     Starting Windows Update scan. Updater service will continue in the background." -logflag $True
            UsoClient StartInteractiveScan                  

            Write-Log -string "     Opening Windows Update window." -logflag $True
            Start-Process 'ms-settings:windowsupdate' -WindowStyle Minimized       
            
            Write-Host -NoNewLine "Windows Update is opened. Updater service will continue in the background."
        }

        # 5. Update drivers (via dcu-cli)
        elseif ($MenuInput -eq "5")
        {
            # dcu-cli commands: https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/dell-command-|-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us
            
            Write-Log -String "Begin option 5 - update drivers/BIOS via dcu-cli" -logflag $True

            $dcu_installer_file = "DellCommandUpdateApp_5.2.0.msi"
            $dcu_installer_path1 = "$biosroot"+"$dcu_installer_file"
            $dcu_installer_path2 = "$wuptemp"+"$dcu_installer_file"

            $get_dellupdate = Get-DellUpdate

            if($get_dellupdate.dcu_test) {
                Write-Log -String "     DCU is already installed." -logflag $True
            }
            else {
                Write-Log -String "     Copying installer to local drive."-logflag $True
                
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
                
                Write-Log -String "     Installer copied from $dcu_installer_path1 to $dcu_installer_path2" -logflag $True

                Set-Location $wuptemp

                # $processflag = $True
                # $processcmd = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i "DellCommandUpdateApp_5.1.0.msi" /qn' -Wait -NoNewWindow 
                # 
                # while ($processflag)
                # {
                #     Write-Loading -loopflag $False -activitystring "Installing Dell Command Update..."
                #     if (!$processcmd){$processflag = $False}
                # }

                Write-Host "Installing Dell Command Update..." -NoNewline
                Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $dcu_installer_file /qn" -Wait -NoNewWindow 
                Write-Host " Done!"


                Write-Log -String "     DCU installed." -logflag $True
            }

            Write-Host "Configuring Dell Command Update..." -NoNewline
            $dcucli_params | ForEach-Object {
                Start-Process 'C:\Program Files\Dell\CommandUpdate\dcu-cli.exe' -ArgumentList "/configure $_" -Wait -WindowStyle Hidden
                Write-Log -String "     DCU configured: $_" -logflag $True
            }
            Write-Host " Done!"
            
            Start-Process 'C:\Program Files\Dell\CommandUpdate\dcu-cli.exe' -ArgumentList "/configure -secureBiosPassword" -Wait -NoNewWindow

            Write-Host "`nLaunching Dell Command Update..."
            
            # DCU exit codes: https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/command-line-interface-error-codes?guid=guid-fbb96b06-4603-423a-baec-cbf5963d8948&lang=en-us
            $processprintout = Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyupdates -reboot=enable" -Wait -NoNewWindow -PassThru
            $processcode = $processprintout.ExitCode
            Write-Log -string "     Dell Command Update ran succesfully. Exit code: $processcode" -logflag $True

            # 1 - Reboot required to complete update
            if ($processcode -eq "1" ) 
            {
                Write-Log -string "     Exit code 1. Rebooting to finish updates." -logflag $True
                shutdown /r

            }
            
            Write-Log -string "End option 5." -logflag $True
        }

        # 6. Update Zoom
        elseif ($MenuInput -eq "6")
        {
            $zoom_local_version = $get_zoom.zoom_local_version
            $zoom_remote_version = $get_zoom.zoom_remote_version
            $zoom_installer_path1 = $get_zoom.zoom_installer_path1
            $zoom_installer_path2 = $get_zoom.zoom_installer_path2

            Write-Log -string "Begin option 6 - update Zoom client." -logflag $True

            # Installation
            If ($zoom_local_version -lt $zoom_remote_version)
            {   
                Write-Host "Copying installer to local drive... " -NoNewline
                Copy-Item -Path $zoom_installer_path1 -Destination $zoom_installer_path2 -Force
                Write-Host "Done!"
                Write-Log -String "     Installer copied from $zoom_installer_path1 to $zoom_installer_path2" -logflag $True

                Set-Location $wuptemp

                Write-Host "Installing Zoom $zoom_remote_version... " -NoNewline
                Start-Process msiexec -ArgumentList "/i `"$zoom_installer_path2`" /qn" -Wait
                Write-Host "Done!"
                Write-Log -string "     Installed Zoom." -logflag $True

            }
            else
            {
                Write-Warning "No upgrade necessary. Aborting."
                Write-Log -string "     No upgrade necessary. Aborting." -logflag $True
            }

            Write-Log -string "End option 6." -logflag $True
            
            
        }

        # 7. Clean-up
        elseif ($MenuInput -eq "7")
        {
            Write-Log -string "Begin option 7 - clean up / uninstall Dell Command Update." -logflag $True
        
            # Wipe local temp folder
            Write-Log -string "     Checking for temp folder." -logflag $True

            if (Test-Path $wuptemp -PathType Container)
            {
                Write-Log -string "     Temp folder found at $wuptemp." -logflag $True
                Write-Host "Clearing temp folder... " -NoNewline
                try 
                {
                    Remove-Item -Path "$wuptemp\*" -Force -ErrorAction SilentlyContinue -Recurse
                    Write-Host "Done!" 
                    Write-Log -string "     Succesfully wiped contents of $wuptemp."
                }
                catch
                {
                    Write-Host "Finished, with errors."
                    Write-Log -string "        Error deleting items in temp folder. Continuing." -logflag $True
                }
            }
            else
            {
                Write-Log -string "     Temp folder not found." -logflag $True
            }

            # Run DCU check again for updated status within same session
            $get_dellupdate = Get-DellUpdate

            # Uninstall DCU
            Write-Log -string "     Checking for Dell Command Update." -logflag $True

            if (!($get_dellupdate.dcu_test))    
            {
                Write-Log -string "     Dell Command Update does not appear to be installed. Continuing." -logflag $True
            }
            else 
            {
                if (Get-Service -Name "DellClientManagementService") 
                {
                    Write-Host "Killing DellClientManagementService... " -NoNewline
                    try 
                    {
                        Stop-Process (Get-WmiObject Win32_Service -Filter "Name LIKE 'DellClientManagementService'").ProcessId -Force -ErrorAction Stop
                        Write-Host "Done!"
                        Write-Log -string "     Successfully killed DellClientManagementService." -logflag $True
                    }
                    catch 
                    {
                        Write-Host "Finished, with errors."
                        Write-Log -string "        Failed to kill DellClientManagementService. Continuing." -logflag $True
                    }
                }
                
                
                $rkey = $get_dellupdate.dcu_regkey
                
                Write-Host "Uninstalling Dell Command Update... " -NoNewline
                try {
                    Start-Process 'msiexec' -ArgumentList "/x $rkey /qn" -Wait -NoNewWindow
                    Write-Host "Done!" 
                    Write-Log -string "     Succesfully uninstalled Dell Command Update." -logflag $True
                }
                catch 
                {
                    Write-Host "Finished, with errors."
                    Write-Log -string "      Failed to uninstall Dell Command Update." -logflag $True

                }

                
                # Invoke-Command -ScriptBlock {
                #     param $rkey
                #     Start-Process 'msiexec' -ArgumentList '/x $rkey /qn' -Wait -NoNewWindow
                # } -ArgumentList $rkey

                if (Test-Path -Path "C:\Program Files (x86)\Dell\Update\DellUpdate.exe" -PathType Leaf) {
                    Get-ChildItem -Path "C:\Program Files (x86)\Dell\Update\" | Remove-Item -Recurse -Force
                    Remove-Item -Path "C:\Program Files (x86)\Dell\Update\" -Force
                    Write-Log -string "     Deleted orphaned Dell Update folder." -logflag $True

                    if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dell\Update\Dell Update.lnk") 
                    {
                        Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dell\Update\Dell Update.lnk"
                        Write-Log -string "     Deleted orphaned Start Menu link." -logflag $True
                    }
                    
                    else{Write-Log -string "    No orphaned Start Menu link found." -logflag $True}
                }

                Write-Log -string "End option 7." -logflag $True
            }
        } 

        # 8. Rename computer
        elseif ($MenuInput -eq "8")
        {
            Write-Log -string "Begin option 8 - rename computer." -logflag $True
            $nameloop = $True
            $currentname = hostname.exe
            
            while ($nameloop)
            {
                $newname = Read-Host "Enter new name (max 15 char)"
                Write-Log -string "     User input: $newname" -logflag $True

                if ($newname.length -gt 15)                                 {Write-Warning "Max length is 15 characters, try again.`n"}
                elseif ($newname.ToLower() -eq $currentname.ToLower())      {Write-Warning "Same as current name, try again.`n"}
                else                                                        {$nameloop = $False}
                Write-Log -string "     Name loop status: $nameloop" -logflag $True
            }

            $newname_parsed = $newname.ToUpper()

            Write-Log -string "     Renaming computer to $newname_parsed. Auto-restarting." -logflag $True
            Write-Log -string "End option 8." -logflag $True

            Rename-Computer -NewName $newname_parsed -Force -Restart
            
        }


        # q. Quit
        elseif ($MenuInput.ToLower() -eq "q") 
        {
            $flag_global = $False
            Set-Location $workdir
            Write-Log -String "Ending script." -logflag $True
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
    Write-Log -string "|| Script ended cleanly." -logflag $True
}

catch {
    $error_exception = $_.Exception
    $error_line = $_.InvocationInfo.ScriptLineNumber
    $error_message = $error_exception.Message
    $error_script = $MyInvocation.InvocationName
    
    Write-Warning "An error occurred, aborting. See error details at $wuplog.`n"
    Write-Log -string "!! An error occurred in $error_script at line $error_line : $error_message." -logflag $True
    Start-Sleep -Seconds 5
}

