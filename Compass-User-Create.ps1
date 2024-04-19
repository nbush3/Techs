$array = @()
$badarray = @()
$compcount = 33
$compprefix = "50-21-B123-SD"


# Enumerate compname array
for ($i = 1; $i -le $compcount; $i++)
{
    $num = '{0:d2}' -f $i
    $entry = $compprefix + $num.ToString()
    $array += $entry
}

# Enter PS-Session for each comp and create user
foreach ($comp in $array)
{
    if (Test-Connection $comp -ErrorAction SilentlyContinue -Count 1)
    {
        $s = New-PSSession -ComputerName $comp

        Invoke-Command -session $s -ScriptBlock {
            net user "Compass" "Compass" /expire:"05/01/2024" /add /active:no
            net localgroup "Administrators" "Compass" /add
            
        }

        Exit-PSSession
    }

    # Store comps that couldn't be reached for output
    else
    {
        $badarray += $comp
    }
}

write-host "Comps that couldn't be reached:"
$badarray