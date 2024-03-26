function Write-Log
{
    Param
    (
        $string,
        $list,
        $hashtable,
        $logflag
    )

    if ($logflag)
    {
        $wuplog = "$env:TEMP\wup.log"
        $getdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $indent = "                                   "

        if  ($string)   {"$getdate   $string" | Out-File -FilePath $wuplog -Append}
        elseif ($list)  {$list | ForEach-Object {$indent + $_ | Out-File -FilePath $wuplog -Append}}
        elseif ($hashtable)
        {
            $hashtable.GetEnumerator() | ForEach-Object {

                # Strip unicode check/x strings from *_string variables (won't translate correctly in logs)
                if ($_.Value -like "*33m*" -or $_.Value -like "*37m*") 
                {
                    $tempstring = $_.Value.split(' ')
                    $first, $rest= $tempstring
                    $logstring = $indent + $_.Key + ': ' + $rest.trim()
                }
                
                # For everything else
                else
                {
                    $logstring = $indent + $_.Key + ': ' + $_.Value.trim()
                }

                # Remove blank k/v pairs (used for clean host printout)
                if (!($logstring.trim() -eq ":"))
                {
                    "   $logstring" | Out-File -FilePath $wuplog -Append
                }
            }
        }
    }
}