$moduleroot = $PSScriptRoot
Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-BIOS
{

    Param
    (
        $wuproot,
        $model,
        $logflag
    )

    # WMI check for current BIOS version

    # Check for model number via WMI, then determine the BIOS exe file to run as well as the file's BIOS version

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    $bios_current = (Get-WmiObject Win32_BIOS).Name
    Write-Log -String "     Current BIOS version: $bios_current" -logflag $logflag
    Write-Log -String "     Model: $model" -logflag $logflag
    
    $bios_model_folder = $wuproot+"bios\"+$model
    Write-Log -String "     Presumed BIOS folder path for this model computer: $bios_model_folder" -logflag $logflag
    
    If (Test-Path $bios_model_folder -PathType Container){
        Write-Log -String "     BIOS folder found." -logflag $logflag


        if ($model -eq "Latitude 3380"){
            $bios_exe = "Latitude_3380_*.exe"
            $delim = 2
        }
        elseif ($model -eq "Latitude 5400"){
            $bios_exe = "Latitude_5X00_Precision_3540_*.exe"
            $delim = 4
        }
        elseif ($model -eq "Latitude 5480"){
            $bios_exe = "Latitude_5X80_Precision_3520_*.exe"
            $delim = 4
        }
        elseif($model -eq "Latitude 5520"){
            $bios_exe = "Precision_3560_Latitude_5520_*.exe"
            $delim = 4
        } 
        elseif($model -eq "Latitude 9520"){
            $bios_exe = "Latitude_9520_*.exe"
            $delim = 2
        } 
        elseif($model -eq "OptiPlex 3060"){
            $bios_exe = "OptiPlex_3060_*.exe"
            $delim = 2
        }
        elseif($model -eq "Optiplex 3070"){
            $bios_exe = "OptiPlex_3070_*.exe"
            $delim = 2
        }
        elseif($model -eq "Optiplex 3090"){
            $bios_exe = "OptiPlex_3090_*.exe"
            $delim = 2
        }
        elseif($model -eq "Optiplex 3090 UFF"){
            $bios_exe = "OptiPlex_3090_UFF_*.exe"
            $delim = 3
        }
        elseif($model -eq "Precision 5820 Tower X-Series"){
            $bios_exe = "M33X_*.exe"
            $delim = 1
        }
        elseif($model -eq "Precision 3680 Tower"){
            $bios_exe = "Precision_3680_*.exe"
            $delim = 2
        }

        Write-Log -String "     BIOS exe filename template: $bios_exe" -logflag $logflag
        Write-Log -String "     BIOS exe filename delimeter value: $delim" -logflag $logflag
        
        $bios_path = "$wuproot"+"bios\$model\$bios_exe"
        Write-Log -String "     BIOS exe filename path: $bios_path" -logflag $logflag

        If (Test-Path $bios_path -PathType Leaf){
            Write-Log -String "     BIOS exe file path is valid." -logflag $logflag

            $bios_upg = (((Get-ChildItem $bios_path).BaseName) -Split "_")[$delim]
            Write-Log -String "     BIOS exe file version (based on current filename): $bios_upg" -logflag $logflag
        }
        else {
            Write-Log -String "     BIOS exe file path is not valid. Setting BIOS exe file version and path to null." -logflag $logflag
            $bios_upg = $null
            $bios_path = $null
        }
        
    }
    else {
        Write-Log -String "     BIOS folder not found. Setting BIOS exe file name, path and version to null." -logflag $logflag
        $bios_upg = $null
        $bios_path = $null
        $bios_exe = $null
    }



    if ($bios_upg) {
        if  ([System.Version]$bios_current -ge [System.Version]$bios_upg)      {$bios_checkorx = Get-CheckOrX -Var $True}
        else            {$bios_checkorx = Get-CheckOrX -Var $False}
    }
    
    else                {$bios_checkorx = Get-CheckOrX -Var $False}


    $bios_string = $bios_checkorx + ' ' + $bios_current

    $bios_return = @{
        "bios_upg"          =       $bios_upg
        "bios_path"         =       $bios_path
        "bios_exe"          =       $bios_exe
        "bios_string"       =       $bios_string
        "bios_current"      =       $bios_current
    }

    Write-Log -String "End function $current_function." -logflag $logflag

    return $bios_return


}