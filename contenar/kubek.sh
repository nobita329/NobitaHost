#!/bin/bash

# ==========================================
# KUBEK SERVER CONTROL CENTER
# ==========================================

BG_BLUE="\e[44;97m"; BG_GREEN="\e[42;97m"; BG_RED="\e[41;97m"
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[97m"; GREY="\e[90m"
RESET="\e[0m"; BOLD="\e[1m"

# Fixed permission issue by using user home directory
PORT_FILE="$HOME/.kubek_port"

pause(){ echo; read -p "Press Enter to continue..." _; }

get_port(){
    [ -f "$PORT_FILE" ] && cat "$PORT_FILE" || echo "8000"
}

install_docker(){
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${B}Installing Docker...${RESET}"
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
}

draw_header(){
    clear
    local host=$(hostname)
    local port=$(get_port)

    local docker_status="${BG_RED} OFF ${RESET}"
    command -v docker >/dev/null 2>&1 && docker_status="${BG_GREEN} ON ${RESET}"

    local kubek_status="${BG_RED} OFF ${RESET}"
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^kubek$' && kubek_status="${BG_GREEN} ON ${RESET}"

    echo -e "${BG_BLUE}${BOLD} KUBEK SERVER CONTROL CENTER ${RESET}"
    echo
    echo -e " Host   : $host"
    echo -e " Docker : $docker_status"
    echo -e " Kubek  : $kubek_status"
    echo -e " Port   : ${Y}$port${RESET}"
    echo -e "${GREY}------------------------------------------${RESET}"
}

install_kubek(){
    draw_header
    install_docker
    read -p "Port [8000]: " PORT
    PORT=${PORT:-8000}
    
    # Check if port is already in use before trying to run container
    if ss -tuln | grep -q ":${PORT} "; then
        echo -e "\n${R}Error: Port ${PORT} is already in use by another process!${RESET}"
        pause
        return
    fi

    echo "$PORT" > "$PORT_FILE"
    docker rm -f kubek >/dev/null 2>&1
    docker volume create kubek-data >/dev/null 2>&1
    
    if docker run -d \
      --name kubek \
      --restart unless-stopped \
      -p ${PORT}:8000 \
      -v kubek-data:/data \
      seeroy/kubek-minecraft-dashboard:latest >/dev/null 2>&1; then
        echo -e "\n${G}Kubek installed successfully!${RESET}"
        echo -e "Open: http://$(hostname -I | awk '{print $1}'):${PORT}"
    else
        echo -e "\n${R}Failed to start Docker container. Check port availability or Docker daemon.${RESET}"
    fi
    pause
}

start_kubek(){ docker start kubek; pause; }
stop_kubek(){ docker stop kubek; pause; }
restart_kubek(){ docker restart kubek; pause; }
terminal_kubek(){ docker exec -it kubek /bin/bash; pause; }

logs_kubek(){
    echo -e "${C}Fetching Logs... (Press Ctrl+C to exit logs)${RESET}\n"
    docker logs -f kubek
}

uninstall_kubek(){
    echo -e "${R}Are you sure you want to remove Kubek? (y/n)${RESET}"
    read -p "> " confirm
    if [[ "$confirm" == "y" ]]; then
        docker rm -f kubek
        rm -f "$PORT_FILE"
        echo "Kubek removed."
    fi
    pause
}

while true; do
    draw_header
    echo -e "${G}1)${RESET} Install "
    echo -e "${G}2)${RESET} Start"
    echo -e "${G}3)${RESET} Stop"
    echo -e "${G}4)${RESET} Restart"
    echo -e "${G}5)${RESET} Terminal (Console)"
    echo -e "${G}6)${RESET} Logs (Info/Status)"
    echo -e "${R}7)${RESET} Uninstall"
    echo -e "${W}0)${RESET} Exit"
    echo
    read -p "Select Option: " c

    case "$c" in
        1) install_kubek ;;
        2) start_kubek ;;
        3) stop_kubek ;;
        4) restart_kubek ;;
        5) terminal_kubek ;;
        6) logs_kubek ;;
        7) uninstall_kubek ;;
        0) exit 0 ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
