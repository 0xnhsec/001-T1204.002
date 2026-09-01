<#
.SYNOPSIS
    Install Sysmon + SwiftOnSecurity config untuk lab PoC (Runbook 05 - Victim Win11)
.NOTES
    Jalankan sebagai Administrator PowerShell.
    Pastikan snapshot "clean-pre-exploit" sudah diambil SEBELUM run script ini.
#>

$ErrorActionPreference = "Stop"

Write-Host "[1/5] Cek session Administrator..." -ForegroundColor Cyan
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Script ini harus dijalankan sebagai Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "[2/5] Download Sysmon.zip..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "$env:TEMP\Sysmon.zip"

Write-Host "[3/5] Extract Sysmon.zip..." -ForegroundColor Cyan
Expand-Archive -Path "$env:TEMP\Sysmon.zip" -DestinationPath "$env:TEMP\Sysmon" -Force

# Cari Sysmon64.exe di manapun lokasinya hasil extract (jaga-jaga struktur folder beda)
$sysmonExe = Get-ChildItem -Path "$env:TEMP\Sysmon" -Recurse -Filter "Sysmon64.exe" | Select-Object -First 1
if (-not $sysmonExe) {
    Write-Host "ERROR: Sysmon64.exe tidak ditemukan setelah extract. Cek isi $env:TEMP\Sysmon manual." -ForegroundColor Red
    Get-ChildItem -Path "$env:TEMP\Sysmon" -Recurse
    exit 1
}
Write-Host "    Ditemukan: $($sysmonExe.FullName)" -ForegroundColor Green

Write-Host "[4/5] Download config SwiftOnSecurity..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "$env:TEMP\sysmonconfig.xml"

# Validasi file config bukan halaman error/HTML
$firstLine = Get-Content "$env:TEMP\sysmonconfig.xml" -TotalCount 1
if ($firstLine -notmatch "^\s*<") {
    Write-Host "ERROR: sysmonconfig.xml sepertinya bukan XML valid (cek isi file)." -ForegroundColor Red
    exit 1
}

Write-Host "[5/5] Install Sysmon dengan config..." -ForegroundColor Cyan
& $sysmonExe.FullName -accepteula -i "$env:TEMP\sysmonconfig.xml"

Write-Host "`nVerifikasi channel Sysmon..." -ForegroundColor Cyan
Start-Sleep -Seconds 2
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5 | Format-Table TimeCreated, Id, Message -Wrap -AutoSize

Write-Host "`nSelesai. Lanjut ke step 2 runbook (Baseline Defender)." -ForegroundColor Green
