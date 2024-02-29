function Write-Loading 
{
    <#
    .SYNOPSIS
        Writes a string to console along with a loading bar, for continuous processes.
    .EXAMPLE
        Create a process to feed into it first:
        PS > $process = start-process "notepad.exe" -PassThru
        Now call the function:
        PS > Write-Loading -ActivityString "Running Notepad..." -Process $process
    #>

    Param ($ActivityString, $Process)

    $cursorX = ($ActivityString.length) + 1
    $cursorY = ($host.UI.RawUI.CursorPosition).Y

    $loopflag = $True
    
    Write-Host $ActivityString -NoNewline


    while ($loopflag)
    {
        $processactive = get-process $process.Id -erroraction silentlycontinue

        if ($null -ne $processactive)
        {
            for ($counter = 1; $counter -lt 5; $counter++)
            {
                if      ($counter -eq 1)     {$echo = "\"}
                elseif  ($counter -eq 2)     {$echo = "|"}
                elseif  ($counter -eq 3)     {$echo = "/"}
                elseif  ($counter -eq 4)     {$echo = "-"}
                
                Write-Host -NoNewLine "`r"; $host.UI.RawUI.CursorPosition = @{X = $cursorX; Y = $cursorY}; Write-Host "$echo" -NoNewline
                Start-Sleep -Milliseconds 750
            }
        }
        else 
        {
            $loopflag = $False
            $host.UI.RawUI.CursorPosition = @{X = $cursorX; Y = $cursorY}
            Write-Host "Done!"
        }
    }
}