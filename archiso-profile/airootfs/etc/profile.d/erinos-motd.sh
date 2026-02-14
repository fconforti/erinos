#!/usr/bin/env bash
# ErinOS login banner

if [[ -t 0 ]]; then
    printf '\n'
    printf '  ╔═══════════════════════════════════════╗\n'
    printf '  ║           ErinOS v0.1                 ║\n'
    printf '  ║   Local-first AI assistant appliance  ║\n'
    printf '  ╚═══════════════════════════════════════╝\n'
    printf '\n'
    printf '  Run "erinos status" to check services.\n'
    printf '  Run "erinos --help" for all commands.\n'
    printf '\n'

    # Surface boot health issues
    if [[ -f /var/lib/erinos/boot-health ]]; then
        printf '  ⚠ Boot health check found issues:\n'
        while IFS= read -r line; do
            printf '    %s\n' "$line"
        done < /var/lib/erinos/boot-health
        printf '\n'
    fi

    # Surface security audit findings
    if [[ -f /var/lib/erinos/audit-findings ]]; then
        printf '  ⚠ Security audit findings pending — your assistant will report details.\n\n'
    fi
fi
