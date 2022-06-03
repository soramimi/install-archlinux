#!/bin/sh
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

pacstrap $MNT base linux sudo nano git

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
grub-install --target=x86_64-efi --efi-directory=/boot -bootloader-id=GRUB_UEFI
===
chmod 700 /sbin/install-grub

cat <<=== >/sbin/update-grub
grub-mkconfig -o /boot/grub/grub.cfg
===
chmod 700 /sbin/update-grub

install-grub
update-grub

echo --- Leave chroot environment ---
=====

arch-chroot $MNT /bin/sh /root/install.sh

rm $MNT/root/install.sh
