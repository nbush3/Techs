function Uninstall-Application($app) {
    Write-Output "Uninstalling $($app.Name)..."
    $app.Uninstall() | Out-Null
    if ($?) {
        Write-Output "$($app.Name) has been uninstalled successfully."
    } else {
        Write-Output "Failed to uninstall $($app.Name)."
    }
}

# Define the list of Autodesk product names to search for and uninstall
$autodeskProducts = @(
    "AutoCAD",
    "Revit",
    "3ds Max",
    "3dsmax",
    "Maya",
    "Inventor",
    "Navisworks",
    "Civil 3D",
    "Fusion"
)

# Services to stop+delete
@(
    "AdskLicensingService",
    "Autodesk Access Service Host"
) | ForEach-Object {
    if (Get-Service -name $_ -ErrorAction SilentlyContinue) {
        Stop-Process -name $_ -ErrorAction SilentlyContinue -Force
        sc.exe delete $_ > Out-Null
        Write-Output "Removed service $_"
    }
}

# Processes to stop
@(
    "AdskAccessServiceHost",
    "Autodesk Genuine Service",
    "GenuineService",
    "AdSSO",
    "ie4uinit",
    "RevitAccelerator"
) | foreach-object {
    if (get-process -name $_ -erroraction SilentlyContinue)
    {
        Stop-Process -name $_ -force
        Write-Output "Stopped process $_"
    }
}

# Get installed products via WMI
$appwmi = Get-WmiObject -Class Win32_Product

# Uninstall found WMI products
foreach ($product in $autodeskProducts) {
    $uflag = $False
    foreach ($entry in $appwmi) {
        if ($entry.name -match $product) {Uninstall-Application -app $entry; $uflag = $True}
    }
    if ($uflag -eq $False) {Write-Output "No installed application found matching $($product)."}
}

# Delete regkeys
@(
    "HKLM:\Software\Autodesk",
    "HKLM:\Software\WOW6432Node\Autodesk",
    "HKCU:\Software\Autodesk"
) | foreach-object {
    if (Test-Path -Path $_ -ErrorAction SilentlyContinue) {
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
        if ($?) {
            Write-Output "Removed registry key: $_"
        } else {
            Write-Output "Failed to remove registry key: $_"
        }
    }
}

(get-childitem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall").name | foreach-object {
    $nustring = "$_" -replace ("HKEY_LOCAL_MACHINE","HKLM:")
    
    $prop = get-itemproperty $nustring

    $dname = $prop.Displayname

    if (($dname -match "Autodesk") -or ($prop.Publisher -match "Autodesk"))  {
            try {

            Remove-Item $nustring -Force
            write-host "Removed key: $_ for $dname"
            }
            catch {
            Write-Host "Failed removing key: $_ for $dname"
            }
        }

        start-sleep -Seconds 2
}
  


# Folders to delete
@(
    "C:\Program Files\Autodesk",
    "C:\Program Files\Common Files\Autodesk",
    "C:\Program Files\Common Files\Autodesk Shared",
    "C:\Program Files (x86)\Autodesk",
    "C:\Program Files (x86)\Common Files\Autodesk Shared"
    "C:\ProgramData\Autodesk",
    "C:\Autodesk",
    "$env:LocalAppData\Autodesk",
    "$env:AppData\Roaming\Autodesk"
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Autodesk"
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Autodesk Inventor 2023"
) | foreach-object {
    if (Test-Path -Path $_) 
    {
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
        if ($?) {Write-Output "Removed folder: $_"} 
        else {Write-Output "Failed to remove folder: $_"}
    }
}


# CCMcache

Get-ChildItem "C:\Windows\ccmcache" | ForEach-Object {
    $flag = $False
    $gci = (Get-ChildItem "C:\Windows\ccmcache\$_").Name
    $detectedname = ""

    foreach ($product in $autodeskProducts) {
        foreach ($name in $gci) {
            if ($name -match $product) {$flag = $True; $detectedname = $product}
        }
    }

    if ($flag -eq $True) {
        Remove-Item "C:\Windows\ccmcache\$_" -Force -Recurse
        Write-Output "Removed folder: C:\Windows\ccmcache\$_ for $detectedname"
    }
    
}

# Shortcuts to delete
@(
    "C:\Users\Public\Desktop\Autodesk Fusion 360.lnk",
    "C:\Users\Public\Desktop\Autodesk Fusion.lnk"
    "C:\Users\Public\Desktop\Autodesk Inventor Professional 2023.lnk"
    "C:\Users\Public\Desktop\Revit 2023.lnk"
    "C:\Users\Public\Desktop\AutoCAD 2023 - English.lnk"
    "C:\Users\Public\Desktop\3ds Max 2023.lnk"
) | foreach-object {
    if (test-path $_ -ErrorAction SilentlyContinue) 
    {
        remove-item $_ -force
        if ($?) {Write-Output "Removed shortcut: $_"} 
        else {Write-Output "Failed to remove shortcut: $_"}
    }
}

Write-Output "`nAutodesk software removal process completed.`n"