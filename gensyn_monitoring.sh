#!/bin/bash

# Create the monitoring script
cat > /root/gensyn_monitoring.sh << 'EOF'
#!/bin/bash

# Nama screen yang ingin diperiksa
SCREEN_NAME="gensyn"

# Periksa apakah screen dengan nama tersebut sedang berjalan
# Opsi -q (quiet) membuat grep tidak menghasilkan output, hanya exit status
if ! screen -ls | grep -q "\.${SCREEN_NAME}\s"; then
    # Jika tidak ditemukan, jalankan perintah-perintah ini
    echo "Screen '${SCREEN_NAME}' terminated. Running restart script..."
    cd /root/ # Pindah ke direktori home untuk memastikan path benar
    rm -rf egan.sh
    wget https://raw.githubusercontent.com/ezlabsnodes/gensyn/main/egan.sh
    chmod +x egan.sh
    ./egan.sh
fi
EOF

# Make the script executable
chmod +x /root/gensyn_monitoring.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /root/gensyn_monitoring.sh >/dev/null 2>&1") | crontab -

echo "Monitoring script has been created at /root/gensyn_monitoring.sh"
echo "Cron job has been added to check every 5 minutes"
