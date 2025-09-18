#!/usr/bin/env bash
# BloodyHound.sh (Educational Example)
# Start a local web server or expose it via Cloudflare Tunnel.

set -euo pipefail

# === CONFIG ===
LOCAL_PORT_DEFAULT=5000
CF_LOG="cf.log"
CLOUDFLARED="./cloudflared"

cleanup() {
  echo -e "[\e[33m*\e[0m] Cleaning up..."
  pkill -f "python3 -m http.server" 2>/dev/null || true
  pkill -f "python3 server.py" 2>/dev/null || true
  pkill -f "cloudflared tunnel" 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo -e "[\e[31m!\e[0m] $1 is required. Please install it first."
    exit 1
  }
}

download_cloudflared() {
  if [[ -f "$CLOUDFLARED" ]]; then
    chmod +x "$CLOUDFLARED"
    echo -e "[\e[32m+\e[0m] cloudflared already exists."
    return
  fi
  check_cmd wget || check_cmd curl
  arch=$(uname -m)
  case "$arch" in
    *aarch64*|*arm64*) url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
    *arm*)             url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" ;;
    *x86_64*)          url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
    *)                 url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" ;;
  esac
  echo -e "[\e[32m+\e[0m] Downloading cloudflared..."
  if command -v wget >/dev/null 2>&1; then
    wget -q --no-check-certificate "$url" -O "$CLOUDFLARED"
  else
    curl -sL "$url" -o "$CLOUDFLARED"
  fi
  chmod +x "$CLOUDFLARED"
}

start_local() {
  port=$1
  echo -e "[\e[32m+\e[0m] Starting local server on http://0.0.0.0:${port}"
  python3 server.py --port "${port}" &
  echo -e "[\e[33m*\e[0m] Press Ctrl+C to stop."
  wait
}

start_cloudflare() {
  port=$1
  download_cloudflared

  echo -e "[\e[32m+\e[0m] Starting local server on 127.0.0.1:${port} \e[33m"
  python3 server.py --port "${port}" &
  sleep 2

  echo -e "\e[0m[\e[32m+\e[0m] Starting Cloudflare Tunnel..."
  rm -f "$CF_LOG"
  nohup "$CLOUDFLARED" tunnel --url "http://127.0.0.1:${port}" --logfile "$CF_LOG" >/dev/null 2>&1 &
  
  echo -e "[\e[33m*\e[0m] Waiting for tunnel URL..."
  for i in {1..20}; do
    sleep 2
    if grep -qEo 'https://[-0-9a-z]*\.trycloudflare\.com' "$CF_LOG" 2>/dev/null; then
      link=$(grep -Eo 'https://[-0-9a-z]*\.trycloudflare\.com' "$CF_LOG" | head -n1)
      echo -e "[\e[32m+\e[0m] Public URL: \e[32m$link\e[0m"
      echo -e "[\e[33m*\e[0m] Press Ctrl+C to stop."
      tail -f "$CF_LOG"
      return
    fi
  done

  echo -e "[\e[31m!\e[0m] No URL detected. Check $CF_LOG for details."
  cleanup
}

menu() {
echo -e "\e[31m██░ ██  ▒█████   █    ██  ███▄    █ ▓█████▄ \e[0m"
echo -e "\e[31m▓██░ ██▒▒██▒  ██▒ ██  ▓██▒ ██ ▀█   █ ▒██▀ ██▌\e[0m"
echo -e "\e[31m▒██▀▀██░▒██░  ██▒▓██  ▒██░▓██  ▀█ ██▒░██   █▌\e[0m"
echo -e "\e[31m░▓█ ░██ ▒██   ██░▓▓█  ░██░▓██▒  ▐▌██▒░▓█▄   ▌\e[0m"
echo -e "\e[31m░▓█▒░██▓░ ████▓▒░▒▒█████▓ ▒██░   ▓██░░▒████▓ \e[0m"
echo -e "\e[31m▒ ░░▒░▒░ ▒░▒░▒░ ░▒▓▒ ▒ ▒ ░ ▒░   ▒ ▒  ▒▒▓  ▒ \e[0m"
echo -e "\e[31m▒ ░▒░ ░  ░ ▒ ▒░ ░░▒░ ░ ░ ░ ░░   ░ ▒░ ░ ▒  ▒ \e[0m"
echo -e "\e[31m░  ░░ ░░ ░ ░ ▒   ░░░ ░ ░    ░   ░ ░  ░ ░  ░ \e[0m"
echo -e "\e[31m░  ░  ░    ░ ░     ░              ░    ░    \e[0m"
echo -e "\e[31m                                    ░      \e[0m"
echo -e "\e[33mWARNING\e[0m: Use this tool only with content you own or have permission to share."
echo -e "[\e[32m>\e[0m]\e[31m Bloody Hound is on!!!\e[0m\n"
echo -e "\e[37m1) Start Localhost server\e[0m"
echo -e "\e[37m2) Start with Cloudflare Tunnel (public link)\e[0m"
echo -e "\e[37m3) Download/Update cloudflared\e[0m"
echo -e "\e[37m4) Exit\e[0m\n"
}

main() {
  check_cmd python3
  while true; do
    menu
    read -rp "Select option [1-4]: " opt
    case "$opt" in
      1)
        read -rp "Port [${LOCAL_PORT_DEFAULT}]: " p
        start_local "${p:-$LOCAL_PORT_DEFAULT}"
        ;;
      2)
        read -rp "Local port to forward [${LOCAL_PORT_DEFAULT}]: " p
        start_cloudflare "${p:-$LOCAL_PORT_DEFAULT}"
        ;;
      3)
        download_cloudflared
        ;;
      4)
        cleanup
        ;;
      *)
        echo "Invalid choice."
        ;;
    esac
  done
}

main