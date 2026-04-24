#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Bootstrap Script
#
# This script installs chezmoi, configures template variables, and applies
# dotfiles on a fresh macOS or Linux system.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ericsua/dotfiles/main/setup.sh | bash
#   # or clone the repo first and run:
#   ./setup.sh
# ==============================================================================

set -euo pipefail

DOTFILES_REPO="github.com/ericsua/dotfiles"
CHEZMOI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
CHEZMOI_CONFIG_FILE="$CHEZMOI_CONFIG_DIR/chezmoi.toml"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# --- Detect OS ---
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      error "Unsupported OS: $(uname -s)" ;;
  esac
  info "Detected OS: $OS"
}

# --- Install Homebrew (macOS) ---
install_homebrew() {
  if [[ "$OS" != "macos" ]]; then return; fi
  if command -v brew &>/dev/null; then
    info "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# --- Install core dependencies ---
install_dependencies() {
  info "Installing dependencies..."

  if [[ "$OS" == "macos" ]]; then
    # Core: shell + dotfile mgr + nav + dev tools + tmux stack
    # Note: tpm is installed via brew (referenced in dot_config/tmux/tmux.conf
    # at $HOMEBREW_PREFIX/opt/tpm/share/tpm/tpm). On Linux it's bootstrapped
    # via git clone (see install_tpm() below).
    brew install chezmoi git zsh fzf zoxide pyenv uv vivid eza coreutils tmux tpm fastfetch
    # Optional but recommended
    brew install llvm libomp ngrok go
  elif [[ "$OS" == "linux" ]]; then
    # Install chezmoi
    if ! command -v chezmoi &>/dev/null; then
      sh -c "$(curl -fsLS get.chezmoi.io)"
    fi
    # Install other tools (adjust for your package manager)
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install -y git zsh fzf tmux fastfetch
      # zoxide
      if ! command -v zoxide &>/dev/null; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
      fi
      # pyenv
      if ! command -v pyenv &>/dev/null; then
        curl https://pyenv.run | bash
      fi
      # uv
      if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
      fi
    elif command -v pacman &>/dev/null; then
      sudo pacman -Syu --noconfirm git zsh fzf zoxide pyenv tmux fastfetch
    else
      warn "Unknown package manager. Install manually: git, zsh, fzf, zoxide, pyenv, uv, tmux, fastfetch"
    fi
  fi
}

# --- Install TPM (Tmux Plugin Manager) ---
# On macOS this is a no-op (tpm is installed via brew above and referenced
# in tmux.conf at $HOMEBREW_PREFIX/opt/tpm/share/tpm/tpm). On Linux we git
# clone TPM into ~/.tmux/plugins/tpm — that's also TPM's default plugin
# install location, which our tmux.conf falls back to when the brew path
# doesn't exist.
install_tpm() {
  if [[ "$OS" == "macos" ]]; then
    if [[ -e "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/tpm/share/tpm/tpm" ]]; then
      info "TPM already installed via brew"
      return
    fi
    warn "Expected brew tpm at \${HOMEBREW_PREFIX}/opt/tpm — install with: brew install tpm"
    return
  fi
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir/.git" ]]; then
    info "TPM already cloned at $tpm_dir"
    return
  fi
  info "Cloning TPM (Tmux Plugin Manager) to $tpm_dir..."
  mkdir -p "$(dirname "$tpm_dir")"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  info "TPM installed. Inside tmux, press 'prefix + I' to install configured plugins."
}

# --- Configure chezmoi template variables ---
configure_chezmoi() {
  if [[ -f "$CHEZMOI_CONFIG_FILE" ]]; then
    info "chezmoi.toml already exists at $CHEZMOI_CONFIG_FILE"
    warn "Review it to make sure all variables are set correctly"
    return
  fi

  info "Configuring chezmoi template variables..."
  mkdir -p "$CHEZMOI_CONFIG_DIR"

  echo ""
  echo "The .zshrc template requires the following variables."
  echo "Leave blank to set them later in $CHEZMOI_CONFIG_FILE"
  echo ""

  read -rp "GitLab token (primary, for NUV_INDEX): " gitlab_token
  read -rp "GitLab token (secondary, for project 374): " gitlab_token_2
  read -rp "Google Cloud project ID: " gen_project_id

  cat > "$CHEZMOI_CONFIG_FILE" <<EOF
[data]
  gitlab_token = "${gitlab_token}"
  gitlab_token_2 = "${gitlab_token_2}"
  gen_project_id = "${gen_project_id}"
EOF

  info "Created $CHEZMOI_CONFIG_FILE"
}

# --- Set zsh as default shell ---
set_default_shell() {
  if [[ "$SHELL" == *"zsh"* ]]; then
    info "zsh is already the default shell"
    return
  fi
  info "Setting zsh as the default shell..."
  chsh -s "$(which zsh)"
}

# --- Initialize and apply chezmoi ---
apply_dotfiles() {
  if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi" ]]; then
    info "Applying dotfiles with chezmoi..."
    chezmoi apply -v
  else
    info "Initializing chezmoi from $DOTFILES_REPO..."
    chezmoi init --apply "$DOTFILES_REPO"
  fi
}

# --- Main ---
main() {
  echo ""
  echo "=========================================="
  echo "  Dotfiles Bootstrap"
  echo "=========================================="
  echo ""

  detect_os
  install_homebrew
  install_dependencies
  configure_chezmoi
  set_default_shell
  apply_dotfiles
  install_tpm

  echo ""
  info "Done! Restart your terminal or run: exec zsh"
  info "Zinit will auto-install plugins on first launch."
  echo ""
}

main "$@"
