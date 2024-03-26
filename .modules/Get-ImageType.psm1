# Import other modules
$moduleroot = $PSScriptRoot
Import-Module -name "$moduleroot\Get-Name.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"
Import-Module -name "$moduleroot\Write-Log.psm1"

function Get-ImageType
{
    # Determine the "image type" ("Staff" vs "Student") based on the presence of Outlook. Further, determine if that's "correct" or "incorrect" based on hostname formatting.

    Param ( $logflag )

    $current_function = $MyInvocation.InvocationName

    Write-Log -String "Begin function $current_function." -logflag $logflag


    $tcomp_suffix = @("AD", "AL", "TD", "TL")
    $scomp_suffix = @("SD", "SL")
    $tcomp_midfix = @("21", "LTSUB", "INTERN", "NTO", "PREK", "SPARE", "STEACHER", "TECHLOAN", "TA")
    $scomp_midfix = @("YEARBOOK")
    $tflag = $False
    $sflag = $False


    $hostname = (Get-Name).name
    Write-Log -String "     Hostname: $hostname" -logflag $logflag
    
    $outlook_path = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
    $outlook_valid = Test-Path $outlook_path -PathType Leaf
    Write-Log -String "Looking for OUTLOOK.EXE at $outlook_path" -logflag $logflag


    if ($outlook_valid) {
        $image_type = "Staff Image"
        
        $tcomp_suffix | ForEach-Object {if ($hostname.name -like "*-$_*")     {$tflag = $True}}
        $tcomp_midfix | ForEach-Object {if ($hostname.name -like "*-$_-*")     {$tflag = $True}}

        if ($tflag)      {$image_checkorx = Get-CheckOrX -Var $True}
        else {
            $scomp_suffix | ForEach-Object {if ($hostname.name -like "*-$_*")     {$sflag = $True}}
            $Scomp_midfix | ForEach-Object {if ($hostname.name -like "*-$_-*")     {$sflag = $True}}

            if ($sflag)     {$image_checkorx = Get-CheckOrX -Var $False}
            else {$image_type = " Staff Image"}
        }

    }
    else {
        $image_type = "Student Image"
        $scomp_suffix | ForEach-Object {if ($hostname.name -like "*-$_*")     {$sflag = $True}}
        $Scomp_midfix | ForEach-Object {if ($hostname.name -like "*-$_-*")     {$sflag = $True}}
        if ($sflag)      {$image_checkorx = Get-CheckOrX -Var $True}
        else {
            $tcomp_suffix | ForEach-Object {if ($hostname.name -like "*-$_*")     {$tflag = $True}}
            $tcomp_midfix | ForEach-Object {if ($hostname.name -like "*-$_-*")     {$tflag = $True}}
            if ($tflag)     {$image_checkorx = Get-CheckOrX -Var $False}  
        }
    }

    $image_string = $image_checkorx + ' ' + $image_type

    $image_return = @{
        "image_type"        =       $image_type
        "image_string"      =       $image_string
    }

    Write-Log -String "End function $current_function." -logflag $logflag

    return $image_return

}