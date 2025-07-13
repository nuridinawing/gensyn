#!/bin/bash

# ==============================================================================
#  Skrip untuk Setup Monitoring Gensyn & Menambahkan Cron Job dengan Aman
# ==============================================================================

# Periksa apakah skrip dijalankan sebagai root (dengan sudo)
if [[ $EUID -ne 0 ]]; then
   echo "❌ Kesalahan: Skrip ini harus dijalankan sebagai root." 
   echo "Silakan jalankan dengan perintah: sudo ./setup_monitor.sh"
   exit 1
fi

echo "▶️  Menjalankan sebagai root. Memulai proses setup..."

# --- 1. Membuat Skrip Monitoring ---
MONITOR_SCRIPT_PATH="/root/gensyn_monitoring.sh"

# Menggunakan Here Document untuk membuat file skrip monitoring
tee ${MONITOR_SCRIPT_PATH} > /dev/null <<'MONITOR_EOF'
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
MONITOR_EOF

# --- 2. Memberikan Izin Eksekusi ---
chmod +x ${MONITOR_SCRIPT_PATH}
echo "✅ Skrip monitoring telah dibuat di ${MONITOR_SCRIPT_PATH} dan diberi izin eksekusi."

# --- 3. Menambahkan Cron Job ke Root Crontab ---
CRON_JOB="*/5 * * * * ${MONITOR_SCRIPT_PATH}"

# Menambahkan cron job ke crontab root hanya jika belum ada
if ! crontab -u root -l | grep -Fq "${CRON_JOB}"; then
    (crontab -u root -l 2>/dev/null; echo "${CRON_JOB}") | crontab -u root -
    echo "✅ Cron job berhasil ditambahkan untuk root."
else
    echo "ℹ️  Cron job sudah ada. Tidak ada perubahan yang dilakukan."
fi

echo ""
echo "🎉 Setup Selesai!"
echo "Untuk memeriksa cron job root, jalankan: sudo crontab -l"
echo "Untuk melihat log restart, jalankan: cat /root/gensyn_restart.log"
