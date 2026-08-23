<#
Merge frontend and backend code into canonical folders.

Usage:
  .\merge-code.ps1         # Dry run (lists planned moves)
  .\merge-code.ps1 -Run   # Execute moves

This script detects likely frontend and backend folders and moves their
source into `frontend/src/` and `backend/src/` respectively. Originals are
archived to `archive/` first. Review the dry run before executing.
#>

param(
  [switch]$Run
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
Set-Location $root

$archive = Join-Path $root 'archive'
$frontendDest = Join-Path $root 'frontend\src'
$backendDest = Join-Path $root 'backend\src'

New-Item -Path $archive -ItemType Directory -Force | Out-Null
New-Item -Path $frontendDest -ItemType Directory -Force | Out-Null
New-Item -Path $backendDest -ItemType Directory -Force | Out-Null

$moves = @()

# Helper: plan a move
function Plan-Move($src, $dest) {
  $moves += [pscustomobject]@{ Src=$src; Dest=$dest }
}

# Detect candidate frontend folders by presence of frontend files
$frontendIndicators = @('package.json','vite.config','router.tsx','index.html','tsconfig.json')
$backendIndicators = @('app.py','models.py','requirements.txt')

Get-ChildItem -Path $root -Directory | ForEach-Object {
  $dir = $_.FullName
  $name = $_.Name

  # Skip canonical destinations and scripts/archive
  if ($name -in @('frontend','backend','supabase','docs','scripts','archive','.git')) { return }

  # Check for frontend indicators
  $isFrontend = $false
  foreach ($f in $frontendIndicators) { if (Test-Path (Join-Path $dir $f)) { $isFrontend = $true; break } }

  # Check for backend indicators
  $isBackend = $false
  foreach ($b in $backendIndicators) { if (Test-Path (Join-Path $dir $b)) { $isBackend = $true; break } }

  if ($isFrontend) {
    # Prefer moving `src` folder if present, else move whole folder contents
    $srcFolder = Join-Path $dir 'src'
    if (Test-Path $srcFolder) {
      $dest = Join-Path $frontendDest $name
      Plan-Move $srcFolder $dest
    } else {
      $dest = Join-Path $frontendDest $name
      Plan-Move $dir $dest
    }
    return
  }

  if ($isBackend) {
    $srcFolder = Join-Path $dir 'src'
    if (Test-Path $srcFolder) { $dest = Join-Path $backendDest $name; Plan-Move $srcFolder $dest }
    else { $dest = Join-Path $backendDest $name; Plan-Move $dir $dest }
    return
  }

  # Special-case: root 'src' directory (common in this repo)
  if ($name -eq 'src') {
    Plan-Move $dir (Join-Path $frontendDest 'root-src')
  }
}

if (-not $moves) { Write-Host "No code folders detected for merging."; exit 0 }

Write-Host "Planned code moves:`n"
$moves | ForEach-Object { Write-Host "`t$($_.Src) -> $($_.Dest)" }

if (-not $Run) { Write-Host "`nDry run complete. Re-run with -Run to perform moves." -ForegroundColor Yellow; exit 0 }

foreach ($m in $moves) {
  $src = $m.Src; $dest = $m.Dest
  $basename = Split-Path $src -Leaf
  $archivePath = Join-Path $archive ($basename + '_' + [System.Guid]::NewGuid().ToString())
  Write-Host "Archiving $src -> $archivePath"
  Move-Item -Path $src -Destination $archivePath -Force -Verbose
  Write-Host "Moving archived copy to canonical location: $archivePath -> $dest"
  New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
  Move-Item -Path $archivePath -Destination $dest -Force -Verbose
}

Write-Host "Merge complete. Review moved code under 'frontend/src' and 'backend/src', originals in 'archive'." -ForegroundColor Green
