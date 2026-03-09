# ============================================================
# setup-winrm.ps1 — FIXED VERSION
# Handles Public network profile properly
# Run as Administrator
# ============================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Setting up WinRM for Ansible (Fixed)"   -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ── Fix 1: Change Public network profiles to Private ────────
Write-Host "`n[1] Fixing network profile (Public to Private)..." -ForegroundColor Yellow
$publicProfiles = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Public" }
if ($publicProfiles) {
    foreach ($profile in $publicProfiles) {
        Write-Host "    Changing '$($profile.Name)' from Public to Private..." -ForegroundColor Yellow
        Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private
    }
    Write-Host "    All profiles set to Private" -ForegroundColor Green
} else {
    Write-Host "    No Public profiles found - already OK" -ForegroundColor Green
}

# ── Step 2: Enable WinRM ─────────────────────────────────────
Write-Host "`n[2] Enabling WinRM service..." -ForegroundColor Yellow
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Service WinRM -StartupType Automatic
Start-Service WinRM
Write-Host "    WinRM service started" -ForegroundColor Green

# ── Step 3: Enable Basic Auth (needed for Ansible) ───────────
Write-Host "`n[3] Enabling Basic authentication..." -ForegroundColor Yellow
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item -Path WSMan:\localhost\Client\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Client\AllowUnencrypted -Value $true
Write-Host "    Basic auth enabled" -ForegroundColor Green

# ── Step 4: WinRM Tuning ─────────────────────────────────────
Write-Host "`n[4] Tuning WinRM settings..." -ForegroundColor Yellow
Set-Item -Path WSMan:\localhost\MaxTimeoutms -Value 1800000
Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 1024
Set-Item -Path WSMan:\localhost\Shell\MaxShellsPerUser -Value 50
Write-Host "    WinRM tuning applied" -ForegroundColor Green

# ── Step 5: Open Firewall port 5985 ──────────────────────────
Write-Host "`n[5] Opening Firewall port 5985 (WinRM)..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "Ansible WinRM HTTP" -ErrorAction SilentlyContinue
New-NetFirewallRule `
    -DisplayName "Ansible WinRM HTTP" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5985 `
    -Action Allow `
    -Profile Any | Out-Null
Write-Host "    Port 5985 open" -ForegroundColor Green

# ── Step 6: Open Firewall port 8080 ──────────────────────────
Write-Host "`n[6] Opening Firewall port 8080 (Tomcat)..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "Tomcat HTTP 8080" -ErrorAction SilentlyContinue
New-NetFirewallRule `
    -DisplayName "Tomcat HTTP 8080" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 8080 `
    -Action Allow `
    -Profile Any | Out-Null
Write-Host "    Port 8080 open" -ForegroundColor Green

# ── Step 7: Trusted Hosts ────────────────────────────────────
Write-Host "`n[7] Setting trusted hosts..." -ForegroundColor Yellow
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Write-Host "    TrustedHosts = *" -ForegroundColor Green

# ── Step 8: Enable local admin remote access ─────────────────
Write-Host "`n[8] Enabling local admin remote access..." -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-ItemProperty -Path $regPath -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord
Write-Host "    Local admin remote access enabled" -ForegroundColor Green

# ── Step 9: Show Windows username (use in inventory.ini) ─────
Write-Host "`n[9] Your Windows login info for inventory.ini:" -ForegroundColor Yellow
$currentUser = $env:USERNAME
$computerName = $env:COMPUTERNAME
Write-Host "    Computer : $computerName" -ForegroundColor Cyan
Write-Host "    Username : $currentUser" -ForegroundColor Cyan
Write-Host "    --> Use this as ansible_user in inventory.ini" -ForegroundColor Yellow

# ── Step 10: Show usable IP addresses ───────────────────────
Write-Host "`n[10] Your usable IP addresses (not 169.254.x.x):" -ForegroundColor Yellow
$ips = Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -ne "127.0.0.1" }
foreach ($ip in $ips) {
    Write-Host "    $($ip.InterfaceAlias) : $($ip.IPAddress)" -ForegroundColor Cyan
}

# ── Step 11: Quick local test ────────────────────────────────
Write-Host "`n[11] Testing local WinRM connection..." -ForegroundColor Yellow
try {
    Test-WSMan -ComputerName localhost -ErrorAction Stop | Out-Null
    Write-Host "    Local WinRM test : PASSED" -ForegroundColor Green
} catch {
    Write-Host "    Local WinRM test : FAILED - $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " WinRM Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host " NOW update ansible/inventory.ini:" -ForegroundColor Yellow
Write-Host "   ansible_user=$currentUser" -ForegroundColor Cyan
Write-Host "   ansible_password=YOUR_WINDOWS_LOGIN_PASSWORD" -ForegroundColor Cyan
Write-Host ""
