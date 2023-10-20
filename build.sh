#!/bin/bash

# Environment variables for the CentOS cloud image
ARCH_X86="x86_64"
ARCH_ARM="aarch64"
OS_MAJOR_VER="8"
OS_FULL_VER="8.8"
ROOTFS_VER="Base-8.8-20230518.0"

ROOTFS_FN_X86="Rocky-${OS_MAJOR_VER}-GenericCloud-${ROOTFS_VER}.${ARCH_X86}.qcow2"
ROOTFS_URL_X86="https://dl.rockylinux.org/pub/rocky/${OS_FULL_VER}/images/${ARCH_X86}/${ROOTFS_FN_X86}"

ROOTFS_FN_ARM="Rocky-${OS_MAJOR_VER}-GenericCloud-${ROOTFS_VER}.${ARCH_ARM}.qcow2"
ROOTFS_URL_ARM="https://dl.rockylinux.org/pub/rocky/${OS_FULL_VER}/images/${ARCH_ARM}/${ROOTFS_FN_ARM}"

# Environment variables for RockyLinux WSL Launcher
LNCR_BLD="Launcher"
LNCR_NAME="RockyLinux"
LNCR_FN_X86=${LNCR_NAME}.x64.exe
LNCR_FN_ARM=${LNCR_NAME}.arm64.exe
LNCR_ZIPFN=RockyLinux${OS_MAJOR_VER}.exe
LNCR_URL_X86="https://github.com/rctzxy/RockyLinux-WSL/releases/download/${LNCR_BLD}/${LNCR_FN_X86}"
LNCR_URL_ARM="https://github.com/rctzxy/RockyLinux-WSL/releases/download/${LNCR_BLD}/${LNCR_FN_ARM}"

# Waits until a file appears or disappears
# - $1   File path to wait for its existence
# - [$2] The string 'a' (default) to wait until the file appears, or 'd' to wait until the file disappears
# - [$3] Timeout in seconds
waitFile() {
  local START
  START=$(cut -d '.' -f 1 /proc/uptime)
  local MODE=${2:-"a"}
  until [[ "${MODE}" = "a" && -e "$1" ]] || [[ "${MODE}" = "d" && ( ! -e "$1" ) ]]; do
    sleep 1s
    if [ -n "$3" ]; then
      local NOW
      NOW=$(cut -d '.' -f 1 /proc/uptime)
      local ELAPSED=$(( NOW - START ))
      if [ $ELAPSED -ge "$3" ]; then break; fi
    fi
  done
  sleep 2s
}

# Create a work dir
mkdir wsl
cd wsl

mkdir dist
# X86 Generate

# Download the CentOS cloud image and RockyLinux WSL Launcher
wget --no-verbose ${ROOTFS_URL_X86} -O ${ROOTFS_FN_X86}
wget --no-verbose ${LNCR_URL_X86} -O ${LNCR_FN_X86}

# Mount the qcow2 image
sudo mkdir mntfs
sudo modprobe nbd
sudo qemu-nbd -c /dev/nbd0 --read-only ./${ROOTFS_FN_X86}
waitFile /dev/nbd0p5 "a" 30
sudo mount -o ro /dev/nbd0p5 mntfs

# Clone the qcow2 image contents to a writable directory
sudo cp -a mntfs install

# Unmount the qcow2 image
sudo umount mntfs
sudo qemu-nbd -d /dev/nbd0
waitFile /dev/nbd0p5 "d" 30
sudo rmmod nbd
sudo rmdir mntfs

# Clean up
rm ${ROOTFS_FN_X86}

# Create a tar.gz of the rootfs
sudo chmod 666 ./install/etc/fstab
> ./install/etc/fstab
sudo chmod 644 ./install/etc/fstab
sudo tar -zcpf install.tar.gz -C ./install .
sudo chown "$(id -un)" install.tar.gz

# Clean up
sudo rm -rf install

# Create the distribution zip of WSL RockyLinux
mkdir out

mv -f ${LNCR_FN_X86} ./out/${LNCR_ZIPFN}
mv -f install.tar.gz ./out/
pushd out
zip ../dist/RockyLinux${OS_MAJOR_VER}.x64.zip ./*
popd

# Clean up
rm -rf out

# ARM Generate

# Download the CentOS cloud image and RockyLinux WSL Launcher
wget --no-verbose ${ROOTFS_URL_ARM} -O ${ROOTFS_FN_ARM}
wget --no-verbose ${LNCR_URL_ARM} -O ${LNCR_FN_ARM}

# Mount the qcow2 image
sudo mkdir mntfs
sudo modprobe nbd
sudo qemu-nbd -c /dev/nbd0 --read-only ./${ROOTFS_FN_ARM}
waitFile /dev/nbd0p5 "a" 30
sudo mount -o ro /dev/nbd0p5 mntfs

# Clone the qcow2 image contents to a writable directory
sudo cp -a mntfs install

# Unmount the qcow2 image
sudo umount mntfs
sudo qemu-nbd -d /dev/nbd0
waitFile /dev/nbd0p5 "d" 30
sudo rmmod nbd
sudo rmdir mntfs

# Clean up
rm ${ROOTFS_FN_ARM}

# Create a tar.gz of the rootfs
sudo chmod 666 ./install/etc/fstab
> ./install/etc/fstab
sudo chmod 644 ./install/etc/fstab
sudo tar -zcpf install.tar.gz -C ./install .
sudo chown "$(id -un)" install.tar.gz

# Clean up
sudo rm -rf install

# Create the distribution zip of WSL RockyLinux
mkdir out
mv -f ${LNCR_FN_ARM} ./out/${LNCR_ZIPFN}
mv -f install.tar.gz ./out/
pushd out
zip ../dist/RockyLinux${OS_MAJOR_VER}.arm64.zip ./*
popd

# Clean up
rm -rf out
