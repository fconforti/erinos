#!/usr/bin/env bash
# erinos installer.  curl -fsSL https://erinos.ai/install.sh | bash
#
# Installs erinos for the current user on Arch Linux:
#   1. the packages erin needs, from the official Arch repos (sudo pacman -S --needed)
#   2. a clone of github.com/fconforti/erinos in ~/erinos (HTTPS, no account needed)
#   3. `erin setup`: links the CLI, the Claude conventions and skills, the boot unit, git's credential helper
#   4. git's user.useConfigOnly, the direnv hook in ~/.bashrc, and lingering (sessions come back at boot)
# It asks once before changing anything, and never runs other downloaded scripts.
# Read it first: https://github.com/fconforti/erinos/blob/main/install.sh
#
# Environment: ERINOS_YES=1 skips the question, ERINOS_REPO overrides the clone URL,
# ERINOS_SKIP_PACKAGES=1 skips pacman (other distros: install the packages yourself).
set -euo pipefail

# Everything runs inside main, so a download cut short can't run half a script.
main() {
  local repo="${ERINOS_REPO:-https://github.com/fconforti/erinos.git}" dir="$HOME/erinos"
  local packages=(git tmux direnv python curl)
  local b="" g="" y="" r="" n=""
  if [[ -t 1 ]]; then b=$'\e[1m' g=$'\e[32m' y=$'\e[33m' r=$'\e[31m' n=$'\e[0m'; fi
  say()  { echo "${g}==>${n} $*"; }
  note() { echo "${y}  !${n} $*"; }
  die()  { echo "${r}error:${n} $*" >&2; exit 1; }

  [[ "$(id -u)" -ne 0 ]] || die "run it as your own user, not root: erinos lives in your home folder"
  local pkgs=1
  [[ "${ERINOS_SKIP_PACKAGES:-0}" -eq 1 ]] && pkgs=0
  if [[ "$pkgs" -eq 1 && ! -f /etc/arch-release ]]; then
    die "erinos targets Arch Linux. On another distro install ${packages[*]} yourself, then rerun with ERINOS_SKIP_PACKAGES=1"
  fi
  if [[ -e "$dir" && ! -d "$dir/.git" ]]; then die "$dir exists and isn't a git clone: move it away first"; fi

  echo "${b}erinos${n}: a personal OS for running Claude Code on Arch Linux"
  echo
  echo "This will:"
  [[ "$pkgs" -eq 1 ]] && echo "  - sudo pacman -S --needed ${packages[*]}"
  if [[ -d "$dir/.git" ]]; then echo "  - update $dir (git pull --ff-only)"; else echo "  - clone $repo into $dir"; fi
  echo "  - run erin setup: link ~/.local/bin/erin, ~/.claude/CLAUDE.md, ~/.claude/skills/*, the erin-resume"
  echo "    user unit, and set erin as git's credential helper for github.com"
  echo "  - set git user.useConfigOnly, add the direnv hook to ~/.bashrc, enable lingering for $USER"
  echo
  if [[ "${ERINOS_YES:-0}" -ne 1 ]]; then
    local answer
    { read -rp "Continue? [y/N] " answer </dev/tty; } 2>/dev/null || die "no terminal to ask on: rerun with ERINOS_YES=1 to accept"
    [[ "$answer" =~ ^[Yy] ]] || die "cancelled, nothing changed"
  fi

  if [[ "$pkgs" -eq 1 ]]; then
    say "Installing packages"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
  fi

  if [[ -d "$dir/.git" ]]; then
    say "Updating $dir"
    git -C "$dir" pull --ff-only -q
  else
    say "Cloning erinos into $dir"
    git clone -q "$repo" "$dir"
  fi

  say "erin setup"
  "$dir/bin/erin" setup

  say "git, direnv, lingering"
  if [[ -z "$(git config --global --get user.useConfigOnly || true)" ]]; then
    git config --global user.useConfigOnly true
    echo "  git: commits need an identity from a workspace (user.useConfigOnly)"
  fi
  if [[ -z "$(git config --global --get user.name || true)" ]]; then
    note "git has no user.name: git config --global user.name 'Your Name'"
  fi
  if ! grep -qs 'direnv hook bash' "$HOME/.bashrc"; then
    printf '\n# direnv: loads each project'"'"'s .envrc (its GitHub token) (added by erinos)\neval "$(direnv hook bash)"\n' >> "$HOME/.bashrc"
    echo "  added the direnv hook to ~/.bashrc"
  fi
  if [[ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null || true)" != yes ]]; then
    sudo loginctl enable-linger "$USER" && echo "  lingering on: user services (erin-resume) start at boot"
  fi

  echo
  say "${b}erinos is installed.${n}"
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) note "~/.local/bin isn't on your PATH: add it in ~/.bashrc" ;; esac
  command -v claude >/dev/null || note "Claude Code isn't installed yet: https://code.claude.com/docs/en/setup"
  cat <<EOF

Next:
  1. Open a new shell (direnv hook, PATH).
  2. Describe this machine for Claude in ~/.config/erinos/CLAUDE.md.
  3. Create a workspace:  erin workspace new personal --email you@example.com --owner <github-user>
  4. Create a project:    erin new personal/hello
  5. Check everything:    erin doctor
EOF
}

main "$@"
