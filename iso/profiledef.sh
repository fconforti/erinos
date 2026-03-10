#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="erinos"
iso_label="ERINOS_$(date --utc +%Y%m%d)"
iso_publisher="ErinOS <https://github.com/fconforti/erinos>"
iso_application="ErinOS Installer"
iso_version="$(date --utc +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi-x64.systemd-boot.esp')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15')
file_permissions=(
  ["/usr/local/bin/erinos-install"]="0:0:755"
  ["/usr/local/bin/erinos-firstboot"]="0:0:755"
  ["/usr/local/bin/erinos-console"]="0:0:755"
)
