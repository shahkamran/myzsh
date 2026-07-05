#!/usr/bin/env bash
#
# myzsh installer
# Installs myzsh framework to ~/.myzsh and configures your shell
#

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

MYZSH_DIR="${HOME}/.myzsh"
MYZSH_CACHE_DIR="${HOME}/.cache/myzsh"
MYZSH_DATA_DIR="${HOME}/.local/share/myzsh"
ZSHRC_LINK="${HOME}/.zshrc"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { printf "${CYAN}▸${RESET} %s\n" "$1"; }
success() { printf "${GREEN}✔${RESET} %s\n" "$1"; }
warn()    { printf "${YELLOW}⚠${RESET} %s\n" "$1"; }
error()   { printf "${RED}✖${RESET} %s\n" "$1" >&2; }
die()     { error "$1"; exit 1; }

print_banner() {
    printf "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║              ███╗   ███╗██╗   ██╗███████╗███████╗██╗  ██╗║"
    echo "║              ████╗ ████║╚██╗ ██╔╝╚══███╔╝██╔════╝██║  ██║║"
    echo "║              ██╔████╔██║ ╚████╔╝   ███╔╝ ███████╗███████║║"
    echo "║              ██║╚██╔╝██║  ╚██╔╝   ███╔╝  ╚════██║██╔══██║║"
    echo "║              ██║ ╚═╝ ██║   ██║   ███████╗███████║██║  ██║║"
    echo "║              ╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝║"
    echo "║                                                          ║"
    echo "║                    zsh framework installer               ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# Pre-flight checks
# ─────────────────────────────────────────────────────────────────────────────

print_banner

info "Running pre-flight checks..."

# Check for zsh
if ! command -v zsh &>/dev/null; then
    die "zsh is not installed. Please install zsh first and re-run this script."
fi

ZSH_VERSION_STR=$(zsh --version | head -1)
success "Found zsh: ${ZSH_VERSION_STR}"

# Check for git (needed for submodules)
if ! command -v git &>/dev/null; then
    die "git is not installed. Please install git first and re-run this script."
fi
success "Found git: $(git --version)"

# ─────────────────────────────────────────────────────────────────────────────
# Install myzsh
# ─────────────────────────────────────────────────────────────────────────────

echo ""
info "Installing myzsh to ${MYZSH_DIR}..."

# Clone or copy the repo to ~/.myzsh
if [[ "${REPO_DIR}" == "${MYZSH_DIR}" ]]; then
    success "Already running from ${MYZSH_DIR}, skipping copy."
elif [[ -d "${MYZSH_DIR}" ]]; then
    warn "${MYZSH_DIR} already exists."
    printf "   Overwrite? [y/N] "
    read -r answer
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        rm -rf "${MYZSH_DIR}"
        info "Removed existing ${MYZSH_DIR}"
    else
        die "Installation cancelled. Remove ${MYZSH_DIR} manually or re-run with overwrite."
    fi
fi

if [[ "${REPO_DIR}" != "${MYZSH_DIR}" ]]; then
    if [[ -d "${REPO_DIR}/.git" ]]; then
        # It's a git repo — clone it
        info "Cloning repository to ${MYZSH_DIR}..."
        git clone "${REPO_DIR}" "${MYZSH_DIR}" --quiet
        success "Cloned repository."
    else
        # Not a git repo — copy it
        info "Copying files to ${MYZSH_DIR}..."
        cp -R "${REPO_DIR}" "${MYZSH_DIR}"
        success "Copied files."
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Git submodules (plugins)
# ─────────────────────────────────────────────────────────────────────────────

if [[ -f "${MYZSH_DIR}/.gitmodules" ]]; then
    info "Initializing git submodules (plugins)..."
    (cd "${MYZSH_DIR}" && git submodule init --quiet && git submodule update --quiet --recursive)
    success "Submodules initialized and updated."
else
    info "No .gitmodules found, skipping submodule init."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Back up existing .zshrc
# ─────────────────────────────────────────────────────────────────────────────

echo ""
if [[ -e "${ZSHRC_LINK}" || -L "${ZSHRC_LINK}" ]]; then
    BACKUP_FILE="${HOME}/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    if [[ -L "${ZSHRC_LINK}" ]]; then
        # It's a symlink — just remove it
        info "Removing existing .zshrc symlink..."
        rm -f "${ZSHRC_LINK}"
        success "Removed old symlink."
    else
        # It's a real file — back it up
        info "Backing up existing .zshrc to ${BACKUP_FILE}..."
        cp "${ZSHRC_LINK}" "${BACKUP_FILE}"
        rm -f "${ZSHRC_LINK}"
        success "Backed up .zshrc → ${BACKUP_FILE}"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Create symlink
# ─────────────────────────────────────────────────────────────────────────────

info "Creating symlink: ~/.zshrc → ~/.myzsh/zshrc"
if [[ ! -f "${MYZSH_DIR}/zshrc" ]]; then
    die "Cannot find ${MYZSH_DIR}/zshrc — installation may be incomplete."
fi

ln -sf "${MYZSH_DIR}/zshrc" "${ZSHRC_LINK}"
success "Symlink created."

# ─────────────────────────────────────────────────────────────────────────────
# Create cache and data directories
# ─────────────────────────────────────────────────────────────────────────────

echo ""
info "Creating cache and data directories..."

mkdir -p "${MYZSH_CACHE_DIR}"
mkdir -p "${MYZSH_DATA_DIR}"

# Set restrictive permissions (owner only)
chmod 700 "${MYZSH_DIR}"
chmod 700 "${MYZSH_CACHE_DIR}"
chmod 700 "${MYZSH_DATA_DIR}"

success "Created ${MYZSH_CACHE_DIR}"
success "Created ${MYZSH_DATA_DIR}"
success "Permissions set to 700 (owner-only)"

# ─────────────────────────────────────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────────────────────────────────────

echo ""
printf "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║           ✨ myzsh installed successfully! ✨            ║"
echo "║                                                          ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║   Config:  ~/.myzsh/myzsh.conf                          ║"
echo "║   Themes:  ~/.myzsh/themes/                             ║"
echo "║   Aliases: ~/.myzsh/aliases/                            ║"
echo "║   Funcs:   ~/.myzsh/functions/                          ║"
echo "║                                                          ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
printf "║   Run: ${RESET}${BOLD}exec zsh${GREEN}${BOLD}  to reload your shell              ║\n"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
printf "${RESET}\n"
