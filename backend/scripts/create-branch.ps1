param(
  [string]$Type = 'FRONTEND',
  [string]$Title = 'feature'
)

$dt = Get-Date -Format 'yyyy-MM-dd'
$day = (Get-Date).DayOfWeek.ToString().ToUpper()
$branch = "$dt`_$day`_$Type`_$Title"

Write-Host "Creating branch: $branch"
git checkout -b $branch
if ($LASTEXITCODE -ne 0) { Write-Error "git checkout failed"; exit 1 }
Write-Host "Branch created and checked out: $branch"
