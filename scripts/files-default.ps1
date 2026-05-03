param(
  [ValidateSet('set', 'unset')]
  [string] $Mode = 'set'
)

$ErrorActionPreference = 'Stop'

$filesLocalDir = Join-Path $env:LOCALAPPDATA 'Files'
$filesLauncher = Join-Path $filesLocalDir 'Files.App.Launcher.exe'
$folderOpenKey = 'HKCU:\Software\Classes\Folder\shell\open\command'
$folderExploreKey = 'HKCU:\Software\Classes\Folder\shell\explore\command'
$winEKey = 'HKCU:\Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command'

if ($Mode -eq 'set') {
  $package = Get-AppxPackage -Name FilesPreview
  if (-not $package) {
    throw 'Files Preview is not installed.'
  }

  $packageLauncher = Join-Path $package.InstallLocation 'Assets\FilesOpenDialog\Files.App.Launcher.exe'
  if (-not (Test-Path -LiteralPath $packageLauncher)) {
    throw "Files launcher not found at $packageLauncher"
  }

  New-Item -ItemType Directory -Path $filesLocalDir -Force | Out-Null
  Copy-Item -LiteralPath $packageLauncher -Destination $filesLauncher -Force

  $openCommand = '"%LOCALAPPDATA%\Files\Files.App.Launcher.exe" "%1"'
  $winECommand = '"%LOCALAPPDATA%\Files\Files.App.Launcher.exe"'

  foreach ($key in @($folderOpenKey, $folderExploreKey, $winEKey)) {
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name 'DelegateExecute' -Value '' -PropertyType String -Force | Out-Null
  }

  Set-ItemProperty -Path $folderOpenKey -Name '(default)' -Value $openCommand
  Set-ItemProperty -Path $folderExploreKey -Name '(default)' -Value $openCommand
  Set-ItemProperty -Path $winEKey -Name '(default)' -Value $winECommand

  Write-Host "Files is set as default. Launcher: $filesLauncher"
}
else {
  Remove-Item -Path $folderOpenKey -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -Path $folderExploreKey -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}' -Recurse -Force -ErrorAction SilentlyContinue

  Write-Host 'Files default-file-manager hooks removed.'
}
