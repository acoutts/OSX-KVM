#!/bin/bash

# qemu-img create -f qcow2 mac_hdd_ng.img 128G
#
# echo 1 > /sys/module/kvm/parameters/ignore_msrs (this is required)

############################################################################
# NOTE: Tweak the "MY_OPTIONS" line in case you are having booting problems!
############################################################################

# This works for High Sierra as well as Mojave. Tested with macOS 10.13.6 and macOS 10.14.4.

# Rebind USB controller driver to vfio
# echo 0000:05:00.0 > /sys/bus/pci/devices/0000\:05\:00.0/driver/unbind
# echo 8086 3483 > /sys/bus/pci/drivers/vfio-pci/new_id
virsh nodedev-detach pci_0000_05_00_0 --driver vfio

#+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check
MY_OPTIONS=""
OVMF="./"

qemu-system-x86_64 -enable-kvm -m 8192 -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,$MY_OPTIONS \
  -machine pc-q35-2.9 \
  -smp 4,cores=2 \
  -device vfio-pci,host=01:00.0,bus=pcie.0,multifunction=on \
  -device vfio-pci,host=01:00.1,bus=pcie.0 \
  -device vfio-pci,host=05:00.0,bus=pcie.0 \
  -usb -device usb-kbd -device usb-tablet \
  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
  -drive if=pflash,format=raw,readonly,file=$OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$OVMF/OVMF_VARS-1024x768.fd \
  -smbios type=2 \
  -device ich9-intel-hda -device hda-duplex \
  -device ich9-ahci,id=sata \
  -drive id=Clover,if=none,snapshot=on,format=qcow2,file=./'Mojave/CloverNG.qcow2' \
  -device ide-hd,bus=sata.2,drive=Clover \
  -device ide-hd,bus=sata.3,drive=InstallMedia \
  -drive id=InstallMedia,if=none,file=BaseSystem.img,format=raw \
  -drive id=MacHDD,if=none,file=./mac_hdd_ng.img,format=qcow2 \
  -device ide-hd,bus=sata.4,drive=MacHDD \
  -device vmxnet3,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
  --netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -monitor stdio \
  -vga none
  
