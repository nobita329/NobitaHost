#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================${NC}"
echo -e "          ${YELLOW}APanel Auto Installer${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root.${NC}"
    exit 1
fi

REPO="https://github.com/nobita329/apanel.git"
DIR="apanel"

echo -e "${CYAN}[1/3]${NC} Checking for Git..."

if ! command -v git >/dev/null 2>&1; then
    echo -e "${YELLOW}      Git not found. Installing Git...${NC}"
    apt-get update -y -q
    apt-get install -y -q git
    echo -e "${GREEN}      [✔] Git installed successfully.${NC}"
else
    echo -e "${GREEN}      [✔] Git is already installed.${NC}"
fi

echo -e "${CYAN}[2/3]${NC} Preparing APanel repository..."

if [ -d "$DIR/.git" ]; then
    echo -e "${YELLOW}      Existing APanel directory found.${NC}"
    cd "$DIR"

    echo -e "${CYAN}      Updating existing repository...${NC}"
    # Discard any local changes to prevent merge conflicts when pulling
    git reset --hard HEAD >/dev/null 2>&1
    git pull origin main --quiet || git pull --quiet
    echo -e "${GREEN}      [✔] Repository updated.${NC}"

else
    echo -e "${YELLOW}      APanel not found locally. Cloning...${NC}"
    git clone --quiet "$REPO" "$DIR"
    cd "$DIR"
    echo -e "${GREEN}      [✔] Repository cloned.${NC}"
fi

echo -e "${CYAN}[3/3]${NC} Starting APanel installer..."

# Verify the install script actually exists before running it
if [ -f "install.sh" ]; then
    chmod +x install.sh
    bash install.sh
else
    echo -e "${RED}[!] Error: install.sh not found in the repository!${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}        [✔] APanel Setup Completed${NC}"
echo -e "${CYAN}======================================${NC}"
