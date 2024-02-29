function Write-Loading 
{
    Param ($activitystring, $loopflag)

    $cursorX = ($activitystring.length) + 1
    $cursorY = ($host.UI.RawUI.CursorPosition).Y

    $loopflag = $True
    
    Write-Host $activitystring -NoNewline


    while ($loopflag)
    {
        $processactive = get-process $process.ProcessName -erroraction silentlycontinue

        if ($null -ne $processactive)
        {
            for ($counter = 1; $counter -lt 5; $counter++)
            {
                if      ($counter -eq 1)     {$echo = "\"}
                elseif  ($counter -eq 2)     {$echo = "|"}
                elseif  ($counter -eq 3)     {$echo = "/"}
                elseif  ($counter -eq 4)     {$echo = "-"}
                
                write-host -NoNewLine "`r"; $host.UI.RawUI.CursorPosition = @{X = $cursorX; Y = $cursorY}; write-host "$echo" -NoNewline
                start-sleep -Milliseconds 750
            }
        }
        else {$loopflag = $False}
    }
}