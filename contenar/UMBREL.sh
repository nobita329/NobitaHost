#!/bin/bash

# ==================================================
#   SERVER CONTROL CENTER | UMBREL ONLY
# ==================================================

# --- 1. COLORS & STYLING ---
BG_BLUE="\e[44;97m"; BG_GREEN="\e[42;97m"; BG_RED="\e[41;97m"

R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[97m"; GREY="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

# --- 2. CONFIG ---
UMBREL_PORT_FILE="/root/.umbrel_port"

# --- 3. UTILITY ---
pause() { echo; read -p "   ↩ Press Enter to continue..." _; }

get_port() {
    if [ -f "$UMBREL_PORT_FILE" ]; then cat "$UMBREL_PORT_FILE"; else echo "80"; fi
}

# --- 4. HEADER ---
draw_header() {
    clear
    local user=$(whoami)
    local host=$(hostname)

    # Docker Status
    local doc_pill="${BG_RED} OFF ${RESET}"
    if command -v docker &>/dev/null; then doc_pill="${BG_GREEN} ON  ${RESET}"; fi

    # Umbrel Status
    local umb_pill="${BG_RED} OFF ${RESET}"
    if docker ps -a --format '{{.Names}}' | grep -q umbrel; then umb_pill="${BG_GREEN} ON  ${RESET}"; fi
    local umb_port=$(get_port)

    echo -e "${BG_BLUE}${BOLD}   ⚡ SERVER CONTROL CENTER | UMBREL                                      ${RESET}"
    echo -e "   ${C}User:${RESET} $user    ${GREY}|${RESET}    ${C}Host:${RESET} $host"
    echo -e "   ${M}────────────────────────────────────────────────────────────${RESET}"

    echo -e "   ${BOLD}SERVICES STATUS:${RESET}"
    printf "   ├── ${W}%-10s${RESET} %b\n" "Docker" "$doc_pill"
    printf "   └── ${W}%-10s${RESET} %b  ${GREY}➜ Port: ${Y}%s${RESET}\n" "Umbrel" "$umb_pill" "$umb_port"

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

# --- 6. UMBREL FUNCTIONS ---
install_umbrel() {
    draw_header
    install_docker

    echo -e "   ${BOLD}┌── [ INSTALL UMBREL ]${RESET}"
    echo -e "   ${BOLD}│${RESET}"
    echo -e "   ${GREY}[${Y}1${GREY}]${RESET} Default Port ${C}(80)${RESET}"
    echo -e "   ${GREY}[${Y}2${GREY}]${RESET} Custom Port"
    echo -e "   ${BOLD}│${RESET}"
    read -p "   └─➤ Select Option: " port_choice

    if [ "$port_choice" == "2" ]; then
        read -p "    ➤ Enter Custom Port: " CUSTOM_PORT
        PORT=$CUSTOM_PORT
    else
        PORT=80
    fi

    echo "$PORT" > "$UMBREL_PORT_FILE"

    echo -e "\n   ${B}[+] Installing Umbrel on port ${PORT}...${RESET}"

    docker rm -f umbrel >/dev/null 2>&1
    docker run -d --name umbrel --pid=host -p ${PORT}:80 -v "${PWD:-.}/umbrel:/data" -v "/var/run/docker.sock:/var/run/docker.sock" --stop-timeout 60 --restart=always docker.io/dockurr/umbrel

    echo -e "   ${G}[✓] Installed! Access: http://$host:${PORT}${RESET}"
    pause
}

uninstall_umbrel() {
    echo -e "\n   ${R}[!] Removing Umbrel...${RESET}"
    docker rm -f umbrel >/dev/null 2>&1
    rm -f "$UMBREL_PORT_FILE"
    echo -e "   ${G}[✓] Removed Successfully.${RESET}"
    pause
}

start_umbrel() {
    docker start umbrel
    echo -e "   ${G}[✓] Umbrel Started${RESET}"
    pause
}

stop_umbrel() {
    docker stop umbrel
    echo -e "   ${R}[!] Umbrel Stopped${RESET}"
    pause
}

restart_umbrel() {
    docker restart umbrel
    echo -e "   ${Y}[↻] Umbrel Restarted${RESET}"
    pause
}

# --- 7. UMBREL MENU ---
umbrel_menu() {
    while true; do
        draw_header
        echo -e "   ${BOLD}UMBREL OPTIONS:${RESET}"
        echo -e "   ${GREY}[${Y}1${GREY}]${RESET} ${G}Install${RESET}"
        echo -e "   ${GREY}[${Y}2${GREY}]${RESET} ${G}Turn ON${RESET}"
        echo -e "   ${GREY}[${Y}3${GREY}]${RESET} ${R}Turn OFF${RESET}"
        echo -e "   ${GREY}[${Y}4${GREY}]${RESET} ${Y}Restart${RESET}"
        echo -e "   ${GREY}[${Y}5${GREY}]${RESET} ${R}Uninstall${RESET}"
        echo -e "   ${GREY}[${R}0${GREY}]${RESET} Exit"
        echo

        read -p "   > Select: " opt
        case $opt in
            1) install_umbrel ;;
            2) start_umbrel ;;
            3) stop_umbrel ;;
            4) restart_umbrel ;;
            5) uninstall_umbrel ;;
            0) echo -e "\n   ${G}👋 Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "   ${R}Invalid option${RESET}"; sleep 1 ;;
        esac
    done
}

# --- RUN ---
umbrel_menu
