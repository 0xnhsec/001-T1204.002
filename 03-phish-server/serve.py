#!/usr/bin/env python3
"""
serve.py — Logging HTTP server untuk simulasi drive-by phishing (LAB ONLY).

Menyajikan file dari ./www dan MENCATAT setiap hit ke hits.log:
timestamp, IP victim, User-Agent, path — berguna untuk korelasi
"victim fetch payload" vs event Sysmon di sisi Windows (Event ID 11/15).

Jalankan:  python3 serve.py 8080
Victim  :  http://10.0.2.2:8080/          (mode one-click)
           http://10.0.2.2:8080/?auto=1   (mode drive-by auto-download)

AUTHORIZED LAB USE ONLY — jalankan hanya terhadap VM milik sendiri.
"""
import datetime
import http.server
import os
import socketserver
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(BASE, "www")
LOG = os.path.join(BASE, "hits.log")

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def log_message(self, fmt, *args):
        line = (
            f"[{datetime.datetime.now().isoformat(timespec='seconds')}] "
            f"IP={self.client_address[0]} "
            f"UA=\"{self.headers.get('User-Agent', '-')}\" "
            f"{fmt % args}"
        )
        print(line, flush=True)
        try:
            with open(LOG, "a") as f:
                f.write(line + "\n")
        except OSError:
            pass

    def do_HEAD(self):
        self.log_message("HEAD %s", self.path)
        super().do_HEAD()


class ThreadingServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    os.makedirs(ROOT, exist_ok=True)
    with ThreadingServer(("0.0.0.0", PORT), Handler) as httpd:
        print(f"[*] Phish server  : http://0.0.0.0:{PORT}")
        print(f"[*] Web root      : {ROOT}")
        print(f"[*] Victim URL    : http://10.0.2.2:{PORT}/")
        print(f"[*] Auto drive-by : http://10.0.2.2:{PORT}/?auto=1")
        print(f"[*] Hit log       : {LOG}")
        print("[*] Ctrl+C untuk stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[*] Server dihentikan.")
