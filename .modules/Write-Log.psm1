function Write-Log
{
    Param
    (
        [Parameter(Mandatory=$false,
                   Position=0)]
        [ValidateNotNull()]
        $string,

        [Parameter(Mandatory=$false,
                   Position=0)]
        [ValidateNotNull()]
        $hashtable
    )

    $wuplog = "$env:TEMP\wup.log"
    $getdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ($string){"$getdate   $string" | Out-File -FilePath $wuplog -Append}
    elseif ($hashtable)
    {
        $hashtable.GetEnumerator() | ForEach-Object{

            if (!($_.Key -like "*string*")) {
                $logstring = "         " + $_.Key + ': ' + $_.Value.trim()
            }

            # Remove unicode check/x strings
            if ($_.Value -like "*33m*" -or $_.Value -like "*37m*") {
                $tempstring = $_.Value.split(' ')
                $first, $rest= $tempstring
                $logstring = "         " + $_.Key + ': ' + $rest.trim()
            }

            # Remove blank k/v pair (used for clean host printout)
            if (!($logstring.trim() -eq ":")){
                "$getdate   $logstring" | Out-File -FilePath $wuplog -Append
            }
        }
    }
}