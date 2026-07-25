#!/bin/bash

# ==================================================
#   SERVER CONTROL CENTER | MACOS ONLY
# ==================================================

# --- 1. COLORS & STYLING ---
BG_BLUE="\e[44;97m"; BG_GREEN="\e[42;97m"; BG_RED="\e[41;97m"

R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[97m"; GREY="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

# --- 2. CONFIG ---
MACOS_PORT_FILE="/root/.macos_port"

# --- 3. UTILITY ---
pause() { echo; read -p "   ↩ Press Enter to continue..." _; }

get_port() {
    if [ -f "$MACOS_PORT_FILE" ]; then cat "$MACOS_PORT_FILE"; else echo "8006"; fi
}

# --- 4. HEADER ---
draw_header() {
    clear
    local user=$(whoami)
    local host=$(hostname)

    # Docker Status
    local doc_pill="${BG_RED} OFF ${RESET}"
    if command -v docker &>/dev/null; then doc_pill="${BG_GREEN} ON  ${RESET}"; fi

    # macOS Status
    local mac_pill="${BG_RED} OFF ${RESET}"
    if docker ps -a --format '{{.Names}}' | grep -q macos; then mac_pill="${BG_GREEN} ON  ${RESET}"; fi
    local mac_port=$(get_port)

    echo -e "${BG_BLUE}${BOLD}   ⚡ SERVER CONTROL CENTER | MACOS                                       ${RESET}"
    echo -e "   ${C}User:${RESET} $user    ${GREY}|${RESET}    ${C}Host:${RESET} $host"
    echo -e "   ${M}────────────────────────────────────────────────────────────${RESET}"

    echo -e "   ${BOLD}SERVICES STATUS:${RESET}"
    printf "   ├── ${W}%-10s${RESET} %b\n" "Docker" "$doc_pill"
    printf "   └── ${W}%-10s${RESET} %b  ${GREY}➜ Port: ${Y}%s${RESET}\n" "macOS" "$mac_pill" "$mac_port"

    echo -e "   ${M}────────────────────────────────────────────────────────────${RESET}"
    echo
}

# --- 5. INSTALL DOCKER ---
install_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "   ${B}[+] Installing Docker...${RESET}"
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
}

# --- 6. MACOS FUNCTIONS ---
install_macos() {
    draw_header
    install_docker

    echo -e "   ${BOLD}┌── [ INSTALL MACOS ]${RESET}"
    echo -e "   ${BOLD}│${RESET}"
    echo -e "   ${GREY}[${Y}1${GREY}]${RESET} Default Port ${C}(8006)${RESET}"
    echo -e "   ${GREY}[${Y}2${GREY}]${RESET} Custom Port"
    echo -e "   ${BOLD}│${RESET}"
    read -p "   └─➤ Select Option: " port_choice

    if [ "$port_choice" == "2" ]; then
        read -p "    ➤ Enter Custom Port: " CUSTOM_PORT
        PORT=$CUSTOM_PORT
    else
        PORT=8006
    fi

    echo "$PORT" > "$MACOS_PORT_FILE"

    echo -e "\n   ${B}[+] Installing macOS on port ${PORT}...${RESET}"

    docker rm -f macos >/dev/null 2>&1
    docker run -d --name macos -e "VERSION=14" -p ${PORT}:8006 --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN -v "${PWD:-.}/macos:/storage" --stop-timeout 120 --restart=always docker.io/dockurr/macos

    echo -e "   ${G}[✓] Installed! Access: http://$host:${PORT}${RESET}"
    pause
}

uninstall_macos() {
    echo -e "\n   ${R}[!] Removing macOS...${RESET}"
    docker rm -f macos >/dev/null 2>&1
    rm -f "$MACOS_PORT_FILE"
    echo -e "   ${G}[✓] Removed Successfully.${RESET}"
    pause
}

start_macos() {
    docker start macos
    echo -e "   ${G}[✓] macOS Started${RESET}"
    pause
}

stop_macos() {
    docker stop macos
    echo -e "   ${R}[!] macOS Stopped${RESET}"
    pause
}

restart_macos() {
    docker restart macos
    echo -e "   ${Y}[↻] macOS Restarted${RESET}"
    pause
}

# --- 7. MACOS MENU ---
macos_menu() {
    while true; do
        draw_header
        echo -e "   ${BOLD}MACOS OPTIONS:${RESET}"
        echo -e "   ${GREY}[${Y}1${GREY}]${RESET} ${G}Install${RESET}"
        echo -e "   ${GREY}[${Y}2${GREY}]${RESET} ${G}Turn ON${RESET}"
        echo -e "   ${GREY}[${Y}3${GREY}]${RESET} ${R}Turn OFF${RESET}"
        echo -e "   ${GREY}[${Y}4${GREY}]${RESET} ${Y}Restart${RESET}"
        echo -e "   ${GREY}[${Y}5${GREY}]${RESET} ${R}Uninstall${RESET}"
        echo -e "   ${GREY}[${R}0${GREY}]${RESET} Exit"
        echo

        read -p "   > Select: " opt
        case $opt in
            1) install_macos ;;
            2) start_macos ;;
            3) stop_macos ;;
            4) restart_macos ;;
            5) uninstall_macos ;;
            0) echo -e "\n   ${G}👋 Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "   ${R}Invalid option${RESET}"; sleep 1 ;;
        esac
    done
}

# --- RUN ---
macos_menu
