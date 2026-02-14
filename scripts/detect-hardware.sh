#!/usr/bin/env bash
set -euo pipefail

# detect-hardware.sh — Detect RAM, GPU vendor, and VRAM for model recommendation.
# Output: key=value pairs for consumption by other scripts.

detect_ram() {
    local ram_gb
    ram_gb=$(free -g | awk '/Mem:/{print $2}')
    printf 'RAM_GB=%s\n' "${ram_gb}"
}

detect_gpu() {
    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 || echo "")

    if [[ -z "${gpu_info}" ]]; then
        printf 'GPU_VENDOR=none\n'
        printf 'GPU_NAME=none\n'
        return
    fi

    local vendor="unknown"
    if printf '%s' "${gpu_info}" | grep -qi nvidia; then
        vendor="nvidia"
    elif printf '%s' "${gpu_info}" | grep -qi amd; then
        vendor="amd"
    elif printf '%s' "${gpu_info}" | grep -qi intel; then
        vendor="intel"
    fi

    printf 'GPU_VENDOR=%s\n' "${vendor}"
    printf 'GPU_NAME=%s\n' "${gpu_info}"
}

detect_vram() {
    local vram_mb=0

    # NVIDIA via nvidia-smi
    if command -v nvidia-smi &>/dev/null; then
        vram_mb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1) || vram_mb=0
    fi

    # AMD via sysfs
    if [[ ${vram_mb} -eq 0 ]]; then
        local vram_file
        for vram_file in /sys/class/drm/card*/device/mem_info_vram_total; do
            if [[ -f "${vram_file}" ]]; then
                local vram_bytes
                vram_bytes=$(cat "${vram_file}")
                vram_mb=$((vram_bytes / 1024 / 1024))
                break
            fi
        done
    fi

    printf 'VRAM_MB=%s\n' "${vram_mb}"
}

suggest_model() {
    local ram_gb="${1}"
    local vram_mb="${2}"

    if [[ ${ram_gb} -ge 32 && ${vram_mb} -ge 16000 ]]; then
        printf 'SUGGESTED_MODEL=qwen3:30b-coder\n'
    elif [[ ${ram_gb} -ge 16 && ${vram_mb} -ge 8000 ]]; then
        printf 'SUGGESTED_MODEL=qwen3:8b\n'
    elif [[ ${ram_gb} -ge 16 ]]; then
        printf 'SUGGESTED_MODEL=llama3.2:3b\n'
    else
        printf 'SUGGESTED_MODEL=phi3:mini\n'
    fi
}

main() {
    detect_ram
    detect_gpu
    detect_vram

    # Parse for suggestion
    local ram_gb vram_mb
    ram_gb=$(free -g | awk '/Mem:/{print $2}')
    vram_mb=0
    if command -v nvidia-smi &>/dev/null; then
        vram_mb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1) || vram_mb=0
    fi
    if [[ ${vram_mb} -eq 0 ]]; then
        for f in /sys/class/drm/card*/device/mem_info_vram_total; do
            if [[ -f "${f}" ]]; then
                vram_mb=$(( $(cat "${f}") / 1024 / 1024 ))
                break
            fi
        done
    fi

    suggest_model "${ram_gb}" "${vram_mb}"
}

main "$@"
