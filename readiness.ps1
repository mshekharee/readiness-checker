# Pairing readiness (Windows PowerShell). No installs or elevated permissions.
$ErrorActionPreference='SilentlyContinue'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$items=New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Id,[string]$Status,[string]$Detail){ $items.Add(@{id=$Id; status=$Status; detailB64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Detail))}) }
Add-Check 'os' 'pass' "Windows / $($env:PROCESSOR_ARCHITECTURE)"
try { $f=Join-Path ([IO.Path]::GetTempPath()) ("pairing-"+[guid]::NewGuid().ToString()+'.tmp'); 'test' | Set-Content $f -ErrorAction Stop; $r=Get-Content $f -ErrorAction Stop; Remove-Item $f -ErrorAction SilentlyContinue; if($r -eq 'test'){Add-Check 'permissions' 'pass' 'Temporary workspace can be created and written'}else{Add-Check 'permissions' 'fail' 'Workspace test failed'} }catch{Add-Check 'permissions' 'fail' "Cannot write temporary workspace: $($_.Exception.Message)"}
$containerDetail=$null
if(Get-Command docker -ErrorAction SilentlyContinue){
 $dockerVersion=(& docker --version 2>&1 | Out-String).Trim()
 $dockerInfo=(& docker info --format '{{.ServerVersion}}' 2>&1 | Out-String).Trim()
 if($LASTEXITCODE -eq 0){
  $dockerContext=(& docker context show 2>$null | Out-String).Trim()
    if($dockerContext -eq 'colima'){$containerDetail="Colima engine reachable ($dockerVersion; engine $dockerInfo)"}
    else{$contextDetail=if($dockerContext){"; context $dockerContext"}else{''};$containerDetail="Docker-compatible engine reachable ($dockerVersion$contextDetail; engine $dockerInfo)"}
 }
}
if(!$containerDetail -and (Get-Command colima -ErrorAction SilentlyContinue) -and (Get-Command docker -ErrorAction SilentlyContinue)){
 $null=& colima status 2>&1
 if($LASTEXITCODE -eq 0){
    $colimaInfo=(& docker --context colima info --format '{{.ServerVersion}}' 2>&1 | Out-String).Trim()
    if($LASTEXITCODE -eq 0){$dockerVersion=(& docker --version 2>&1 | Out-String).Trim();$containerDetail="Colima engine reachable ($dockerVersion; context colima; engine $colimaInfo)"}
 }
}
if(!$containerDetail -and (Get-Command podman -ErrorAction SilentlyContinue)){
 $podmanVersion=(& podman --version 2>&1 | Out-String).Trim()
 $podmanInfo=(& podman info --format '{{.Host.Version}}' 2>&1 | Out-String).Trim()
 if($LASTEXITCODE -eq 0){$containerDetail="Podman engine reachable ($podmanVersion; engine $podmanInfo)"}
}
if($containerDetail){Add-Check 'docker' 'pass' $containerDetail}
else{Add-Check 'docker' 'fail' 'No supported container engine is accessible. Start Docker, Colima, or Podman, then retry.'}
$git=Get-Command git -ErrorAction SilentlyContinue
if($git){$v=(& git --version 2>&1 | Out-String).Trim();Add-Check 'git' 'pass' $v}else{Add-Check 'git' 'fail' 'Git not found on PATH'}
$langs=@('python','python3','go','ruby','node','java','dotnet') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
if($langs.Count){Add-Check 'language' 'pass' ('Available runtimes: '+($langs -join ', '))}else{Add-Check 'language' 'unknown' 'No supported language runtime found on PATH'}
$edit=@('code','codium','vim','nvim','notepad','notepad++','subl') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
$apps=@("$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe", "$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:ProgramFiles\JetBrains") | Where-Object { Test-Path $_ }
if($edit.Count -or $apps.Count){Add-Check 'editor' 'pass' ('Detected editor(s): '+(($edit+$apps) -join ', '))}else{Add-Check 'editor' 'unknown' 'No known editor detected; GUI-only installations may be missed'}
try { $response=Invoke-WebRequest -Uri 'https://github.com' -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop; Add-Check 'network' 'pass' "GitHub reachable (HTTP $([int]$response.StatusCode))" }catch{Add-Check 'network' 'fail' 'GitHub cannot be reached over HTTPS'}
try {
 $downloadRequest=[System.Net.HttpWebRequest]::Create('https://speed.cloudflare.com/__down?bytes=1000000');$downloadRequest.Timeout=15000;$downloadRequest.ReadWriteTimeout=15000
 $downloadTimer=[Diagnostics.Stopwatch]::StartNew();$downloadResponse=$downloadRequest.GetResponse();$responseMs=$downloadTimer.Elapsed.TotalMilliseconds
 $downloadStream=$downloadResponse.GetResponseStream();$buffer=New-Object byte[] 65536;[long]$downloadBytes=0
 while(($bytesRead=$downloadStream.Read($buffer,0,$buffer.Length)) -gt 0){$downloadBytes+=$bytesRead}
 $downloadStream.Dispose();$downloadResponse.Close();$downloadTimer.Stop();$downloadMbps=($downloadBytes*8)/$downloadTimer.Elapsed.TotalSeconds/1000000
 $uploadRequest=[System.Net.HttpWebRequest]::Create('https://speed.cloudflare.com/__up');$uploadRequest.Method='POST';$uploadRequest.ContentType='application/octet-stream';$uploadRequest.ContentLength=262144;$uploadRequest.Timeout=15000;$uploadRequest.ReadWriteTimeout=15000
 $uploadTimer=[Diagnostics.Stopwatch]::StartNew();$uploadStream=$uploadRequest.GetRequestStream();for($chunk=0;$chunk -lt 4;$chunk++){$uploadStream.Write($buffer,0,$buffer.Length)};$uploadStream.Dispose()
 $uploadResponse=$uploadRequest.GetResponse();$uploadResponse.Close();$uploadTimer.Stop();$uploadMbps=(262144*8)/$uploadTimer.Elapsed.TotalSeconds/1000000
 $internetDetail='Cloudflare response {0} ms; download {1} Mbps; upload {2} Mbps' -f [Math]::Round($responseMs),[Math]::Round($downloadMbps,1),[Math]::Round($uploadMbps,1)
 if($responseMs -le 100 -and $downloadMbps -ge 25 -and $uploadMbps -ge 10){Add-Check 'internet' 'excellent' "$internetDetail; excellent connection"}
 elseif($responseMs -le 300 -and $downloadMbps -ge 5 -and $uploadMbps -ge 2){Add-Check 'internet' 'good' "$internetDetail; meets the suggested video-call baseline"}
 else{Add-Check 'internet' 'poor' "$internetDetail; below the suggested video-call baseline (300 ms response, 5 Mbps down, 2 Mbps up)"}
}catch{Add-Check 'internet' 'unknown' 'Internet quality could not be measured; the Cloudflare test did not complete'}
$ssh=Get-Command ssh -ErrorAction SilentlyContinue
if(!$ssh){Add-Check 'ssh' 'fail' 'OpenSSH client not found'}else{$sshOutput=(& $ssh.Source -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=8 git@github.com 2>&1 | Out-String).Trim();if($sshOutput -match 'successfully authenticated'){Add-Check 'ssh' 'pass' 'GitHub accepted your SSH key for account authentication; no repository access was tested.'}elseif($sshOutput -match '(?i)host key verification failed|host key.*not found|no .*host key.*known'){Add-Check 'ssh' 'unknown' 'GitHub host key is not trusted yet; verify it with ssh -T git@github.com, then rerun diagnostics'}else{$sshDetail=$sshOutput;if($sshDetail.Length -gt 300){$sshDetail=$sshDetail.Substring(0,300)};Add-Check 'ssh' 'fail' "GitHub SSH authentication failed (no repository is targeted by this check): $sshDetail"}}
if(Get-Command kubectl -ErrorAction SilentlyContinue){$null=& kubectl cluster-info --request-timeout=5s 2>&1; if($LASTEXITCODE -eq 0){Add-Check 'k8s' 'pass' 'Cluster reachable'}else{Add-Check 'k8s' 'unknown' 'No reachable cluster'}}else{Add-Check 'k8s' 'unknown' 'kubectl not installed'}
$js='window.REPORT_ITEMS = '+($items | ConvertTo-Json -Depth 5 -Compress)+';'+[Environment]::NewLine+'window.REPORT_GENERATED_AT = '+((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')|ConvertTo-Json)+';'
[IO.File]::WriteAllText((Join-Path $root 'results.js'),$js,[Text.UTF8Encoding]::new($false))
Write-Host 'Readiness diagnostics complete. Opening report...'
Start-Process (Join-Path $root 'report.html')
