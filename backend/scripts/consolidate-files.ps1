<#
Consolidation script (dry-run by default).

Usage:
  .\consolidate-files.ps1          # Dry run: shows planned moves
  .\consolidate-files.ps1 -Run    # Execute moves

This script moves common top-level SQL and documentation files into
canonical folders (supabase/migrations, docs/*) and archives originals.
Back up or run the dry run before applying.
#>

param(
  [switch]$Run
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Repository root is parent of scripts folder (assumes scripts/ is directly under repo root)
$root = Split-Path -Parent $scriptDir
Set-Location $root

$archive = Join-Path $root 'archive'
$supabaseMigs = Join-Path $root 'supabase\migrations'
$docs = Join-Path $root 'docs'
$proposals = Join-Path $docs 'proposals'
$databaseDocs = Join-Path $docs 'database'

# Create folders
New-Item -Path $archive -ItemType Directory -Force | Out-Null
New-Item -Path $supabaseMigs -ItemType Directory -Force | Out-Null
New-Item -Path $docs -ItemType Directory -Force | Out-Null
New-Item -Path $proposals -ItemType Directory -Force | Out-Null
New-Item -Path $databaseDocs -ItemType Directory -Force | Out-Null

Write-Host "Consolidation script - Run mode: $Run"

$moves = @()

# Move top-level SQL files into supabase/migrations
Get-ChildItem -Path $root -Filter *.sql -File | ForEach-Object {
  $src = $_.FullName
  $dest = Join-Path $supabaseMigs $_.Name
  $moves += [pscustomobject]@{ Src = $src; Dest = $dest }
}

# Move proposal and system docs
$proposalPatterns = @('KUWAIT_BRANCH_SYSTEM_PROPOSAL.md','SYSTEM_GUIDE.md','QUICK_START.md','TaxiSystemRequirements.md')
foreach ($p in $proposalPatterns) {
  $f = Join-Path $root $p
  if (Test-Path $f) { $moves += [pscustomobject]@{ Src = $f; Dest = Join-Path $proposals (Split-Path $p -Leaf) } }
}

# Move other top-level md files (except README.md) into docs/database if they look like DB guides
Get-ChildItem -Path $root -Filter *.md -File | Where-Object { $_.Name -ne 'README.md' -and $_.Name -notin $proposalPatterns } | ForEach-Object {
  $dest = Join-Path $databaseDocs $_.Name
  $moves += [pscustomobject]@{ Src = $_.FullName; Dest = $dest }
}

if (-not $moves) { Write-Host "No files detected for consolidation."; exit 0 }

Write-Host "Planned moves:`n"
$moves | ForEach-Object { Write-Host "`t$($_.Src) -> $($_.Dest)" }

if (-not $Run) {
  Write-Host "`nDry run complete. Re-run with -Run to execute moves." -ForegroundColor Yellow
  exit 0
}

foreach ($m in $moves) {
  $destDir = Split-Path $m.Dest -Parent
  if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
  $archivePath = Join-Path $archive (Split-Path $m.Src -Leaf)
  Write-Host "Archiving $($m.Src) -> $archivePath"
  Move-Item -Path $m.Src -Destination $archivePath -Force -Verbose
  Write-Host "Moving archived copy to canonical location: $archivePath -> $($m.Dest)"
  Move-Item -Path $archivePath -Destination $m.Dest -Force -Verbose
}

Write-Host "Consolidation complete. Review files in 'archive' and 'docs'/'supabase/migrations'." -ForegroundColor Green
