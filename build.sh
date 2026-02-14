#!/usr/bin/env bash
set -euo pipefail

# ErinOS ISO build wrapper around mkarchiso
# Must be run as root on an Arch Linux system with archiso installed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${SCRIPT_DIR}/archiso-profile"
WORK_DIR="${SCRIPT_DIR}/work"
OUT_DIR="${SCRIPT_DIR}/out"

usage() {
    printf 'Usage: %s [--clean]\n' "$(basename "$0")"
    printf '  --clean   Remove work directory before building\n'
    exit 1
}

check_prerequisites() {
    if [[ $EUID -ne 0 ]]; then
        printf 'Error: must run as root (mkarchiso requires it)\n' >&2
        exit 1
    fi

    if ! command -v mkarchiso &>/dev/null; then
        printf 'Error: archiso not installed. Run: pacman -S archiso\n' >&2
        exit 1
    fi

    if [[ ! -d "${PROFILE_DIR}" ]]; then
        printf 'Error: archiso profile not found at %s\n' "${PROFILE_DIR}" >&2
        exit 1
    fi
}

clean() {
    printf 'Cleaning work directory...\n'
    rm -rf "${WORK_DIR}"
}

build() {
    mkdir -p "${OUT_DIR}"

    printf 'Building ErinOS ISO...\n'
    printf '  Profile: %s\n' "${PROFILE_DIR}"
    printf '  Work:    %s\n' "${WORK_DIR}"
    printf '  Output:  %s\n' "${OUT_DIR}"
    printf '\n'

    mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${PROFILE_DIR}"

    printf '\nBuild complete. ISO written to:\n'
    ls -lh "${OUT_DIR}"/erinos-*.iso
}

main() {
    local do_clean=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --clean) do_clean=true; shift ;;
            -h|--help) usage ;;
            *) printf 'Unknown option: %s\n' "$1" >&2; usage ;;
        esac
    done

    check_prerequisites

    if [[ "${do_clean}" == true ]]; then
        clean
    fi

    build
}

main "$@"
