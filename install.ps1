# Download the GitHub checker, run diagnostics, and open the local HTML report.
param([string]$Repo='mshekharee/readiness-checker',[string]$Ref='main')
$ErrorActionPreference='Stop'
if($Repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or $Ref -notmatch '^[A-Za-z0-9._/-]+$' -or $Ref.Contains('..')){throw 'Invalid repository or ref'}
$tmp=Join-Path ([IO.Path]::GetTempPath()) ('pairing-'+[guid]::NewGuid().ToString())
$destination=Join-Path $HOME '.pairing-readiness-checker'
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
 $archive=Join-Path $tmp 'checker.zip'
 $url="https://github.com/$Repo/archive/refs/heads/$Ref.zip"
 Write-Host "Downloading $Repo ($Ref) ..."
 Invoke-WebRequest -Uri $url -OutFile $archive -TimeoutSec 90
 Expand-Archive -Path $archive -DestinationPath (Join-Path $tmp 'src') -Force
 $folder=Get-ChildItem (Join-Path $tmp 'src') -Directory | Select-Object -First 1
 if(!$folder -or !(Test-Path (Join-Path $folder.FullName 'readiness.ps1')) -or !(Test-Path (Join-Path $folder.FullName 'report.html'))){throw 'Archive missing checker files'}
 New-Item -ItemType Directory -Path $destination -Force | Out-Null
 Copy-Item (Join-Path $folder.FullName 'readiness.ps1'),(Join-Path $folder.FullName 'report.html') -Destination $destination -Force
 Write-Host 'Running local system checks...'
 & (Join-Path $destination 'readiness.ps1')
 Write-Host "Report files: $destination"
} finally {Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue}
