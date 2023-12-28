# Import other modules
$moduleroot = $PSScriptRoot
Import-Module -name "$moduleroot\Write-Log.psm1"
Import-Module -name "$moduleroot\Get-CheckOrX.psm1"

function Get-Asset
{
    # WMI check for BIOS asset tag field

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function."

    # Use regex to remove leading 0's from asset tag
    $asset_unparsed = ((Get-WmiObject -Class Win32_SystemEnclosure).SMBIOSAssetTag).Trim()
    $asset_parsed = $asset_unparsed -replace '^0{0,8}'

    Write-Log -String "     BIOS asset tag: $asset_unparsed"
    Write-Log -String "     BIOS asset tag (regex'ed): $asset_parsed"
    
    if ($asset_parsed)
    {
        $asset_checkorx = Get-CheckOrX -Var $True
        Write-Log -String "Asset tag exists. Get-CheckOrX Value is 'check'."
    }
    else
    {
        $asset_checkorx = Get-CheckOrX -Var $False
        Write-Log -String "Asset tag does not exist. Get-CheckOrX Value is 'x'."
        if ($asset_unparsed = "(all 0's)") {$asset_parsed = $asset_unparsed}
        elseif ($asset_unparsed = "") {$asset_parsed = "(blank)"}
    }

    $asset_string = $asset_checkorx + ' ' + $asset_parsed

    $asset_return = @{
        "asset_unparsed"        =       $asset_unparsed
        "asset_parsed"          =       $asset_parsed
        "asset_string"          =       $asset_string
    }

    Write-Log -String "End function $current_function."

    return $asset_return

}