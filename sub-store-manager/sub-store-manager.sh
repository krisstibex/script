#!/bin/bash

TARGET_DIR="/root/sub-store"

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

cd "$TARGET_DIR" || { echo "Unable to change directory to $TARGET_DIR"; exit 1; }

# ASCII Art
echo "            _                           "
echo "  ___ _   _| |__  _ __ ___   __ _ _ __  "
echo " / __| | | | '_ \| '_ \` _ \ / _\` | '_ \ "
echo " \__ \ |_| | |_) | | | | | | (_| | | | |"
echo " |___/\__,_|_.__/|_| |_| |_|\__,_|_| |_|"
echo "                                        "

show_menu() {
    echo "Select an option:"
    echo "1. Install or Update Sub-Store"
    echo "2. Request Certificate and Setup Reverse Proxy"
    echo "3. Install Service"
    echo "4. Install Node.js Environment"
    echo "5. Exit"
}

read_option() {
    local choice="$1"
    case $choice in
        1) install_update_substore ;;
        2) setup_certificate ;;
        3) install_service ;;
        4) install_node ;;
        5) exit 0 ;;
        *) echo "Invalid choice" && exit 1
    esac
}

install_update_substore() {
    rm -f sub-store.bundle.js
    rm -rf frontend
    wget -q "https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js" -O "sub-store.bundle.js"
    wget -q "https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip" -O "dist.zip"
    unzip -q dist.zip && mv dist frontend && rm dist.zip
    systemctl restart sub-store.service
}

setup_certificate() {
    local domain="$1"
    if [ -z "$domain" ]; then
        read -p "Domain: " domain
    fi

    apt-get update
    apt-get install -y nginx certbot python3-certbot-nginx

    RANDOM_STR=$(openssl rand -base64 6 | tr -dc 'a-zA-Z0-9' | cut -c1-8)
    EMAIL="${RANDOM_STR}@gmail.com"
    certbot --nginx -d "$domain" --email "$EMAIL" --agree-tos --no-eff-email > /dev/null 2>&1

    cat > /etc/nginx/sites-enabled/default <<EOL
server {

    if (\$host = $domain) {
        return 301 https://\$host\$request_uri;
    }

    listen 80 ;
    listen [::]:80 ;
    server_name $domain;
    return 404;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name $domain;

  ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

  location / {
    proxy_pass http://127.0.0.1:3001;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}

EOL

    nginx -s reload
}

install_service() {
    local api_path="$1"
    if [ -z "$api_path" ]; then
        read -p "Enter API path (leave blank for random): " api_path
        if [ -z "$api_path" ]; then
            api_path=$(uuidgen)
        fi
    fi

    cat > /etc/systemd/system/sub-store.service <<EOL
[Unit]
Description=Sub-Store
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
LimitNOFILE=32767
Type=simple
Environment="SUB_STORE_FRONTEND_BACKEND_PATH=/$api_path"
Environment="SUB_STORE_BACKEND_CRON=0 0 * * *"
Environment="SUB_STORE_FRONTEND_PATH=/root/sub-store/frontend"
Environment="SUB_STORE_FRONTEND_HOST=0.0.0.0"
Environment="SUB_STORE_FRONTEND_PORT=3001"
Environment="SUB_STORE_DATA_BASE_PATH=/root/sub-store"
Environment="SUB_STORE_BACKEND_API_HOST=127.0.0.1"
Environment="SUB_STORE_BACKEND_API_PORT=3000"
ExecStart=node /root/sub-store/sub-store.bundle.js
User=root
Group=root
Restart=on-failure
RestartSec=5s
ExecStartPre=/bin/sh -c ulimit -n 51200
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOL

    systemctl start sub-store.service
    systemctl enable sub-store.service
    systemctl restart sub-store.service
    systemctl daemon-reload
}

install_node() {
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
    sudo apt-get install -y nodejs
}

if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read -p "Enter your choice (1-5): " choice
        read_option "$choice"
    done
else
    case $1 in
        install|update) install_update_substore ;;
        cert) shift; setup_certificate "$1" ;;
        service) shift; install_service "$1" ;;
        node) install_node ;;
        -h|-help) show_help ;;
        *) echo "Invalid option $1" && exit 1 ;;
    esac
fi
