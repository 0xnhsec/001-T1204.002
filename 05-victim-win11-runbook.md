# 05 — Runbook Sisi Victim (Windows 11 25H2 VM)

> ⚠️AUTHORIZED LAB ONLY. Semua langkah di sini untuk VM milik sendiri di VirtualBox.

Urutan penting: **instrumentasi dulu, baru testing**. Kalau Sysmon dipasang
setelah payload jalan, telemetry fase awal hilang dan hasil PoC defense kamu
gak bisa dipakai buat bikin Sigma rules.

---

## 0. Snapshot DULU sebelum apa pun

```
VirtualBox → Machine → Take Snapshot → "clean-pre-exploit"
```

Setiap fase testing selesai → restore snapshot → repeat. Ini yang bikin
retest evasion (fase hades_gate/XOR nanti) apples-to-apples.

---

## 1. Install Sysmon (SEBELUM testing)

Download dari Microsoft Sysinternals (di VM, butuh internet sekali — NAT
masih bisa keluar):

```powershell
# Admin PowerShell
Invoke-WebRequest https://download.sysinternals.com/files/Sysmon.zip -OutFile $env:TEMP\Sysmon.zip
Expand-Archive $env:TEMP\Sysmon.zip -DestinationPath $env:TEMP\Sysmon -Force

# Config community: SwiftOnSecurity sysmon-config
Invoke-WebRequest https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml -OutFile $env:TEMP\sysmonconfig.xml

$env:TEMP\Sysmon\Sysmon64.exe -accepteula -i $env:TEMP\sysmonconfig.xml
```

Verifikasi channel-nya hidup:

```powershell
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
```

## 2. Baseline Defender (catat — ini "before" buat AV test)

```powershell
Get-MpComputerStatus | Format-List AMServiceEnabled, RealTimeProtectionEnabled,
    BehaviorMonitorEnabled, AntivirusSignatureVersion, AntivirusEngineVersion,
    AntivirusSignatureLastUpdated
```

Simpan outputnya ke file. Setiap varian payload dites, catat: kena / tidak,
di stage mana (download vs execution).

## 3. Connectivity test (pastikan routing NAT jalan)

```powershell
Test-NetConnection 10.0.2.2 -Port 8080    # phish server
Test-NetConnection 10.0.2.2 -Port 4444    # handler
```

> Kalau `ipconfig` menunjukkan Default Gateway bukan 10.0.2.2 (misal NAT
> network custom), pakai gateway itu sebagai IP di semua langkah.

## 4. Test Sequence

| Step | Aksi | Yang diamati |
|------|------|--------------|
| 4.1 | Buka `http://10.0.2.2:8080/` di Edge | One-click mode — perhatikan SmartScreen/MotW warning |
| 4.2 | Klik tombol → exe masuk Downloads | Sysmon EID 11 (file create), EID 15 (MotW/Zone) |
| 4.3 | Jalankan exe (ini mensimulasikan victim dipancing) | EID 1 (process create), Defender first-scan |
| 4.4 | Callback masuk ke handler di CachyOS | EID 3 (network connect → 10.0.2.2:4444) |
| 4.5 | Di handler: `whoami`, `ipconfig`, `dir` | EID 1 child process: cmd.exe dari payload |

Drive-by penuh (tanpa klik): buka `http://10.0.2.2:8080/?auto=1`.

## 5. Query event pasca-tes (bahan Sigma rules kamu)

```powershell
# Semua event Sysmon terbaru
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 50 |
    Format-Table TimeCreated, Id, Message -Wrap

# Network connection ke handler
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 200 |
    Where-Object { $_.Message -match "10.0.2.2" } |
    Format-List TimeCreated, Id, Message

# Proses yang lahir dari Downloads
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 500 |
    Where-Object { $_.Message -match "Downloads" -and $_.Id -eq 1 } |
    Format-List TimeCreated, Message
```

## 6. Detection Matrix (fase ini → event yang harus memicu alert)

| Fase attack | Teknik (ATT&CK) | Sysmon EID | Yang diharapkan terlihat |
|---|---|---|---|
| Drive-by visit | T1189 Drive-By Compromise | 11, 15 | exe muncul di Downloads + MotW zone |
| Eksekusi payload | T1204.002 User Execution | 1 | SecureDocViewer.exe spawn dari Downloads |
| Callback C2 | T1071.001 Web/TCP | 3 | koneksi outbound ke 10.0.2.2:4444, proses = payload |
| Command exec | T1059.003 Windows cmd | 1 | cmd.exe dengan parent = payload |

Ini matriks inti buat sessi defense: **kalau 4 baris ini bisa di-alert via
Sigma, deteksi kill chain fase awal kamu sudah jalan**.

## 7. Restore

Setelah capture lengkap → restore snapshot "clean-pre-exploit" → siap untuk
fase evasion (XOR encoder / hades_gate) dan LPE dengan telemetry bersih.
