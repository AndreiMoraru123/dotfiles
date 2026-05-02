param(
    [Parameter(Mandatory = $true)]
    [string]$ProcessName,

    [string]$Executable,
    [string]$AppUserModelId
)

$ErrorActionPreference = "SilentlyContinue"

$glazeCli = "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe"

function Launch-Target {
    if ($AppUserModelId) {
        Start-Process explorer.exe "shell:AppsFolder\$AppUserModelId"
        return
    }

    if ($Executable) {
        Start-Process $ExecutionContext.InvokeCommand.ExpandString($Executable)
        return
    }
}

if (Test-Path $glazeCli) {
    $json = & $glazeCli query windows 2>$null
    if ($LASTEXITCODE -eq 0 -and $json) {
        $windows = ($json | ConvertFrom-Json).data.windows
        $match = $windows |
            Where-Object { $_.processName -ieq $ProcessName } |
            Sort-Object @{ Expression = { if ($_.hasFocus) { 0 } else { 1 } } }, title |
            Select-Object -First 1

        if ($match) {
            & $glazeCli command --id $match.id focus --container-id $match.id | Out-Null
            if ($match.state.type -eq "minimized") {
                & $glazeCli command --id $match.id toggle-minimized | Out-Null
            }
            return
        }
    }
}

Launch-Target

