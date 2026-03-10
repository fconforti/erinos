#!/usr/bin/env bash
# Shared helpers for ErinOS scripts (install, firstboot, console).

# ── Colors ─────────────────────────────────────────────────────
PINK=13
GREEN=82
RED=196
YELLOW=11
WHITE=15
DIM=245

# ── Logo ───────────────────────────────────────────────────────
LOGO='
███████╗██████╗ ██╗███╗   ██╗   ██████╗ ███████╗
██╔════╝██╔══██╗██║████╗  ██║  ██╔═══██╗██╔════╝
█████╗  ██████╔╝██║██╔██╗ ██║  ██║   ██║███████╗
██╔══╝  ██╔══██╗██║██║╚██╗██║  ██║   ██║╚════██║
███████╗██║  ██║██║██║ ╚████║  ╚██████╔╝███████║
╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═════╝ ╚══════╝'

# ── Output helpers ─────────────────────────────────────────
ok()   { printf "  \033[38;5;${GREEN}m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[38;5;${YELLOW}m!\033[0m %s\n" "$1"; }
fail() { printf "  \033[38;5;${RED}m✗\033[0m %s\n" "$1"; }

# ── UI helpers ─────────────────────────────────────────────
banner() {
  gum style --padding "1 0" --margin "1 0" \
    --foreground $PINK --bold \
    "$LOGO" "" "$@"
}

reveal_logo() {
  local delay="${1:-0.06}"
  echo ""
  while IFS= read -r line; do
    printf "\033[38;5;${PINK}m%s\033[0m\n" "$line"
    sleep "$delay"
  done <<< "$LOGO"
  echo ""
}

# ── Step counter ───────────────────────────────────────────
# Callers must set TOTAL_STEPS before using step()
STEP=0
step() {
  ((++STEP))
  echo ""
  gum style --foreground $PINK --bold "[$STEP/$TOTAL_STEPS] $1"
}

# ── Logging helpers ────────────────────────────────────────
# Callers must set LOG before using run_logged/try_step
run_logged() {
  local label="$1"; shift
  if "$@" >>"$LOG" 2>&1; then
    ok "$label"
  else
    fail "$label"
    return 1
  fi
}

try_step() {
  local label="$1"; shift
  while true; do
    if "$@"; then return 0; fi
    ACTION=$(gum choose --header "Step failed: ${label}" \
      "Retry" "View log" "Open shell" "Exit")
    case "$ACTION" in
      "Retry")      continue ;;
      "View log")   more "$LOG"; continue ;;
      "Open shell") bash; continue ;;
      "Exit")       exit 1 ;;
    esac
  done
}
