#!/usr/bin/env bash
set -euo pipefail

# update.sh — Daily update logic for ErinOS
# Called by erinos-update.service via the erinos CLI.
# This script is sourced by "erinos update" — see the CLI for the wrapper.

# This file exists as the canonical reference for the update procedure.
# The actual implementation lives in the erinos CLI (cmd_update).
# Keeping it here for documentation and potential standalone use.

printf 'update.sh: Use "sudo erinos update" instead.\n' >&2
exit 1
