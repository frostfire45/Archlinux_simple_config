#!/bin/bash
local=$(pwd)
echo "============================================="
echo "Loading Files For pacman"
#cat "$local"/pacman.conf > /etc/pacman.conf
cat $local/mirrorlist > /etc/pacman.d/mirrorlist
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
    ping -c 1 archlinux.org
    if [[ $? -eq 0 ]]; then
        echo 'Network is open'
        echo 'Sync Archlinx Repos'
	pacman -Sy --noconfirm 
	pacman -S --noconfirm unzip
    else
        echo 'Network Issues'
        echo 'Stopping Installer'
        exit 1
    fi
fi
echo "---------------------------------------------"

echo "Checking for sda.fdisk file"
if [[ -e $local/sda.fdisk50 ]]; then
    echo 'Running sfdisk on sda.fdisk'
    sfdisk /dev/sda < ./sda.fdisk
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
if [[ -d $networkDir ]] ; then
    cat $local/networking.config > /etc/systemd/network/20-wired.network
else
    echo 'Error occured directory does not exsists'
fi
echo "---------------------------------------------"
echo "Inserting Networking Config File"
unzip $local/Linux_terminal_color.zip
cp $local/bash.bashrc /mnt/etc/bash.bashrc
comp1=$(cat $local/bash.bashrc | sha256sum )
comp2=$(cat /mnt/etc/bash.bashrc | sha256sum )
if [[ $comp1  != $comp2 ]] ; then
    echo "bash.bashrc File BAD"
    exit 1
fi
cp $local/DIR_COLORS /mnt/etc/
comp1=$(cat $local/DIR_COLORS | sha256sum)
comp2=$(cat /mnt/etc/DIR_COLORS | sha256sum)
if [[ $comp1 != $comp2 ]] ; then
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
arch-chroot /mnt pacman -S --noconfirm grub
grub-install --target=i386-pc --boot-directory=/mnt/boot/ /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
