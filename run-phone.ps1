# run-phone.ps1 — one-command dev loop for the DIGIVET mobile app on a real
# phone over Wi-Fi. Does, in order:
#   1. finds this laptop's Wi-Fi/LAN IP (ignores VPN adapters like Radmin)
#   2. makes sure the DIGIVET Online backend (port 4001) is running
#   3. makes sure Windows Firewall lets the phone reach it (one-time, asks for admin)
#   4. connects the phone with adb over Wi-Fi (auto-discovers it; pairs on first use)
#   5. runs the app on the phone with the right API address
# Use -Check to do steps 1-3 only (no phone needed).

param([switch]$Check)

$ErrorActionPreference = 'Stop'
$AppDir = $PSScriptRoot
$ServerDir = Join-Path $AppDir '..\digivetonline\server'
$Port = 4001
$RuleName = 'DIGIVET Online API (dev, LAN only)'
$Flutter = Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'
$Adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

function Step($msg) { Write-Host "`n== $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "   OK  $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "   !!  $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "   XX  $msg" -ForegroundColor Red; exit 1 }

# ---- 1. LAN IP --------------------------------------------------------
Step 'Finding this laptop''s Wi-Fi/LAN address'
$lan = Get-NetIPConfiguration |
  Where-Object { $_.IPv4DefaultGateway -and $_.InterfaceAlias -notmatch 'Radmin|VPN|vEthernet|Virtual|VMware|Loopback|Tailscale|ZeroTier' } |
  ForEach-Object { $_.IPv4Address.IPAddress } |
  Where-Object { $_ -match '^(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)' } |
  Select-Object -First 1
if (-not $lan) { Fail 'No Wi-Fi/LAN address found. Connect the laptop to the same Wi-Fi as the phone.' }
Ok "LAN IP $lan"
$ApiBase = "http://${lan}:$Port/api"

# ---- 2. backend -------------------------------------------------------
function Test-Port($p) {
  $c = New-Object Net.Sockets.TcpClient
  try { $c.Connect('127.0.0.1', $p); $true } catch { $false } finally { $c.Close() }
}
Step "Checking the DIGIVET Online backend (port $Port)"
if (Test-Port $Port) {
  Ok 'already running'
} else {
  if (-not (Test-Path (Join-Path $ServerDir 'package.json'))) { Fail "Backend folder not found: $ServerDir" }
  Warn 'not running - starting it in a new window'
  Start-Process cmd.exe -ArgumentList '/k', "cd /d `"$ServerDir`" && npm run dev"
  for ($i = 0; $i -lt 30 -and -not (Test-Port $Port); $i++) { Start-Sleep -Seconds 1 }
  if (-not (Test-Port $Port)) { Fail "Backend did not start on port $Port. Check the new window for errors." }
  Ok 'started'
}

# ---- 3. firewall ------------------------------------------------------
Step 'Checking the firewall rule'
if (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue) {
  Ok 'rule exists'
} else {
  Warn 'rule missing - asking for administrator permission (one time)'
  $cmd = "New-NetFirewallRule -DisplayName '$RuleName' -Direction Inbound -Protocol TCP -LocalPort $Port -RemoteAddress LocalSubnet -Profile Any -Action Allow"
  try {
    Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command', $cmd
  } catch { Fail 'Administrator permission was declined.' }
  if (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue) { Ok 'rule created' }
  else { Fail 'Firewall rule was not created.' }
}

try {
  $h = Invoke-RestMethod "http://${lan}:$Port/api/health" -TimeoutSec 5
  Ok "health check via $lan : $($h.status)"
} catch { Warn "Health check via $lan failed - the phone may not be able to reach the backend." }

if ($Check) { Write-Host "`nCheck complete. API address for the phone: $ApiBase" -ForegroundColor Green; exit 0 }

# ---- 4. phone over Wi-Fi ---------------------------------------------
if (-not (Test-Path $Adb)) { Fail "adb not found at $Adb" }
if (-not (Test-Path $Flutter)) { Fail "Flutter not found at $Flutter" }

function Get-Phone {
  # A "device" line that is a Wi-Fi connection (ip:port or adb-...-mdns name).
  (& $Adb devices) | Select-Object -Skip 1 |
    Where-Object { $_ -match '\sdevice$' -and $_ -match '^(\d+\.\d+\.\d+\.\d+:\d+|adb-)' } |
    ForEach-Object { ($_ -split '\s+')[0] } | Select-Object -First 1
}
function Get-Mdns($kind) {
  # Lines look like: adb-XXXX  _adb-tls-connect._tcp  192.168.1.5:41234
  (& $Adb mdns services) | Where-Object { $_ -match [regex]::Escape($kind) } |
    ForEach-Object { if ($_ -match '(\d+\.\d+\.\d+\.\d+:\d+)') { $Matches[1] } } | Select-Object -First 1
}

Step 'Connecting the phone over Wi-Fi'
& $Adb start-server | Out-Null
$phone = Get-Phone
for ($try = 0; -not $phone -and $try -lt 3; $try++) {
  $addr = Get-Mdns '_adb-tls-connect'
  if ($addr) {
    Write-Host "   found phone at $addr - connecting"
    & $Adb connect $addr | Out-Null
    Start-Sleep -Seconds 1
    $phone = Get-Phone
    continue
  }
  $pair = Get-Mdns '_adb-tls-pairing'
  if ($pair) {
    Warn "Pairing screen found at $pair"
    $code = Read-Host '   Enter the 6-digit pairing code shown on the phone'
    & $Adb pair $pair $code
    Start-Sleep -Seconds 2
    continue
  }
  Warn 'Phone not found. On the phone: Settings > Developer options > Wireless debugging = ON.'
  Write-Host '   (First time? tap "Pair device with pairing code" and leave that screen open.)'
  Read-Host '   Press Enter to search again'
}
if (-not $phone) { Fail 'Could not connect to the phone. Make sure it is on the same Wi-Fi as this laptop.' }
Ok "phone connected: $phone"

# ---- 5. run -----------------------------------------------------------
Step "Running the app on the phone (API = $ApiBase)"
Set-Location $AppDir
& $Flutter run -d $phone --dart-define="API_BASE=$ApiBase"
