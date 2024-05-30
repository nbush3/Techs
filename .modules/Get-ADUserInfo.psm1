function Get-ADUserInfo
{
    <#
    .SYNOPSIS
    Query AD for user properties.

    .DESCRIPTION
    Query Active Directory (AD) using current credentials for the provided username. If username is valid, retrieve several properties from the user's AD object and print to console in a sorted hashtable. Optional flags exist for also displaying AD groups and SCCM "primary" devices.

    .PARAMETER User
    System.Object.String. Username query for in AD.

    .PARAMETER ListGroups
    System.Switch. Assumed false unless declared. Enable to query AD for the user's current groups and list them.

    .PARAMETER ListDevices
    System.Switch. Assumed false unless declared. Enable to query SCCM for the user's "primary" devices and list them.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    PS > Get-ADUserInfo -User "mpowerski"

    Name                           Powerski, Marissa
    AD Path                        rcs.local/Disabled Accounts/Staff/Powerski, Marissa
    DEN number                     111692
    Location                       Administration
    AD Role
    Email                          MPowerski@rochester.k12.mi.us
    Extension
    DID Number
    Mobile Phone
    MiCollab Role

    Account Created                08/16/2021 9:30:09 PM
    Account Modified               05/16/2024 2:35:31 PM

    Enabled in AD                  Disabled
    Disabled Message               Disabled 09/30/23 PJT

    .EXAMPLE
    PS > Get-ADUserInfo -User "kfoutz" -ListDevices

    Name                           Foutz, Kara
    AD Path                        rcs.local/RCS/Staff/Secondary/West/Foutz, Kara
    DEN number                     109759
    Location                       West
    AD Role                        Teacher
    Email                          KFoutz@rochester.k12.mi.us
    Extension                      5004
    DID Number                     2487265004
    Mobile Phone
    MiCollab Role                  stdplus

    Account Created                08/29/2013 11:00:31 PM
    Account Modified               05/19/2024 2:16:16 PM

    Enabled in AD                  Enabled

    Primary Devices                41-21-KFOUTZ

    .EXAMPLE
    PS > Get-ADUserInfo -User "ibushe9771" -ListGroups

    Name                           Ibushe9771
    AD Path                        rcs.local/RCS/Students/2028/Ibushe9771
    DEN number                     219771
    Location
    AD Role
    Email                          ibushe9771@rcs-k12.us
    Extension                      2028
    DID Number
    Mobile Phone
    MiCollab Role

    Account Created                08/01/2018 11:39:53 AM
    Account Modified               05/23/2024 9:10:50 AM

    Enabled in AD                  Enabled

    Group Membership               41-Students
                                   Domain Users
                                   Internet-All-Students
                                   Students-2028
    #> 

    Param
   (
        [Parameter(Mandatory=$true,
        `           Position=0)]
        [ValidateNotNull()]
        $User,

        [switch]$ListGroups,
 
        [switch]$ListDevices

    )

    ForEach ($a in $User)
    {
        $error.clear()
        try {$uprops = Get-ADUser -Identity $a -Properties Name, CanonicalName, EmployeeID, Pager, POBox, EmailAddress, TelephoneNumber, IPPhone, MobilePhone, wWWHomePage, Created, Modified, Enabled, Description}
        catch {return $False}
        
        if (!$error) {
            
            $userarray = [Ordered]@{
                "Name"                  =       $uprops.Name
                "AD Path"               =       $uprops.CanonicalName
                "DEN number"            =       $uprops.EmployeeID
                "Location"              =       $uprops.Pager
                "AD Role"               =       $uprops.POBox
                "Email"                 =       $uprops.EmailAddress
                "Extension"             =       $uprops.TelephoneNumber
                "DID Number"            =       $uprops.IPPhone
                "Mobile Phone"          =       $uprops.MobilePhone
                "MiCollab Role"         =       $uprops.wWWHomePage
                ""                      =       ""
                "Account Created"       =       $uprops.Created
                "Account Modified"      =       $uprops.Modified
                " "                     =       ""
            }

            if      ($uprops.Enabled -eq "True")     {$userarray.Add("Enabled in AD", "Enabled")}
            
            else {
                $userarray.Add("Enabled in AD", "Disabled")
            
                # Search for optional disabled messages in AD accounts that Trevor and Michael often put in
                if      ($uprops.Description -like "*disabled*")     {$userarray.Add("Disabled Message", $uprops.Description)}  
            }

            if ($ListDevices){
                $localdir = Get-Location
                
                Import-Module ConfigurationManager
                Set-Location RCS:
                
                $userarray.Add("  ", "")
                $devices = (Get-CMUserDeviceAffinity -UserName "RCS\$a").ResourceName
                $devicesfinal = ""

                $devices | ForEach-Object {$devicesfinal += "$_`n"}

                $userarray.Add("Primary Devices", $devicesfinal)
            }



            # Optional function parameter for listing user AD groups
            if ($ListGroups){
                
                # Empty key/value pair for readability
                $userarray.Add("   ", "")
                $grpmb = (Get-ADPrincipalGroupMembership -Identity $a | Sort-Object -Property Name).Name
                $groupsfinal = ""
                
                $grpmb | ForEach-Object     {$groupsfinal += "$_`n"}
                $userarray.Add("Group Membership", $groupsfinal)
            }

            # Finally, print the user's hashtable
            $userarray.GetEnumerator() | Format-Table -HideTableHeaders -Wrap
        }
    }
}