function Clear-PhoneInfo
{

    Param
   (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $User
 
    )

    Set-ADUser -Identity $User -Clear TelephoneNumber, ipPhone, wWWHomePage, mobile, postOfficeBox

}