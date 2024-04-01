function Get-ADUserInfo
{

    Param
   (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $User,

        [switch]$ListGroups,
 
        [switch]$ListDevices

    )

    ForEach ($a in $User)
    {
        $error.clear()
        try {$uprops = Get-ADUser -Identity $a -Properties * | Select-Object Name, CanonicalName, EmployeeID, Pager, POBox, EmailAddress, TelephoneNumber, IPPhone, MobilePhone, wWWHomePage, Created, Modified, Enabled, Description}
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