
# ==================================================
#  SERVER CONTROL CENTER | PROXMOX ONLY
# ==================================================

# --- 1. COLORS & STYLING ---
BG_BLUE="\e[44;97m"; BG_GREEN="\e[42;97m"; BG_RED="\e[41;97m"

R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[97m"; GREY="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

# --- 2. CONFIG ---
PROXMOX_PORT_FILE="/root/.proxmox_port"

# --- 3. UTILITY ---
pause() { echo; read -p "  ↩ Press Enter to continue..." _; }

get_port() {
    if [ -f "$PROXMOX_PORT_FILE" ]; then cat "$PROXMOX_PORT_FILE"; else echo "8006"; fi
}

# --- 4. HEADER ---
draw_header() {
    clear
    local user=$(whoami)
    local host=$(hostname)

    # Docker Status
    local doc_pill="${BG_RED} OFF ${RESET}"
    if command -v docker &>/dev/null; then doc_pill="${BG_GREEN} ON  ${RESET}"; fi

    # Proxmox Status
    local pmx_pill="${BG_RED} OFF ${RESET}"
    if docker ps -a --format '{{.Names}}' | grep -q "^proxmox$"; then pmx_pill="${BG_GREEN} ON  ${RESET}"; fi
    local pmx_port=$(get_port)

    echo -e "${BG_BLUE}${BOLD}  ⚡ SERVER CONTROL CENTER | PROXMOX                   ${RESET}"
    echo -e "  ${C}User:${RESET} $user   ${GREY}|${RESET}   ${C}Host:${RESET} $host"
    echo -e "  ${M}────────────────────────────────────────────────────────────${RESET}"

    echo -e "  ${BOLD}SERVICES STATUS:${RESET}"
    printf "  ├── ${W}%-10s${RESET} %b\n" "Docker" "$doc_pill"
    printf "  └── ${W}%-10s${RESET} %b  ${GREY}➜ Port: ${Y}$pmx_port${RESET}\n" "Proxmox" "$pmx_pill"

    echo -e "  ${M}────────────────────────────────────────────────────────────${RESET}"
    echo
}

# --- 5. INSTALL DOCKER ---
install_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "  ${B}[+] Installing Docker...${RESET}"
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
}

# --- 6. PROXMOX FUNCTIONS ---
install_proxmox() {
    draw_header
    install_docker

    echo -e "  ${BOLD}┌── [ INSTALL PROXMOX ]${RESET}"
    echo -e "  ${BOLD}│${RESET}"
    echo -e "  ${GREY}[${Y}1${GREY}]${RESET} Default Port ${C}(8006)${RESET}"
    echo -e "  ${GREY}[${Y}2${GREY}]${RESET} Custom Port"
    echo -e "  ${BOLD}│${RESET}"
    read -p "  └─➤ Select Option: " port_choice

    if [ "$port_choice" == "2" ]; then
        read -p "    ➤ Enter Custom Port: " CUSTOM_PORT
        PORT=$CUSTOM_PORT
    else
        PORT=8006
    fi

    echo "$PORT" > "$PROXMOX_PORT_FILE"

    echo -e "\n  ${B}[+] Creating persistent directories...${RESET}"
    mkdir -p /opt/proxmox/data
    mkdir -p /opt/proxmox/config

    echo -e "  ${B}[+] Installing Proxmox on port ${PORT}...${RESET}"

    docker rm -f proxmox >/dev/null 2>&1
    docker run -d \
      --name proxmox \
      --hostname pve \
      --privileged \
      --restart unless-stopped \
      --stop-timeout 120 \
      -e PASSWORD="root" \
      -p ${PORT}:8006 \
      -v /opt/proxmox/data:/var/lib/vz \
      -v /opt/proxmox/config:/var/lib/pve-cluster \
      nobitaa/proxmox

    echo -e "  ${G}[✓] Installed! Access: https://$host:${PORT}${RESET}"
    echo -e "  ${GREY}Note: Default Password is 'root'${RESET}"
    pause
}

uninstall_proxmox() {
    echo -e "\n  ${R}[!] Removing Proxmox container...${RESET}"
    docker rm -f proxmox >/dev/null 2>&1
    rm -f "$PROXMOX_PORT_FILE"
    echo -e "  ${G}[✓] Removed Successfully.${RESET}"
    echo -e "  ${Y}Note: Volumes in /opt/proxmox were kept intact. Delete them manually if needed.${RESET}"
    pause
}

start_proxmox() {
    docker start proxmox
    echo -e "  ${G}[✓] Proxmox Started${RESET}"
    pause
}

stop_proxmox() {
    docker stop proxmox
    echo -e "  ${R}[!] Proxmox Stopped${RESET}"
    pause
}

restart_proxmox() {
    docker restart proxmox
    echo -e "  ${Y}[↻] Proxmox Restarted${RESET}"
    pause
}

open_terminal() {
    echo -e "\n  ${B}[+] Opening Proxmox Terminal...${RESET}"
    if ! docker ps -a --format '{{.Names}}' | grep -q "^proxmox$"; then
        echo -e "  ${R}[!] Proxmox is not running. Start it first.${RESET}"
        pause
        return
    fi
    echo -e "  ${Y}Type 'exit' to return to the menu.${RESET}\n"
    docker exec -it proxmox /bin/bash
    pause
}

download_template() {
    echo -e "\n  ${B}[+] Downloading and starting OS Template Downloader inside Proxmox...${RESET}"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^proxmox$"; then
        echo -e "  ${R}[!] Proxmox container is not running. Please start it first.${RESET}"
        pause
        return
    fi

    # Execute the download and script directly inside the container
    docker exec -it proxmox /bin/bash -c "wget https://github.com/ConvoyPanel/downloader/releases/latest/download/downloader_x86 && chmod +x downloader_x86 && ./downloader_x86"
    pause
}

# --- 7. PROXMOX MENU ---
proxmox_menu() {
    while true; do
        draw_header
        echo -e "  ${BOLD}PROXMOX OPTIONS:${RESET}"
        echo -e "  ${GREY}[${Y}1${GREY}]${RESET} ${G}Install${RESET}"
        echo -e "  ${GREY}[${Y}2${GREY}]${RESET} ${G}Turn ON${RESET}"
        echo -e "  ${GREY}[${Y}3${GREY}]${RESET} ${R}Turn OFF${RESET}"
        echo -e "  ${GREY}[${Y}4${GREY}]${RESET} ${Y}Restart${RESET}"
        echo -e "  ${GREY}[${Y}5${GREY}]${RESET} ${B}Terminal Open${RESET}"
        echo -e "  ${GREY}[${Y}6${GREY}]${RESET} ${M}Download OS Template${RESET}"
        echo -e "  ${GREY}[${Y}7${GREY}]${RESET} ${R}Uninstall${RESET}"
        echo -e "  ${GREY}[${R}0${GREY}]${RESET} Exit"
        echo

        read -p "  > Select: " opt
        case $opt in
            1) install_proxmox ;;
            2) start_proxmox ;;
            3) stop_proxmox ;;
            4) restart_proxmox ;;
            5) open_terminal ;;
            6) download_template ;;
            7) uninstall_proxmox ;;
            0) echo -e "\n  ${G}👋 Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "  ${R}Invalid option${RESET}"; sleep 1 ;;
        esac
    done
}

# --- RUN ---
proxmox_menu
