#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="erinos"
iso_label="ERINOS_$(date +%Y%m)"
iso_publisher="ErinOS <https://github.com/fconforti/erinos>"
iso_application="ErinOS — Local-first AI assistant appliance"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
            'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
            'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/usr/local/bin/erinos"]="0:0:755"
  ["/usr/local/bin/erinos-onboard"]="0:0:755"
  ["/etc/profile.d/erinos-motd.sh"]="0:0:644"
  ["/root/customize_airootfs.sh"]="0:0:755"
)
