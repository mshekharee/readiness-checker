# Pairing readiness (Windows PowerShell). No installs or elevated permissions.
$ErrorActionPreference='SilentlyContinue'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$items=New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Id,[string]$Status,[string]$Detail){ $items.Add(@{id=$Id; status=$Status; detailB64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Detail))}) }
Add-Check 'os' 'pass' "Windows / $($env:PROCESSOR_ARCHITECTURE)"
try { $f=Join-Path ([IO.Path]::GetTempPath()) ("pairing-"+[guid]::NewGuid().ToString()+'.tmp'); 'test' | Set-Content $f -ErrorAction Stop; $r=Get-Content $f -ErrorAction Stop; Remove-Item $f -ErrorAction SilentlyContinue; if($r -eq 'test'){Add-Check 'permissions' 'pass' 'Temporary workspace can be created and written'}else{Add-Check 'permissions' 'fail' 'Workspace test failed'} }catch{Add-Check 'permissions' 'fail' "Cannot write temporary workspace: $($_.Exception.Message)"}
$docker=Get-Command docker -ErrorAction SilentlyContinue
if(!$docker){Add-Check 'docker' 'fail' 'Docker CLI not found. Install or enable Docker Desktop.'}
else {
 $v=(& docker --version 2>&1 | Out-String).Trim()
 $out=(& docker info --format '{{.ServerVersion}}' 2>&1 | Out-String).Trim()
 if($LASTEXITCODE -eq 0){Add-Check 'docker' 'pass' "Docker installed and engine running ($v; engine $out)"}
 else{Add-Check 'docker' 'fail' "Docker CLI present ($v) but engine inaccessible. Start Docker Desktop and retry. $($out.Substring(0,[Math]::Min(250,$out.Length)))"}
}
$git=Get-Command git -ErrorAction SilentlyContinue
if($git){$v=(& git --version 2>&1 | Out-String).Trim();Add-Check 'git' 'pass' $v}else{Add-Check 'git' 'fail' 'Git not found on PATH'}
$langs=@('python','python3','go','ruby','node','java','dotnet') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
if($langs.Count){Add-Check 'language' 'pass' ('Available runtimes: '+($langs -join ', '))}else{Add-Check 'language' 'unknown' 'No supported language runtime found on PATH'}
$edit=@('code','codium','vim','nvim','notepad','notepad++','subl') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
$apps=@("$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe", "$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:ProgramFiles\JetBrains") | Where-Object { Test-Path $_ }
if($edit.Count -or $apps.Count){Add-Check 'editor' 'pass' ('Detected editor(s): '+(($edit+$apps) -join ', '))}else{Add-Check 'editor' 'unknown' 'No known editor detected; GUI-only installations may be missed'}
try { $response=Invoke-WebRequest -Uri 'https://github.com' -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop; Add-Check 'network' 'pass' "GitHub reachable (HTTP $([int]$response.StatusCode))" }catch{Add-Check 'network' 'fail' 'GitHub cannot be reached over HTTPS'}
if(Get-Command kubectl -ErrorAction SilentlyContinue){$null=& kubectl cluster-info --request-timeout=5s 2>&1; if($LASTEXITCODE -eq 0){Add-Check 'k8s' 'pass' 'Kubernetes cluster reachable (optional)'}else{Add-Check 'k8s' 'unknown' 'No reachable Kubernetes cluster (optional)'}}else{Add-Check 'k8s' 'unknown' 'kubectl not found (optional)'}
$js='window.REPORT_ITEMS = '+($items | ConvertTo-Json -Depth 5 -Compress)+';'+[Environment]::NewLine+'window.REPORT_GENERATED_AT = '+((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')|ConvertTo-Json)+';'
[IO.File]::WriteAllText((Join-Path $root 'results.js'),$js,[Text.UTF8Encoding]::new($false))
Write-Host 'Readiness diagnostics complete. Opening report...'
Start-Process (Join-Path $root 'report.html')
