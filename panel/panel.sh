#!/bin/bash

# --- CONFIG & SEMA UI COLORS ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;220m'
ORANGE='\033[38;5;208m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# --- MODULE DEFINITIONS: "label|url" (empty url = unavailable) ---
declare -A MODULES
MODULES[1]="Pterodactyl|https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/pterodactyl/run.sh"
MODULES[2]="Jexactyl|"
MODULES[3]="JexPanel|"
MODULES[4]="Reviactyl|https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/reviactyl/run.sh"
MODULES[5]="CtrlPanel|"
MODULES[6]="Paymenter|https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/paymenter/run.sh"
MODULES[7]="Convoy|https://raw.githubusercontent.com/nobita329/hub/refs/heads/main/Codinghub/panel/convoy/run.sh"
MODULES[8]="FeatherPanel|"
MODULES[9]="Mythicaldash|https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/mythical/run.sh"
MODULES[10]="Mythicaldashv3|"
MODULES[11]="VPS Panel|"

MOD_COUNT=11
COLS=2
CELL_W=30

pause() {
    echo ""
    echo -ne "  ${GRAY}Press any key to return to grid...${NC}"
    read -n 1 -s -r
}

get_metrics() {
    UPT=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
}

# Print a centered line inside the banner box (50-char content between ║ markers)
# $1: color code, $2: text (centered within the 46-char padded area)
banner_line() {
    local color=$1 text=$2
    local text_len=${#text}
    local pad=$(( (46 - text_len) / 2 ))
    (( pad < 0 )) && pad=0
    printf "  ${PURPLE}║${NC}  ${color}%*s%s%*s${NC}  ${PURPLE}║${NC}\n" $pad "" "$text" $pad ""
}

print_banner() {
    local ts=$(date +"%H:%M %Z")
    echo -e "${PURPLE}  ╔══════════════════════════════════════════════════════╗${NC}"
    banner_line "" ""
    banner_line "${WHITE}${BOLD}" "All Panel by Nobita"
    banner_line "${GRAY}" "$(printf '%.0s─' $(seq 1 28))"
    banner_line "${GOLD}" "SERVER PANEL MANAGER  v15.0"
    banner_line "${GRAY}" "$ts"
    banner_line "" ""
    echo -e "${PURPLE}  ╚══════════════════════════════════════════════════════╝${NC}"
}

show_header() {
    get_metrics
    clear
    print_banner
    echo ""
    echo -e "  ${CYAN}${BOLD}SYSTEM STATUS${NC}"
    echo -e "  ${GRAY}├─${NC} ${DIM}Uptime${NC}   ${WHITE}$UPT${NC}"
    echo -e "  ${GRAY}├─${NC} ${DIM}Load${NC}     ${WHITE}$LOAD${NC}"
    echo -e "  ${GRAY}└─${NC} ${DIM}Modules${NC}  ${WHITE}$MOD_COUNT available${NC}"
    echo ""
}

# Print one cell in the grid
# $1 = index, $2 = name, $3 = available (true/false)
cell() {
    local idx=$1 name=$2 avail=$3
    local idx_s="[$idx]"
    if [[ "$avail" == "true" ]]; then
        printf "${GRAY}│${NC} ${GREEN}●${NC} ${PURPLE}%s${NC} ${WHITE}%s${NC}" "$idx_s" "$name"
    else
        printf "${GRAY}│${NC} ${RED}●${NC} ${GRAY}%s${NC} ${DIM}%s${NC}" "$idx_s" "$name"
    fi
    local used=$(( ${#idx_s} + 1 + ${#name} + 2 + 2 ))
    local pad=$(( CELL_W - used ))
    if (( pad > 0 )); then
        printf "${DIM}%.0s.${NC}" $(seq 1 $pad)
    fi
}

panel_menu() {
    while true; do
        show_header

        echo -e "  ${GOLD}${BOLD}  AVAILABLE DEPLOYMENTS${NC}"
        echo ""

        local i=1
        while (( i <= MOD_COUNT )); do
            local entry="${MODULES[$i]}"
            local name="${entry%%|*}"
            local url="${entry#*|}"
            local avail="false"
            [[ -n "$url" ]] && avail="true"

            cell "$i" "$name" "$avail"

            local j=$(( i + 1 ))
            if (( j <= MOD_COUNT )); then
                local entry2="${MODULES[$j]}"
                local name2="${entry2%%|*}"
                local url2="${entry2#*|}"
                local avail2="false"
                [[ -n "$url2" ]] && avail2="true"

                cell "$j" "$name2" "$avail2"
            else
                # Fill remaining space in row
                local rest=$(( CELL_W * 2 ))
                if (( rest > 0 )); then
                    printf "${DIM}%.0s.${NC}" $(seq 1 $rest)
                fi
            fi

            printf " ${GRAY}│${NC}\n"
            i=$(( i + 2 ))
        done

        echo -e "  ${GRAY}──────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${DIM}Enter number or name (partial OK). Gray = not yet available.${NC}"
        echo ""
        echo -ne "  ${CYAN}λ${NC} ${WHITE}Select [1-$MOD_COUNT] ${RED}[0=exit]${NC}:${NC} "
        read input

        if [[ "$input" == "0" ]] || [[ "${input,,}" == "exit" ]] || [[ "${input,,}" == "quit" ]] || [[ "${input,,}" == "q" ]]; then
            echo ""
            echo -e "  ${RED}Shutting down Uplink. Goodbye!${NC}"
            exit 0
        fi

        # Try numeric match first
        local found=false
        local selected=""
        if [[ "$input" =~ ^[0-9]+$ ]] && (( input >= 1 && input <= MOD_COUNT )); then
            selected=$input
            found=true
        fi

        # Try name match (case-insensitive, substring)
        if ! $found; then
            local input_lower="${input,,}"
            for k in $(seq 1 $MOD_COUNT); do
                local n="${MODULES[$k]%%|*}"
                if [[ "${n,,}" == "$input_lower" ]] || [[ "${n,,}" == *"$input_lower"* ]]; then
                    selected=$k
                    found=true
                    break
                fi
            done
        fi

        if $found; then
            local entry="${MODULES[$selected]}"
            local name="${entry%%|*}"
            local url="${entry#*|}"

            if [[ -z "$url" ]]; then
                echo -e "  ${ORANGE}⚠ Module '${name}' is not yet available.${NC}"
                sleep 1
                continue
            fi

            echo ""
            echo -e "  ${CYAN}➜${NC} ${WHITE}Launching ${BOLD}${name}${NC}${WHITE}...${NC}"
            echo ""
            bash <(curl -s --fail "$url")
            local rc=$?
            echo ""
            if (( rc == 0 )); then
                echo -e "  ${GREEN}✔ ${name} completed successfully${NC}"
            else
                echo -e "  ${RED}✖ ${name} exited with code ${rc}${NC}"
            fi
            pause
        else
            echo -e "  ${RED}⚠ Invalid selection: '${input}'${NC}"
            sleep 1
        fi
    done
}

# --- PREREQ CHECK ---
for cmd in curl sed awk; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}Missing required command: ${cmd}${NC}"
        exit 1
    fi
done

panel_menu

