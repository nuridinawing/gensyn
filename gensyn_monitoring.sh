#!/bin/bash

# Nama screen yang ingin diperiksa
SCREEN_NAME="gensyn"

# Log file untuk mencatat kapan restart terjadi
LOG_FILE="/root/gensyn_restart.log"

# Periksa apakah screen dengan nama tersebut sedang berjalan
if ! screen -ls | grep -q "\.${SCREEN_NAME}\s"; then
    # Jika tidak ditemukan, catat waktu dan jalankan perintah restart
    echo "$(date): Screen '${SCREEN_NAME}' tidak ditemukan. Memulai ulang..." >> ${LOG_FILE}
    cd /root/
    rm -f egan.sh
    wget -q https://raw.githubusercontent.com/ezlabsnodes/gensyn/main/egan.sh
    chmod +x egan.sh
    ./egan.sh >> ${LOG_FILE} 2>&1
fi
