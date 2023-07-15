# VMCLI

A set of utilities to help you manage VMs with `Virtualization.framework`

## Installation

### Prerequisites

* macOS Ventura (13+)
* XCode.app installed

```
# make sure xcode command-line tools are installed
xcode-select --install

# run build (produces ./build/vmcli)
make
```

## Arch Linux from scratch

Preparations:

```bash
# PWD=./

mkdir arch && cd arch # this will contain all vm related data

# prepare disk image (eg. 20GiB)
dd if=/dev/null of="$(pwd)/disk.img" bs=1m count=0 seek=20000
```

Fetch [archboot](https://archboot.com/) images:

```bash
# PWD=./arch

mkdir archboot && cd archboot

# Fetch archboot's linux kernel image
wget -O linux.gz "https://archboot.com/iso/aarch64/latest/boot/Image-aarch64.gz"
gzip -d linux.gz

# Fetch archboot's initrd
wget -O initrd https://archboot.com/iso/aarch64/latest/boot/initrd-aarch64.img
```

Boot archboot:

```bash
# PWD=./arch

# Boot archboot and use the `disk.img` image
# Note: archboot requires somewhat >1GB ram to boot
vmcli -b linux -k ./archboot/linux --initrd ./archboot/initrd -d ./disk.img -m 1536 --cmdline "console=hvc0 irqaffinity=0 mitigations=off root=/dev/vda"

# Follow the archboot instructions
# Tip: Just exit/cancel the initial setup and use the default configuration, so you get faster to a working shell.

    [root@archboot /]#

```

Inside archboot, continue with a basic Arch Linux installation.

Requirements:

- Partition table should preferrably be GPT
- Virtualization.framework supports booting EFI compatible systems, so make sure your installation is "EFI supported", that includes having a EFI system partition and an EFI enabled bootloader

One possible way to install Arch Linux:

```bash
# Inside archboot

# First partition disk
fdisk /dev/vda

# Create GPT table
fdisk> g

# Create boot partition
fdisk> n

Command (m for help): n
Partition number (1-128, default 1):
First sector (2048-4095966, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-4095966, default 4093951): +500M

Created a new partition 1 of type 'Linux filesystem' and of size 500 MiB.

# Change boot partition type to EFI system
fdisk> t

Command (m for help): t
Selected partition 1
Partition type or alias (type L to list all): 1
Changed type of partition 'Linux filesystem' to 'EFI System'.

# Create root partition
fdisk> n

Command (m for help): n
Partition number (2-128, default 2):
First sector (1026048-4095966, default 1026048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (1026048-4095966, default 4093951):

Created a new partition 2 of type 'Linux filesystem' and of size 1.5 GiB.

# Save changes
fdisk> w

# Partition table should look like:
[root@archboot /]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
zram0  251:0    0    4G  0 disk /
vda    253:0    0    2G  0 disk
|-vda1 253:1    0  500M  0 part
`-vda2 253:2    0  1.5G  0 part

# Format partitions
mkfs.fat -F 32 /dev/vda1
mkfs.ext4 /dev/vda2

# Mount partitions
mount /dev/vda2 /mnt
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot

# Install base packages
# Note: I'd usually go for systemd-boot but somehow Virtualization.framework doesn't boot with that. GRUB however, booted fine, so we'll go with that.
pacstrap -K /mnt base linux-aarch64 archlinuxarm-keyring grub vim

# Basic configuration
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt
echo "vm" > /etc/hostname
passwd

# Install GRUB bootloader
# Note: The --removable flag is important. That causes grub to put the booloader as `/boot/EFI/BOOT/BOOTAA64.EFI` which is kinda the default lookup place when the nvram doesn't have any bootloader entries.
grub-install --target=arm64-efi --efi-directory=/boot --bootloader-id=GRUB --removable

# Change `GRUB_CMDLINE_LINUX_DEFAULT` inside `/etc/default/grub`
vim /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="console=hvc0 irqaffinity=0 mitigations=off"
# Change timeouts because they are useless when running headless
GRUB_DEFAULT=0
GRUB_TIMEOUT=0

# Generate grub config
grub-mkconfig -o /boot/grub/grub.cfg

# Exit
exit

# Unmount
umount -R /mnt

# Shutdown
poweroff
```

The initial setup is done. Now you should be able to boot into the system with the EFI bootloader:

```bash
# PWD=./arch

# Note: Make use to use a fixed mac address for the network interface, so the dhcp service will try to always assign a stable ip address.
vmcli -b efi --efivars ./efivars -d ./disk.img -m 512 -n 74:a5:1a:d1:78:ed@nat
```

You should have a working Arch Linux. As mentioned above this is a very minimal installation. You probably need to setup things like networking and other stuff afterwards too.
