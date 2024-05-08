function Request-YesNo
{
    param(
        [Parameter(Position=0,Mandatory)]
                $Prompt
    )

    $input_text = (Read-Host "$Prompt (y/n)").Trim().ToLower()
    $input_loop = $True

    while ($input_loop)
    {
        if ($input_text -eq "y") {$input_loop = $False; return $True}
        elseif ($input_text -eq "n") {$input_loop = $False; return $False}
        else {$input_text = (Read-Host "Invalid input. Try again").Trim().ToLower()}
    }
}