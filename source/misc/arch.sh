#!/bin/bash

wifi-menu

parted /dev/sda mklabel gpt
parted /dev/sda mkpart msdos 0 1024
parted /dev/sda1 set boot on
parted /dev/sda mkpart ext4 1024

mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt

mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

genfstab /mnt > /mnt/etc/fstab

pacstrap /mnt base base-devel grub-efi-x86_64 vim tmux wpa_supplicant efibootmgr

arch-chroot /mnt -x <<'EOF'
    grub-install
    grub-mkconfig -o /boot/grub/grub.cfg
EOF

reboot
