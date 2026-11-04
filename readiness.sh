#!/usr/bin/env bash
# Pairing readiness: no installs, no privileged operations, no secrets collected.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
REPORT="$ROOT/results.js"
status=""; detail=""
b64(){ printf '%s' "$1" | base64 | tr -d '\r\n'; }
entry(){ local id="$1"; printf '  {id:"%s",status:"%s",detailB64:"%s"},\n' "$id" "$status" "$(b64 "$detail")" >> "$REPORT"; }
pass(){ status=pass; detail="$1"; }
fail(){ status=fail; detail="$1"; }
unknown(){ status=unknown; detail="$1"; }
command_exists(){ command -v "$1" >/dev/null 2>&1; }
run_quick(){ # $1 timeout seconds, remainder command
  local secs="$1"; shift
  if command_exists timeout; then timeout "$secs" "$@" 2>&1
  elif command_exists gtimeout; then gtimeout "$secs" "$@" 2>&1
  else "$@" 2>&1
  fi
}
{
  printf 'window.REPORT_ITEMS = [\n'
} > "$REPORT"
OS=$(uname -s); ARCH=$(uname -m)
pass "$OS / $ARCH"; entry os
TMPBASE="${TMPDIR:-/tmp}"
if tmpcheck=$(mktemp "${TMPBASE%/}/pairing-check.XXXXXX" 2>/dev/null); then
  if printf 'test' > "$tmpcheck" 2>/dev/null && [ "$(cat "$tmpcheck" 2>/dev/null)" = test ]; then pass 'Temporary workspace can be created and written'; else fail 'Unable to write to temporary workspace'; fi
  rm -f "$tmpcheck"
else fail 'Unable to create a temporary file (check local permissions)'; fi
entry permissions
container_result=''
if command_exists docker; then
  docker_version=$(docker --version 2>/dev/null | head -1)
  if result=$(run_quick 8 docker info --format '{{.ServerVersion}}'); then
    docker_context=$(docker context show 2>/dev/null)
    if [ "$docker_context" = colima ]; then
      container_result="Colima engine reachable (${docker_version}; engine $result)"
    else
      container_result="Docker-compatible engine reachable (${docker_version}${docker_context:+; context $docker_context}; engine $result)"
    fi
  fi
fi
if [ -z "$container_result" ] && command_exists colima && command_exists docker; then
  if run_quick 8 colima status >/dev/null && result=$(run_quick 8 docker --context colima info --format '{{.ServerVersion}}'); then
    docker_version=$(docker --version 2>/dev/null | head -1)
    container_result="Colima engine reachable (${docker_version}; context colima; engine $result)"
  fi
fi
if [ -z "$container_result" ] && command_exists podman; then
  podman_version=$(podman --version 2>/dev/null | head -1)
  if result=$(run_quick 8 podman info --format '{{.Host.Version}}'); then
    container_result="Podman engine reachable (${podman_version}; engine $result)"
  fi
fi
if [ -n "$container_result" ]; then pass "$container_result"
else fail 'No supported container engine is accessible. Start Docker, Colima, or Podman, then retry.'; fi
entry docker
if command_exists git && git --version >/dev/null 2>&1; then pass "$(git --version 2>/dev/null)"; else fail 'Git not found or not executable'; fi
entry git
found=''
for cmd in python3 python go ruby node java dotnet; do
 if command_exists "$cmd"; then found="$found${found:+, }$cmd"; fi
done
if [ -n "$found" ]; then pass "Available runtimes: $found"; else unknown 'No supported runtime detected on PATH'; fi
entry language
editors=''
for cmd in code codium vim nvim nano emacs subl idea; do
 if command_exists "$cmd"; then editors="$editors${editors:+, }$cmd"; fi
done
if [ "$OS" = Darwin ]; then
 for app in '/Applications/Visual Studio Code.app' '/Applications/Xcode.app' '/Applications/IntelliJ IDEA.app' '/Applications/Sublime Text.app'; do
  if [ -d "$app" ]; then editors="$editors${editors:+, }$(basename "$app")"; fi
 done
fi
if [ -n "$editors" ]; then pass "Detected editors: $editors"; else unknown 'No known editor detected; some GUI-only installations may be missed'; fi
entry editor
if command_exists curl && curl -fsSI --connect-timeout 5 --max-time 10 https://github.com >/dev/null 2>&1; then pass 'GitHub reachable over HTTPS'; else fail 'Could not reach github.com over HTTPS (check internet/proxy)'; fi
entry network
if command_exists curl && command_exists dd && command_exists awk; then
  internet_download_metrics=$(curl -fsS --connect-timeout 5 --max-time 15 -o /dev/null -w '%{time_starttransfer} %{speed_download}' 'https://speed.cloudflare.com/__down?bytes=1000000' 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$internet_download_metrics" ]; then
    internet_response_seconds=${internet_download_metrics%% *}
    internet_download_bytes_sec=${internet_download_metrics##* }
    internet_upload_bytes_sec=$(dd if=/dev/zero bs=65536 count=4 2>/dev/null | curl -fsS --connect-timeout 5 --max-time 15 -o /dev/null -w '%{speed_upload}' --data-binary @- 'https://speed.cloudflare.com/__up' 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$internet_upload_bytes_sec" ]; then
      internet_response_ms=$(awk -v seconds="$internet_response_seconds" 'BEGIN { printf "%.0f", seconds * 1000 }')
      internet_download_mbps=$(awk -v rate="$internet_download_bytes_sec" 'BEGIN { printf "%.1f", rate * 8 / 1000000 }')
      internet_upload_mbps=$(awk -v rate="$internet_upload_bytes_sec" 'BEGIN { printf "%.1f", rate * 8 / 1000000 }')
      internet_detail="Cloudflare response ${internet_response_ms} ms; download ${internet_download_mbps} Mbps; upload ${internet_upload_mbps} Mbps"
      if awk -v response="$internet_response_ms" -v download="$internet_download_mbps" -v upload="$internet_upload_mbps" 'BEGIN { exit !(response <= 300 && download >= 5 && upload >= 2) }'; then
        pass "$internet_detail; meets the suggested video-call baseline"
      else
        status=review; detail="$internet_detail; below the suggested video-call baseline (300 ms response, 5 Mbps down, 2 Mbps up)"
      fi
    else unknown 'Internet quality could not be measured; the Cloudflare upload test did not complete'; fi
  else unknown 'Internet quality could not be measured; the Cloudflare download test did not complete'; fi
else unknown 'Internet quality test requires curl, dd, and awk'; fi
entry internet
if command_exists ssh; then
  ssh_output=$(run_quick 10 ssh -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=8 git@github.com 2>&1)
  if printf '%s' "$ssh_output" | grep -Fq 'successfully authenticated'; then
    pass 'GitHub accepted your SSH key for account authentication; no repository access was tested.'
  elif printf '%s' "$ssh_output" | grep -Eqi 'host key verification failed|no .*host key.*known|host key.*not found'; then
    unknown 'GitHub host key is not trusted yet; verify it with ssh -T git@github.com, then rerun diagnostics'
  else
    fail "GitHub SSH authentication failed (no repository is targeted by this check): ${ssh_output:0:300}"
  fi
else fail 'OpenSSH client not found'; fi
entry ssh
if command_exists kubectl; then
 if run_quick 6 kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then pass 'Kubernetes cluster reachable (optional)'; else unknown 'kubectl available but no reachable cluster (optional)'; fi
else unknown 'kubectl not installed (optional)'; fi
entry k8s
printf '];\nwindow.REPORT_GENERATED_AT = "%s";\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$REPORT"
printf '\nDiagnostics written to: %s\n' "$REPORT"
case "$OS" in
 Darwin) open "$ROOT/report.html" >/dev/null 2>&1 && echo 'Opening report in your browser.' ;;
 Linux) if command_exists xdg-open; then xdg-open "$ROOT/report.html" >/dev/null 2>&1 && echo 'Opening report in your browser.'; else echo "Open $ROOT/report.html in your browser"; fi ;;
esac
printf 'To re-test, run this script again. No applications were installed.\n'
