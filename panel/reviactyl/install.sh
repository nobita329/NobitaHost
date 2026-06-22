#!/bin/bash

# --- SEMA NEON THEME ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'
HEADER_LINE="${GRAY}────────────────────────────────────────────────────────────${NC}"
PHP_VERSION="8.3"

# --- UI HELPERS ---
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
ooooooooo.                          o8o                          .               oooo  
`888   `Y88.                        `"'                        .o8               `888  
 888   .d88'  .ooooo.  oooo    ooo oooo   .oooo.    .ooooo.  .o888oo oooo    ooo  888  
 888ooo88P'  d88' `88b  `88.  .8'  `888  `P  )88b  d88' `"Y8   888    `88.  .8'   888  
 888`88b.    888ooo888   `88..8'    888   .oP"888  888         888     `88..8'    888  
 888  `88b.  888    .o    `888'     888  d8(  888  888   .o8   888 .    `888'     888  
o888o  o888o `Y8bod8P'     `8'     o888o `Y888""8o `Y8bod8P'   "888"     .8'     o888o 
                                                                     .o..P'            
                                                                     `Y8P'             
                                                                     
        reviactyl PANEL INSTALLER         
                                                                                                         
EOF
    echo -e "           ${WHITE}PREMIUM PTERODACTYL INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
}

ok() {
    echo -e "  ${GREEN}[OK]${NC} $1"
}

step() {
    echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"
}

# --- INPUT FUNCTION ---
ask() {
    local label=$1
    local default=$2
    local var_name=$3
    echo -ne "  ${PURPLE}•${NC} ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}╰─>${NC} "
    read input
    if [ -z "$input" ]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

# --- START ---
show_banner

# --- DATA COLLECTION ---
ask "Panel Domain" "panel.nobita.indevs.in" DOMAIN
ask "Admin Email" "admin@gmail.com" EMAIL
ask "Admin Username" "admin" USERNAME
ask "Admin Password" "admin" PASSWORD

# --- FINAL VALIDATION LOOP ---
echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}Domain:${NC}   $DOMAIN"
echo -e "  ${GOLD}│${NC} ${GRAY}Email:${NC}    $EMAIL"
echo -e "  ${GOLD}│${NC} ${GRAY}User:${NC}     $USERNAME"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM
    echo ""

    case $CONFIRM in
        [Yy]* )
            echo -e "  ${GREEN}Proceeding to deployment...${NC}"
            break
            ;;
        [Nn]* )
            echo -e "  ${RED}Installation aborted by user.${NC}"
            exit
            ;;
        * )
            echo -e "  ${GRAY}Invalid input. Enter ${NC}${WHITE}y${NC}${GRAY} or ${NC}${WHITE}n${NC}${GRAY}.${NC}"
            ;;
    esac
done

echo -e "${HEADER_LINE}"

line(){ echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }
step(){ echo -e "${C_BLUE}➜ $1${C_RESET}"; }
ok(){ echo -e "${C_GREEN}✔ $1${C_RESET}"; }
warn(){ echo -e "${C_YELLOW}⚠ $1${C_RESET}"; }

# --- Dependencies ---
apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

if [[ "$OS" == "ubuntu" ]]; then
    echo "✅ Detected Ubuntu. Adding PPA for PHP..."
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    echo "✅ Detected Debian. Skipping PPA and adding PHP repo manually..."
    # Add SURY PHP repo for Debian
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# Add Redis GPG key and repo
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
#  --------------------------------------------------------------- #
# Update repositories list
apt update
# Install Dependencies
apt -y install php8.5 php8.5-{common,cli,gd,mbstring,bcmath,xml,fpm,curl,zip,intl,redis,sqlite3} nginx tar unzip git redis-server
# Install MySQL/MariaDB Dependencies (Optional)
apt install -y php8.5-mysql mariadb-server
# Install PostgreSQL Dependencies (Optional)
apt install -y php8.5-pgsql postgresql postgresql-contrib
#  --------------------------------------------------------------- #
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
mkdir -p /var/www/reviactyl
cd /var/www/reviactyl
curl -Lo panel.tar.gz https://github.com/reviactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# --- .env Setup ---
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
fi

#  --------------------------------------------------------------- #
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
php artisan key:generate --force
#  --------------------------------------------------------------- #
# --- Permissions ---
chown -R www-data:www-data /var/www/reviactyl/*
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/reviactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
# --- Nginx Setup ---
mkdir -p /etc/certs/reviactyl
cd /etc/certs/reviactyl
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem

tee /etc/nginx/sites-available/reviactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/reviactyl/public;
    index index.php;

    ssl_certificate /etc/certs/reviactyl/fullchain.pem;
    ssl_certificate_key /etc/certs/reviactyl/privkey.pem;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/reviactyl.conf /etc/nginx/sites-enabled/reviactyl.conf || true
nginx -t && systemctl restart nginx
ok "Nginx online"

# --- Queue Worker ---
tee /etc/systemd/system/reviq.service > /dev/null << 'EOF'
# /etc/systemd/system/reviq.service
[Unit]
Description=Reviactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/reviactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now redis-server
sudo systemctl enable --now reviq.service

step "Create admin user"

cd /var/www/reviactyl

# Update .env settings
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env
sed -i '/RECAPTCHA_ENABLED=/d' .env
echo 'RECAPTCHA_ENABLED=false' >> .env
sed -i '/APP_NAME=/d' .env
echo 'APP_NAME="Nobita Cloud"' >> .env
TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
sed -i "s|APP_TIMEZONE=.*|APP_TIMEZONE=${TIMEZONE}|g" .env

# SMTP defaults (user should update these)
sed -i "s|MAIL_MAILER=.*|MAIL_MAILER=smtp|g" .env
sed -i "s|MAIL_HOST=.*|MAIL_HOST=smtp.zoho.in|g" .env
sed -i "s|MAIL_PORT=.*|MAIL_PORT=587|g" .env
sed -i "s|MAIL_USERNAME=.*|MAIL_USERNAME=free.mell@aiomarket.online|g" .env
sed -i "s|MAIL_PASSWORD=.*|MAIL_PASSWORD=58@S5wZuWtpdDDX|g" .env
sed -i "s|MAIL_ENCRYPTION=.*|MAIL_ENCRYPTION=tls|g" .env
sed -i "s|MAIL_FROM_ADDRESS=.*|MAIL_FROM_ADDRESS=free.mell@aiomarket.online|g" .env
sed -i 's|MAIL_FROM_NAME=.*|MAIL_FROM_NAME="Nobita Cloud"|g' .env

php artisan p:location:make --short=IN --long="India" 2>/dev/null || true

# --- Cache optimization ---
php artisan view:clear
php artisan config:clear
php artisan cache:clear
php artisan config:cache
chown -R www-data:www-data /var/www/reviactyl/*
php artisan queue:restart

# --- Admin User ---
php artisan p:user:make -n --email="$EMAIL" --username="${USERNAME}" --password="$PASSWORD" --admin=1 --name-first=My --name-last=Admin

# --- END REPORT ---
clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}https://$DOMAIN${NC}"
echo -e "  ${GRAY}Username  :${NC} ${WHITE}$USERNAME${NC}"
echo -e "  ${GRAY}Password  :${NC} ${WHITE}$PASSWORD${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}$EMAIL${NC}"
echo -e "\n  ${PURPLE}Enjoy your new Pterodactyl Panel!${NC}"
echo -e "${HEADER_LINE}"
