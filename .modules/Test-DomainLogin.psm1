function Test-DomainLogin
{
    $username = Read-Host "Enter username"
    $password = Read-Host "Enter password" -AsSecureString
    $domain = "LDAP://" + ([ADSI]"").distinguishedName

    if ((New-Object System.DirectoryServices.DirectoryEntry($domain,$username,(New-Object System.Management.Automation.PSCredential "null", $password).GetNetworkCredential().password)).distinguishedName)     {return $True}
    else                   {return $False}
}