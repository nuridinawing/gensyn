#!/bin/bash

# Nama screen yang ingin diperiksa
SCREEN_NAME="gensyn"

# Periksa apakah screen dengan nama tersebut sedang berjalan
# Opsi -q (quiet) membuat grep tidak menghasilkan output, hanya exit status
if ! screen -ls | grep -q "\.${SCREEN_NAME}\s"; then
    # Jika tidak ditemukan, jalankan perintah-perintah ini
    echo "Screen '${SCREEN_NAME}' terminated. Running restart script..."
    cd /root/ # Pindah ke direktori home untuk memastikan path benar
    rm -rf updateunofficial.sh
    wget https://raw.githubusercontent.com/ezlabsnodes/gensyn/main/updateunofficial.sh
    chmod +x updateunofficial.sh
    ./updateunofficial.sh
fi
