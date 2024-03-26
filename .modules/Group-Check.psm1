# Import other modules
$moduleroot = $PSScriptRoot
Import-Module -name "$moduleroot\Write-Log.psm1"

function Group-Check
{
    Param ($check_group, $logflag)
    $check_user = $Env:USERNAME
    $check_flag = $False

    $current_function = $MyInvocation.InvocationName
    Write-Log -String "Begin function $current_function." -logflag $logflag

    Write-Log -String "     Checking if $check_user is a member of $check_group." -logflag $logflag

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

    Write-Log -String "     Group check status: $check_flag" -logflag $logflag

    Write-Log -String "End function $current_function." -logflag $logflag

    return $check_flag
}