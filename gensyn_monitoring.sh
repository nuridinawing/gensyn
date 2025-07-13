#!/bin/bash

# Menentukan path dan nama file skrip monitoring
MONITOR_SCRIPT_PATH="/root/gensyn_monitoring.sh"

# Membuat file skrip monitoring menggunakan "here document"
# Ini lebih aman dan lebih mudah daripada menggunakan editor teks dalam skrip
cat <<'EOF' > ${MONITOR_SCRIPT_PATH}
#!/bin/bash

# Nama screen yang ingin diperiksa
SCREEN_NAME="gensyn"

# Log file untuk mencatat kapan restart terjadi
LOG_FILE="/root/gensyn_restart.log"

# Periksa apakah screen dengan nama tersebut sedang berjalan
# Opsi -q (quiet) membuat grep tidak menghasilkan output, hanya exit status
if ! screen -ls | grep -q "\.${SCREEN_NAME}\s"; then
    # Jika tidak ditemukan, catat waktu dan jalankan perintah restart
    echo "$(date): Screen '${SCREEN_NAME}' not found. Restarting..." >> ${LOG_FILE}
    cd /root/
    rm -f egan.sh
    wget -q https://raw.githubusercontent.com/ezlabsnodes/gensyn/main/egan.sh
    chmod +x egan.sh
    ./egan.sh
fi
EOF

# Memberikan izin eksekusi (+x) pada skrip monitoring
chmod +x ${MONITOR_SCRIPT_PATH}
echo "✅ Skrip ${MONITOR_SCRIPT_PATH} telah dibuat dan diberi izin eksekusi."

# Menyiapkan cron job yang akan dijalankan
CRON_JOB="*/5 * * * * ${MONITOR_SCRIPT_PATH} >/dev/null 2>&1"

# Menambahkan cron job hanya jika belum ada untuk menghindari duplikasi
# 'crontab -l' untuk melihat list, 'grep' untuk mencari, '||' jika tidak ketemu maka jalankan perintah selanjutnya
(crontab -l 2>/dev/null | grep -Fq "${CRON_JOB}") || \
( (crontab -l 2>/dev/null; echo "${CRON_JOB}") | crontab - )

echo "✅ Cron job telah ditambahkan untuk berjalan setiap 5 menit."
echo "Untuk memeriksa, jalankan: crontab -l"
