#!/usr/bin/env bash
#
# myzsh uninstaller
# Removes myzsh framework and restores previous configuration
#

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

MYZSH_DIR="${HOME}/.myzsh"
MYZSH_CACHE_DIR="${HOME}/.cache/myzsh"
MYZSH_DATA_DIR="${HOME}/.local/share/myzsh"
ZSHRC_LINK="${HOME}/.zshrc"

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

print_banner() {
    printf "${BOLD}${RED}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║              myzsh — uninstaller                         ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# Confirmation
# ─────────────────────────────────────────────────────────────────────────────

print_banner

printf "${YELLOW}This will remove myzsh from your system.${RESET}\n"
printf "Continue? [y/N] "
read -r confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
    info "Uninstall cancelled."
    exit 0
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Remove .zshrc symlink
# ─────────────────────────────────────────────────────────────────────────────

if [[ -L "${ZSHRC_LINK}" ]]; then
    LINK_TARGET="$(readlink "${ZSHRC_LINK}")"
    if [[ "${LINK_TARGET}" == *"myzsh"* || "${LINK_TARGET}" == "${MYZSH_DIR}/zshrc" ]]; then
        info "Removing .zshrc symlink (pointed to ${LINK_TARGET})..."
        rm -f "${ZSHRC_LINK}"
        success "Removed ~/.zshrc symlink."
    else
        warn "~/.zshrc is a symlink but does not point to myzsh (→ ${LINK_TARGET}). Skipping."
    fi
elif [[ -f "${ZSHRC_LINK}" ]]; then
    warn "~/.zshrc is a regular file (not a myzsh symlink). Leaving it in place."
else
    info "No ~/.zshrc found, nothing to remove."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Restore backup .zshrc
# ─────────────────────────────────────────────────────────────────────────────

echo ""
BACKUP_FILES=( $(ls -t "${HOME}"/.zshrc.backup.* 2>/dev/null || true) )

if [[ ${#BACKUP_FILES[@]} -gt 0 ]]; then
    LATEST_BACKUP="${BACKUP_FILES[0]}"
    info "Found backup: ${LATEST_BACKUP}"
    printf "   Restore this backup as ~/.zshrc? [Y/n] "
    read -r restore_answer
    if [[ ! "${restore_answer}" =~ ^[Nn]$ ]]; then
        cp "${LATEST_BACKUP}" "${ZSHRC_LINK}"
        success "Restored ${LATEST_BACKUP} → ~/.zshrc"
    else
        info "Skipping backup restore."
    fi

    if [[ ${#BACKUP_FILES[@]} -gt 1 ]]; then
        info "Other backups found:"
        for f in "${BACKUP_FILES[@]:1}"; do
            echo "     ${f}"
        done
    fi
else
    info "No .zshrc backup files found."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Remove cache and data directories
# ─────────────────────────────────────────────────────────────────────────────

echo ""
if [[ -d "${MYZSH_CACHE_DIR}" ]]; then
    info "Removing cache directory: ${MYZSH_CACHE_DIR}"
    rm -rf "${MYZSH_CACHE_DIR}"
    success "Removed ${MYZSH_CACHE_DIR}"
fi

if [[ -d "${MYZSH_DATA_DIR}" ]]; then
    info "Removing data directory: ${MYZSH_DATA_DIR}"
    rm -rf "${MYZSH_DATA_DIR}"
    success "Removed ${MYZSH_DATA_DIR}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Optionally remove ~/.myzsh
# ─────────────────────────────────────────────────────────────────────────────

echo ""
if [[ -d "${MYZSH_DIR}" ]]; then
    printf "${YELLOW}▸${RESET} Remove ${MYZSH_DIR} entirely? [y/N] "
    read -r remove_dir
    if [[ "${remove_dir}" =~ ^[Yy]$ ]]; then
        rm -rf "${MYZSH_DIR}"
        success "Removed ${MYZSH_DIR}"
    else
        info "Keeping ${MYZSH_DIR} in place."
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────────────────────────────────────

echo ""
printf "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║           🧹 myzsh has been uninstalled.                 ║"
echo "║                                                          ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║   Your shell will use the default config on next launch. ║"
echo "║   Run: exec zsh  or open a new terminal.                 ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
printf "${RESET}\n"
