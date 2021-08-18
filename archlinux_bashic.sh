#!/bin/bash
echo "============================================="
echo "Setting Time"
#$(timedatectl set-ntp true)

echo "Time Status is: $(timedatectl status)"
echo "---------------------------------------------"
echo "Verifing if EFI"
if [[ -d '/sys/firmware/efi/efivars' ]]; then
    echo "Non-Efi"
else
    echo "Setup EFI setup"
fi
echo "---------------------------------------------"
echo "Testing for network connectivity"
if [[ -z $(ip link | grep enp) ]]; then
    echo 'Error connecting to network'
    exit 1    
else
    echo "Network is ready"
    $(ping -c 1 archlinux.org)
    if [[ $? -eq 0 ]]; then
        echo 'Network is open'
        echo 'Sync Archlinx Repos'
        $(pacman -Sy)
    else
        echo 'Network Issues'
        echo 'Stopping Installer'
        exit 1
    fi
fi
echo "---------------------------------------------"

echo "Checking for sda.fdisk file"
if [[ -e ./sda.fdisk ]]; then
    echo 'Running sfdisk on sda.fdisk'
    sfdisk /dev/sda < sda.fdisk
else
    echo 'File does not exist'
    exit 1
fi
echo "---------------------------------------------"
ROOT='/dev/sda3'
SWAP='/dev/sda2'
BOOT='/dev/sda1'

echo 'Formating Root'
mkfs.ext4 $ROOT
echo 'Formating Swap'
mkswap $SWAP
echo "======================//====================="
echo "PreProcess Complete"
echo "======================//====================="
echo "Setting up mounts"
mount $ROOT /mnt
swapon $SWAP
echo "---------------------------------------------"
packagelist='base linux linux-firmware vim openssh'
pacstrap /mnt $packagelist
genfstab -U /mnt >> /mnt/etc/fstab
echo "---------------------------------------------"
echo "Inserting Networking Config File"
networkDir='/etc/systemd/network/'
if [[ -d $networkDir]]; then
    cat ./networking.config > /etc/systemd/network/20-wired.network
else
    echo 'Error occured directory does not exsists'
fi
echo "---------------------------------------------"
echo "Inserting Networking Config File"
gunzip Linux_terminal_color.zip
cp ./bash.bashrc /mnt/etc/bash.bashrc
if [[ $(sha256sum -t ./.bash.bashrc ) != $(sha256sum -t /mnt/etc/bash.bashrc) ]]; then
    echo "bash.bashrc File BAD"
    exit 1
fi
cp ./DIR_COLORS /mnt/etc/
if [[ $(sha256sum -t ./DIR_COLORS ) != $(sha256sum -t /mnt/etc/DIR_COLORS) ]]; then
    echo "DIR_COLOR File BAD"
    exit 1
fi
rm ./.bashrc bash.bashrc DIR_COLORS
echo 'Setting up Time'
arch-chroot /mnt ln -sf /usr/share/zoneinfo/US/Central /etc/localtime
arch-chroot /mnt echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
echo '---------------------------------------------'
echo 'Installing Bootloader'
arch-chroot /mnt grub-install --target=i386-pc /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg