#!/bin/bash

wifi-menu

umount /mnt/boot/efi
umount /mnt

parted -s /dev/sda mklabel gpt

parted /dev/sda mkpart msdos 2048s 411647s

parted /dev/sda set 1 esp on
parted /dev/sda set 1 boot on

parted /dev/sda mkpart ext4 411648s 21383167s

mkfs.fat -F -F32 /dev/sda1
mkfs.ext4 -F  /dev/sda2

mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

pacstrap /mnt       \
    base            \
    base-devel      \
    grub-efi-x86_64 \
    vim             \
    tmux            \
    wpa_supplicant  \
    efibootmgr

genfstab /mnt > /mnt/etc/fstab

arch-chroot /mnt /bin/bash -c "grub-install --efi-directory=/boot/efi && grub-mkconfig -o /boot/grub/grub.cfg"

# reboot
