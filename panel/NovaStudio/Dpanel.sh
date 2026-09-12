#!/bin/bash

# Exit immediately if a setup command fails
set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}          DPanel Manager${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root.${NC}"
    exit 1
fi

REPO="https://github.com/nobita329/dpanel.git"
DIR="/root/dpanel"

# Check Git
if ! command -v git >/dev/null 2>&1; then
    echo -e "${YELLOW}Git not found. Installing...${NC}"
    apt-get update -y -q
    apt-get install -y -q git
    echo -e "${GREEN}[✔] Git installed.${NC}"
fi

# Clone or use existing folder
if [ -d "$DIR/.git" ]; then
    echo -e "${GREEN}Existing DPanel directory found.${NC}"
    cd "$DIR"

    echo -e "${CYAN}Updating repository...${NC}"
    git reset --hard HEAD >/dev/null 2>&1
    git pull origin main --quiet || git pull --quiet
    echo -e "${GREEN}[✔] Repository updated.${NC}"
else
    echo -e "${YELLOW}DPanel not found locally. Cloning...${NC}"
    git clone --quiet "$REPO" "$DIR"
    cd "$DIR"
    echo -e "${GREEN}[✔] Repository cloned.${NC}"
fi

# Verify run.sh exists before proceeding
if [ ! -f "run.sh" ]; then
    echo -e "${RED}[!] Error: run.sh not found in the repository!${NC}"
    exit 1
fi

chmod +x run.sh

# Disable 'exit on error' so the menu doesn't crash if a DPanel command fails
set +e 

while true; do
    clear

    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}          DPanel Manager${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Install"
    echo -e "${GREEN}2)${NC} Update"
    echo -e "${GREEN}3)${NC} Start"
    echo -e "${GREEN}4)${NC} Stop"
    echo -e "${GREEN}5)${NC} Restart"
    echo -e "${GREEN}6)${NC} Status"
    echo -e "${GREEN}7)${NC} Logs"
    echo -e "${GREEN}8)${NC} Reset Admin"
    echo -e "${GREEN}9)${NC} Uninstall"
    echo -e "${RED}0)${NC} Exit"
    echo ""
    read -rp "Select an option [0-9]: " choice
    
    echo "" # Add a blank line before output

    case "$choice" in
        1) bash run.sh install ;;
        2) bash run.sh update ;;
        3) bash run.sh start ;;
        4) bash run.sh stop ;;
        5) bash run.sh restart ;;
        6) bash run.sh status ;;
        7) bash run.sh logs ;;
        8) bash run.sh reset-admin ;;
        9)
            echo -e "${RED}WARNING: This will uninstall DPanel.${NC}"
            read -rp "Continue? [y/N]: " confirm

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                bash run.sh uninstall
            else
                echo -e "${YELLOW}Cancelled.${NC}"
            fi
            ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select a number between 0 and 9.${NC}"
            ;;
    esac

    echo ""
    read -rp "Press Enter to return to menu..."
done
