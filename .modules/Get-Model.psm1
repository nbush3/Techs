function Get-Model
{
    # WMI check for model name

    $model = (Get-WmiObject Win32_ComputerSystem).Model
    
    $model_return = @{
        "model" = $model
        "model_string" = '  ' + $model
    }
    
    return $model_return
}
