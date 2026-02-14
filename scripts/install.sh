#!/usr/bin/env bash
set -euo pipefail

# install.sh — ErinOS disk installer
# Handles: disk selection → GPT partitioning → LUKS encryption → mkfs →
# pacstrap → fstab → GRUB with LUKS unlock → create erin user → enable services → reboot.
#
# Must be run as root from the live ISO environment.

die() { printf 'install: %s\n' "$1" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "must run as root"

# ── Disk selection ───────────────────────────────────────────────────────────

select_disk() {
    printf 'Available disks:\n\n'
    lsblk -d -o NAME,SIZE,MODEL -n | grep -v '^loop\|^sr\|^ram'
    printf '\n'

    local disk
    read -r -p 'Enter disk to install to (e.g., sda): ' disk
    DISK="/dev/${disk}"

    if [[ ! -b "${DISK}" ]]; then
        die "not a block device: ${DISK}"
    fi

    printf '\nWARNING: All data on %s will be destroyed.\n' "${DISK}"
    read -r -p 'Type "YES" to continue: ' confirm
    [[ "${confirm}" == "YES" ]] || die "aborted"
}

# ── Partitioning (GPT) ──────────────────────────────────────────────────────

partition_disk() {
    printf '\nPartitioning %s...\n' "${DISK}"

    # Create GPT table: 512M EFI + 512M boot + rest for LUKS
    sgdisk --zap-all "${DISK}"
    sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "${DISK}"
    sgdisk -n 2:0:+512M -t 2:8300 -c 2:"boot" "${DISK}"
    sgdisk -n 3:0:0 -t 3:8309 -c 3:"luks" "${DISK}"

    partprobe "${DISK}"
    sleep 2

    # Detect partition naming (nvme vs sd)
    if [[ "${DISK}" == *nvme* ]]; then
        PART_EFI="${DISK}p1"
        PART_BOOT="${DISK}p2"
        PART_LUKS="${DISK}p3"
    else
        PART_EFI="${DISK}1"
        PART_BOOT="${DISK}2"
        PART_LUKS="${DISK}3"
    fi
}

# ── LUKS encryption ─────────────────────────────────────────────────────────

setup_luks() {
    printf '\nSetting up LUKS encryption...\n'
    printf 'You will be prompted to set an encryption passphrase.\n\n'

    cryptsetup luksFormat --type luks2 "${PART_LUKS}"
    cryptsetup luksOpen "${PART_LUKS}" cryptroot
}

# ── Filesystems ──────────────────────────────────────────────────────────────

create_filesystems() {
    printf '\nCreating filesystems...\n'

    mkfs.fat -F32 "${PART_EFI}"
    mkfs.ext4 -L boot "${PART_BOOT}"
    mkfs.ext4 -L erinos /dev/mapper/cryptroot
}

# ── Mount ────────────────────────────────────────────────────────────────────

mount_filesystems() {
    printf '\nMounting filesystems...\n'

    mount /dev/mapper/cryptroot /mnt
    mkdir -p /mnt/boot
    mount "${PART_BOOT}" /mnt/boot
    mkdir -p /mnt/boot/efi
    mount "${PART_EFI}" /mnt/boot/efi
}

# ── Install base system ─────────────────────────────────────────────────────

install_base() {
    printf '\nInstalling base system...\n'

    pacstrap /mnt base linux linux-firmware grub efibootmgr \
        networkmanager openssh firewalld docker tailscale \
        nodejs-lts-iron npm ollama \
        gum qrencode \
        htop tmux neovim git curl wget jq \
        cryptsetup lvm2 mkinitcpio \
        bash-completion man-db man-pages pciutils lshw \
        dosfstools e2fsprogs sudo

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

# ── Configure installed system ───────────────────────────────────────────────

configure_system() {
    printf '\nConfiguring system...\n'

    # Copy ErinOS files from live ISO to installed system
    local erinos_dirs=(
        "etc/ssh/sshd_config.d"
        "etc/firewalld/zones"
        "etc/systemd/resolved.conf.d"
        "etc/systemd/system"
        "etc/docker"
        "etc/profile.d"
        "etc/skel"
        "usr/local/bin"
    )

    for dir in "${erinos_dirs[@]}"; do
        if [[ -d "/${dir}" ]]; then
            mkdir -p "/mnt/${dir}"
            cp -a "/${dir}/." "/mnt/${dir}/"
        fi
    done

    # Configure GRUB for LUKS
    local luks_uuid
    luks_uuid=$(blkid -s UUID -o value "${PART_LUKS}")

    arch-chroot /mnt bash -c "
        set -euo pipefail

        # Timezone
        ln -sf /usr/share/zoneinfo/UTC /etc/localtime
        hwclock --systohc

        # Locale
        printf 'en_US.UTF-8 UTF-8\n' > /etc/locale.gen
        locale-gen
        printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf

        # Hostname
        printf 'erinos\n' > /etc/hostname

        # mkinitcpio — add encrypt hook
        sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
        mkinitcpio -P

        # GRUB
        sed -i 's|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${luks_uuid}:cryptroot root=/dev/mapper/cryptroot\"|' /etc/default/grub
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ErinOS
        grub-mkconfig -o /boot/grub/grub.cfg

        # Create erin user
        useradd -m -G wheel,docker -s /bin/bash erin
        printf '%s\n' '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel-nopasswd
        chmod 440 /etc/sudoers.d/wheel-nopasswd

        # ErinOS state directory
        mkdir -p /var/lib/erinos
        chmod 750 /var/lib/erinos

        # Resolv.conf
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

        # Enable services
        systemctl enable NetworkManager sshd firewalld docker tailscaled ollama
        systemctl enable erinos-onboard erinos-health erinos-update.timer
        systemctl enable systemd-resolved
    "
}

# ── Finish ───────────────────────────────────────────────────────────────────

finish() {
    printf '\nInstallation complete!\n'
    printf 'Set a password for the erin user:\n'
    arch-chroot /mnt passwd erin

    printf '\nUnmounting...\n'
    umount -R /mnt
    cryptsetup close cryptroot

    printf '\nRemove the installation media and reboot.\n'
    read -r -p 'Press Enter to reboot...'
    reboot
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
    printf 'ErinOS Installer\n\n'
    printf 'This will install ErinOS with full-disk encryption.\n\n'

    select_disk
    partition_disk
    setup_luks
    create_filesystems
    mount_filesystems
    install_base
    configure_system
    finish
}

main "$@"
