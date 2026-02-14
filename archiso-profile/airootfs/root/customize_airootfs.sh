#!/usr/bin/env bash
set -euo pipefail

# customize_airootfs.sh — runs inside the airootfs chroot during ISO build.
# Sets up users, enables services, and prepares the system for first boot.

# Create the erin user (no password — login via SSH key only)
useradd -m -G wheel,docker -s /bin/bash erin

# Allow wheel group to use sudo without password (for onboarding, locked down after)
printf '%s\n' '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel-nopasswd
chmod 440 /etc/sudoers.d/wheel-nopasswd

# Create ErinOS state directory
mkdir -p /var/lib/erinos
chmod 750 /var/lib/erinos

# Enable services
systemctl enable NetworkManager.service
systemctl enable sshd.service
systemctl enable firewalld.service
systemctl enable docker.service
systemctl enable tailscaled.service
systemctl enable ollama.service
systemctl enable erinos-onboard.service
systemctl enable erinos-health.service
systemctl enable erinos-update.timer
systemctl enable systemd-resolved.service

# Set default firewall zone
# Physical interfaces get the "public" zone (no open ports)
# tailscale0 gets the "tailscale" zone (SSH allowed) — defined in zone XML

# Symlink resolv.conf to systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Set hostname
printf 'erinos\n' > /etc/hostname

# Set timezone to UTC (user can change during onboarding)
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Generate locale
printf 'en_US.UTF-8 UTF-8\n' > /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
