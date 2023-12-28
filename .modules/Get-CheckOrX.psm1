function Get-CheckOrX
{
    # If passed $Var -eq $True, return text output with a green checkmark. If passed $Var -eq $False, return text output with a red 'x'. For the purposes of the startup output indicating "correct" values and "incorrect" values.

    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNull()]
        $Var
    )

    $checkmark = ([char]8730)

    $greenforecolor = "$([char]0x1b)[92m"
    $redforecolor = "$([char]0x1b)[91m"
    # $whiteforecolor = "$([char]0x1b)[37m"
    $defaultforecolor = (Get-PSReadLineOption).DefaultTokenColor

    $greenCheck = $greenforecolor + $checkmark + $defaultforecolor
    $redX = $redforecolor + "x" + $defaultforecolor

    if  ($Var -eq $True)    {return $greenCheck}
    else                    {return $redX}
}