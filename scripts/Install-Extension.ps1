[CmdletBinding()]
param(
    [string]$VsixPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw -Path (Join-Path $projectRoot 'package.json') | ConvertFrom-Json
$expectedExtension = "$($manifest.publisher).$($manifest.name)@$($manifest.version)"

if (-not $VsixPath) {
    $VsixPath = Get-ChildItem -Path (Join-Path $projectRoot 'dist') -Filter '*.vsix' -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName
}

if (-not $VsixPath -or -not (Test-Path -LiteralPath $VsixPath -PathType Leaf)) {
    throw 'No VSIX was found. Run .\scripts\Build-Extension.ps1 first, or pass -VsixPath.'
}

& code --install-extension $VsixPath --force
if ($LASTEXITCODE -ne 0) {
    throw "VS Code extension installation failed with exit code $LASTEXITCODE."
}

$installedExtensions = & code --list-extensions --show-versions
if ($LASTEXITCODE -ne 0) {
    throw "VS Code extension verification failed with exit code $LASTEXITCODE."
}

if ($installedExtensions -notcontains $expectedExtension) {
    throw "Expected $expectedExtension after installation, but VS Code did not report it."
}

Write-Host "Installed $expectedExtension from $VsixPath"
Write-Host 'Reload the VS Code window to refresh the extension publisher metadata and icon.'