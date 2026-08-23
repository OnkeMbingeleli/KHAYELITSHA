param(
  [switch]$Run
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
Set-Location $root

$planned = @()

Get-ChildItem -Path $root -File | ForEach-Object {
  $f = $_
  switch -Wildcard ($f.Extension.ToLower()) {
    '.py' { $planned += [pscustomobject]@{ Src=$f.FullName; Dest=(Join-Path $root 'backend\scripts\' + $f.Name) } }
    '.html' { $planned += [pscustomobject]@{ Src=$f.FullName; Dest=(Join-Path $root 'frontend\public\' + $f.Name) } }
    '.txt' { $planned += [pscustomobject]@{ Src=$f.FullName; Dest=(Join-Path $root 'docs\notes\' + $f.Name) } }
    '.md' { if ($f.Name -ne 'README.md') { $planned += [pscustomobject]@{ Src=$f.FullName; Dest=(Join-Path $root 'docs\notes\' + $f.Name) } } }
    default { } 
  }
}

if (-not $planned) { Write-Host 'No top-level files detected for planned moves.'; exit 0 }

Write-Host 'Planned root file moves:`n'
$planned | ForEach-Object { Write-Host "`t$($_.Src) -> $($_.Dest)" }

if (-not $Run) { Write-Host "`nDry run complete. Re-run with -Run to execute." -ForegroundColor Yellow; exit 0 }

New-Item -ItemType Directory -Path (Join-Path $root 'backend\scripts') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'frontend\public') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'docs\notes') -Force | Out-Null

foreach ($m in $planned) {
  Write-Host "Moving: $($m.Src) -> $($m.Dest)"
  Move-Item -Path $m.Src -Destination $m.Dest -Force -Verbose
}

Write-Host 'Root moves complete.' -ForegroundColor Green
