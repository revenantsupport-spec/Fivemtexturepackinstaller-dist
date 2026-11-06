# FiveM Mod Installer - one-line bootstrap:
#   irm https://raw.githubusercontent.com/revenantsupport-spec/Fivemtexturepackinstaller-dist/main/install.ps1 | iex
# Source lives in the private Fivemtexturepackinstaller repo; this script and the
# exe releases are distributed from the public Fivemtexturepackinstaller-dist repo.

param(
    [string]$SourceUrl = "",   # test seam: override the download URL
    [switch]$NoLaunch        # test seam: install without starting the app
)

$ErrorActionPreference = "Stop"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$Repo       = "revenantsupport-spec/Fivemtexturepackinstaller-dist"
$InstallDir = Join-Path $env:LOCALAPPDATA "FiveMModInstaller"
$Dest       = Join-Path $InstallDir "FiveMModInstaller.exe"
$Shortcut   = Join-Path ([Environment]::GetFolderPath("Desktop")) "FiveM Mod Installer.lnk"

$Url = if ($SourceUrl -ne "") { $SourceUrl }
       else { "https://github.com/$Repo/releases/latest/download/FiveMModInstaller.exe" }

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }

Write-Step "Downloading FiveM Mod Installer"
try {
    $tmp = Join-Path $env:TEMP "FiveMModInstaller_download.exe"
    Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing
    if ((Get-Item $tmp).Length -lt 1024) { throw "downloaded file looks too small to be the app" }
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Move-Item -LiteralPath $tmp -Destination $Dest -Force
} catch {
    Write-Host ""
    Write-Host "Could not download the installer from:" -ForegroundColor Red
    Write-Host "  $Url" -ForegroundColor Red
    Write-Host "Check your internet connection, and that a Release with FiveMModInstaller.exe exists on $Repo." -ForegroundColor Red
    if (Test-Path (Join-Path $env:TEMP "FiveMModInstaller_download.exe")) {
        Remove-Item (Join-Path $env:TEMP "FiveMModInstaller_download.exe") -Force -ErrorAction SilentlyContinue
    }
    exit 1
}
Write-Ok "Installed to $Dest"

Write-Step "Creating Desktop shortcut"
$ws  = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut($Shortcut)
$lnk.TargetPath      = $Dest
$lnk.WorkingDirectory = $InstallDir
$lnk.Description     = "FiveM Mod Installer (Texture Pack, BloodFX, Tracers, KillFX)"
$lnk.Save()
Write-Ok $Shortcut

if (-not $NoLaunch) {
    Write-Step "Launching"
    Start-Process -FilePath $Dest -WorkingDirectory $InstallDir
    Write-Ok "FiveM Mod Installer is running"
}

Write-Host ""
Write-Host "First run only: Windows SmartScreen may ask about the unsigned exe -" -ForegroundColor Yellow
Write-Host "click 'More info' -> 'Run anyway'." -ForegroundColor Yellow
Write-Host "Your settings and uninstall records live in $InstallDir and survive reinstalls." -ForegroundColor Gray
