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

    Connect-CM

    if ($TestResult)
    {
        Remove-CMDevice -Name $Comp -Force
        Write-Host "Comp deleted from SCCM."
    }
    else    {Write-Host "Comp is not listed in SCCM under this name."}
}

function Test-ADComp
{
    param ($Comp)

    try {
        Get-ADComputer -Identity $Comp > Out-Null
        return $True
    }
    catch {
        return $False
    }
}

function Test-CMComp
{
    param ($Comp)

    Connect-CM

    try {
        if (Get-CMDevice -Name $Comp)   {return $True}
        else                            {return $False}
    }
    catch {
        return $False
    }
}

function Connect-CM
{
    Import-Module ConfigurationManager
    Set-Location RCS:
}

$currentdir = Get-Location

while($True)
{
    $Comp = Read-Host -Prompt "`nEnter comp name"

    $adstatus = Test-ADComp -Comp $Comp
    $cmstatus = Test-CMComp -Comp $Comp

    Write-Host "AD status: $adstatus"
    Write-Host "CM status: $cmstatus"

    if ($adstatus -or $cmstatus)
    {
        $yn = Read-Host -Prompt "`nRemove comp? (y/n)"
        if ($yn.ToLower() -eq "y")
        {
            if ($adstatus) {Remove-ADComp -Comp $Comp -TestResult $adstatus}
            if ($cmstatus) {Remove-CMComp -Comp $Comp -TestResult $cmstatus}   
        }
    }

    Set-Location $currentdir
}