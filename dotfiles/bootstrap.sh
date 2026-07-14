#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC_SOURCE="$SCRIPT_DIR/zshrc"

if [[ ${EUID:-$(id -u)} -eq 0 && -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
else
  TARGET_USER="$(id -un)"
  TARGET_HOME="$HOME"
fi

TARGET_GROUP="$(id -gn "$TARGET_USER")"
ZSHRC_TARGET="$TARGET_HOME/.zshrc"
BASHRC_TARGET="$TARGET_HOME/.bashrc"
OH_MY_ZSH_DIR="$TARGET_HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"

run_as_target() {
  local command="$1"

  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    bash -lc "$command"
  else
    sudo -u "$TARGET_USER" -H bash -lc "$command"
  fi
}

set_target_ownership() {
  local path="$1"

  if [[ ${EUID:-$(id -u)} -eq 0 && -e "$path" ]]; then
    chown "$TARGET_USER:$TARGET_GROUP" "$path"
  fi
}

write_default_zshrc() {
  cat > "$ZSHRC_TARGET" <<'EOF'
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Enable command auto-completion
autoload -U compinit
compinit

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Disable update checks
DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Use lsd when available, otherwise fallback to ls.
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd --group-dirs=first --long --icon=never'
fi
EOF

  set_target_ownership "$ZSHRC_TARGET"
}

if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "[1/7] Installing base packages..."
$SUDO apt update -y
$SUDO apt install -y zsh git curl || true
$SUDO apt install -y lsd || true

echo "[2/7] Installing Oh My Zsh..."
if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
  run_as_target "export HOME='$TARGET_HOME'; RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"
fi

echo "[3/7] Installing plugins..."
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  run_as_target "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git '$ZSH_CUSTOM/plugins/zsh-syntax-highlighting'"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  run_as_target "git clone https://github.com/zsh-users/zsh-autosuggestions.git '$ZSH_CUSTOM/plugins/zsh-autosuggestions'"
fi

echo "[4/7] Installing theme..."
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  run_as_target "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '$ZSH_CUSTOM/themes/powerlevel10k'"
fi

echo "[5/7] Writing ~/.zshrc..."
if [[ -f "$ZSHRC_TARGET" ]]; then
  backup_path="$ZSHRC_TARGET.bak.$(date +%Y%m%d%H%M%S)"
  cp "$ZSHRC_TARGET" "$backup_path"
  set_target_ownership "$backup_path"
fi

if [[ -f "$ZSHRC_SOURCE" ]]; then
  cp "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
  set_target_ownership "$ZSHRC_TARGET"
else
  echo "Template not found at $ZSHRC_SOURCE, using built-in default."
  write_default_zshrc
fi

echo "[6/7] Enabling zsh for future bash sessions..."
if [[ ! -f "$BASHRC_TARGET" ]]; then
  run_as_target "touch '$BASHRC_TARGET'"
fi

if ! grep -Fq 'if [ -t 1 ]; then exec zsh; fi' "$BASHRC_TARGET"; then
  echo 'if [ -t 1 ]; then exec zsh; fi' >> "$BASHRC_TARGET"
  set_target_ownership "$BASHRC_TARGET"
fi

echo "[7/7] Switching current shell..."
if [[ -t 0 && -z "${SETUPTERMINAL_NO_EXEC:-}" ]]; then
  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    exec zsh -l
  else
    exec sudo -u "$TARGET_USER" -H zsh -l
  fi
fi

echo "Done. Run: zsh"
