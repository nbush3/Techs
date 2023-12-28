# Import other modules
$moduleroot = $PSScriptRoot
Import-Module -name "$moduleroot\Write-Log.psm1"

function Group-Check
{
    Param ($check_group)
    $check_user = $Env:USERNAME
    $check_flag = $False

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function."
    
    try 
    {
        # Initial check for AD Group Membership, using PowerShell's ActiveDirectory module. Some machines don't have ActiveDirectory installed, may result in errors.
        (Get-ADPrincipalGroupMembership -Identity $check_user | select-object name | sort-object name).getenumerator() | foreach-object {if($_.name -eq $check_group) {$check_flag = $True}}
    }
    catch 
    {
        # Fallback check for AD Group Membership, using cmd's whoami command.
        # Write-Log -String "     Error occurred: " $Error[0]
        whoami /groups /fo csv | convertfrom-csv | foreach-object {if ($_."Group Name" -like "*RCS\$check_group*") {$check_flag = $True}}
    }

    Write-Log -String "End function $current_function."

    return $check_flag
}