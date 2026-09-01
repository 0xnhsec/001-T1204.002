#!/usr/bin/env bash
# ============================================================
# 01 — Lab Prep (CachyOS / Arch-based)
# Instal semua dependency untuk attacker box.
# Jalankan: bash 01-lab-prep.sh
# ============================================================
set -euo pipefail

echo "[*] Menginstall paket sistem (nim, mingw cross-compiler, socat, netcat, python, go)..."
sudo pacman -S --needed --noconfirm \
    nim \
    mingw-w64-gcc \
    socat \
    openbsd-netcat \
    python \
    go \
    git \
    unzip

echo
echo "[*] Verifikasi toolchain..."
nim --version | head -1
x86_64-w64-mingw32-gcc --version | head -1
socat -V | head -1
nc -h 2>&1 | head -1 || true

echo
echo "[+] Lab prep selesai."
echo "    Next step: bash 02-build-backdoor.sh [IP_HOST] [PORT] [NAMA_EXE]"
echo "    Default  : bash 02-build-backdoor.sh 10.0.2.2 4444 SecureDocViewer.exe"
