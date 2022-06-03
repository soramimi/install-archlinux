#!/bin/sh
if [ -z $1 ]; then
	echo "usage: sudo ./install-archlinux.sh <dir>"
	exit 1
fi

MNT=$1
MNTBOOT=$MNT/boot

if [ ! -d $MNT ]; then
	echo $MNT is not a directory
	exit 1
fi
if [ ! -d $MNTBOOT ]; then
	echo $MNTBOOT is not a directory
	exit 1
fi

echo $MNT
echo $MNTBOOT

pacstrap $MNT base linux linux-firmware sudo nano

sed -i -e 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' $MNT/etc/sudoers

genfstab -U $MNT >>/$MNT/etc/fstab

cat <<===== >$MNT/root/install.sh
echo --- Enter chroot environment ---

ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localetime
hwclock --systohc

sed -i -e s/#en_US.UTF-8/en_US.UTF-8/g -e s/#ja_JP.UTF-8/ja_JP.UTF-8/ /etc/locale.gen
locale-gen

cat <<=== >/etc/locale.conf
LANG=en_US.UTF-8
===

cat <<=== >/etc/vconsole.conf
KEYMAP=jp106
===

cat <<=== >/etc/hostname
archlinux
===

pacman -S --noconfirm grub efibootmgr dosfstools os-prober mtools

cat <<=== >/sbin/install-grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB_UEFI
===
chmod 700 /sbin/install-grub

cat <<=== >/sbin/update-grub
grub-mkconfig -o /boot/grub/grub.cfg
===
chmod 700 /sbin/update-grub

install-grub
update-grub

cat <<=== >/etc/systemd/network/20-ethernet.network
[Match]
Name=en*
[Network]
DHCP=yes
===
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl disable systemd-networkd-wait-online

mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat <<=== >/etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/agetty --autologin root --noclear %I $TERM
===

cat <<=== >/root/disable-autologin.sh
rm /etc/systemd/system/getty@tty1.service.d/override.conf
===
chmod +x /root/disable-autologin.sh

echo --- Leave chroot environment ---
=====

arch-chroot $MNT /bin/sh /root/install.sh

rm $MNT/root/install.sh
