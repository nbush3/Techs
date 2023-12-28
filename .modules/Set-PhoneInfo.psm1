function Set-PhoneInfo
{

    Param
   (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $ParamBlock
    )  

    $identity = $ParamBlock.identity
    $ParamBlock2 = $ParamBlock.clone()
    $ParamBlock2.Remove("identity")
    $ParamBlock.GetEnumerator() | ForEach-Object {
        # . (period) = Wipe existing value
        if      ($_.Value.Trim() -eq '.')       {
            Set-ADUser -Identity $identity -Clear $_.Key
            $ParamBlock2.Remove($_.Key)
        }
        
        # null = Do not set value
        elseif  ($_.Value.Trim() -eq '')        {
            $ParamBlock2.Remove($_.Key)
        }
    }

    $ParamBlock2.GetEnumerator() | ForEach-Object {
        # In order to reliably set custom properties in AD, we must wipe it first if it has any value, so that we're performing the same "replace" action every time regardless of the existing value
        if ($null -ne (Get-ADUser -Identity $ParamBlock.identity -Properties $_.Key).($_.Key)){
            Set-ADUser -Identity $ParamBlock.identity -Clear $_.Key
        }
        
        Set-ADUser -Identity $ParamBlock.identity -replace @{$_.Key = $_.Value}
    }
}