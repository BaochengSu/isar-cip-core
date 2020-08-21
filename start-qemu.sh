#!/bin/sh
#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

usage()
{
	echo "Usage: $0 ARCHITECTURE [QEMU_OPTIONS]"
	echo -e "\nSet QEMU_PATH environment variable to use a locally " \
		"built QEMU version"
	echo -e "\nSet SECURE_BOOT environment variable to boot a secure boot environment " \
		"This environment also needs the variables OVMF_VARS and OVMF_CODE set"
	exit 1
}

if [ -n "${QEMU_PATH}" ]; then
	QEMU_PATH="${QEMU_PATH}/"
fi

if [ -z "${DISTRO_RELEASE}" ]; then
  DISTRO_RELEASE="buster"
fi
if [ -z "${TARGET_IMAGE}" ];then
	TARGET_IMAGE="cip-core-image"
fi

case "$1" in
	x86|x86_64|amd64)
		DISTRO_ARCH=amd64
		QEMU=qemu-system-x86_64
		QEMU_EXTRA_ARGS=" \
			-cpu qemu64 \
			-smp 4 \
			-machine q35,accel=kvm:tcg \
			-device ide-hd,drive=disk \
			-device virtio-net-pci,netdev=net"
		KERNEL_CMDLINE=" \
			root=/dev/sda"
		;;
	arm64|aarch64)
		DISTRO_ARCH=arm64
		QEMU=qemu-system-aarch64
		QEMU_EXTRA_ARGS=" \
			-cpu cortex-a57 \
			-smp 4 \
			-machine virt \
			-device virtio-serial-device \
			-device virtconsole,chardev=con -chardev vc,id=con \
			-device virtio-blk-device,drive=disk \
			-device virtio-net-device,netdev=net"
		KERNEL_CMDLINE=" \
			root=/dev/vda"
		;;
	arm|armhf)
		DISTRO_ARCH=armhf
		QEMU=qemu-system-arm
		QEMU_EXTRA_ARGS=" \
			-cpu cortex-a15 \
			-smp 4 \
			-machine virt \
			-device virtio-serial-device \
			-device virtconsole,chardev=con -chardev vc,id=con \
			-device virtio-blk-device,drive=disk \
			-device virtio-net-device,netdev=net"
		KERNEL_CMDLINE=" \
			root=/dev/vda"
		;;
	""|--help)
		usage
		;;
	*)
		echo "Unsupported architecture: $1"
		exit 1
		;;
esac

IMAGE_PREFIX="$(dirname $0)/build/tmp/deploy/images/qemu-${DISTRO_ARCH}/${TARGET_IMAGE}-cip-core-${DISTRO_RELEASE}-qemu-${DISTRO_ARCH}"

if [ -z "${DISPLAY}" ]; then
	QEMU_EXTRA_ARGS="${QEMU_EXTRA_ARGS} -nographic"
	case "$1" in
		x86|x86_64|amd64)
			KERNEL_CMDLINE="${KERNEL_CMDLINE} console=ttyS0"
	esac
fi

shift 1

if [ -n "${SECURE_BOOT}" ]; then
		ovmf_code=${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE.secboot.fd}
		ovmf_vars=${OVMF_VARS:-./OVMF_VARS.fd}
		QEMU_EXTRA_ARGS=" ${QEMU_EXTRA_ARGS} \
			-global ICH9-LPC.disable_s3=1 \
			-global isa-fdc.driveA= "

		BOOT_FILES="-drive if=pflash,format=raw,unit=0,readonly=on,file=${ovmf_code} \
			-drive if=pflash,format=raw,file=${ovmf_vars} \
			-drive file=${IMAGE_PREFIX}.wic.img,discard=unmap,if=none,id=disk,format=raw"
		${QEMU_PATH}${QEMU} \
			-m 1G -serial mon:stdio -netdev user,id=net \
			${BOOT_FILES} ${QEMU_EXTRA_ARGS} "$@"
else
		IMAGE_FILE=$(ls ${IMAGE_PREFIX}.ext4.img)

		KERNEL_FILE=$(ls ${IMAGE_PREFIX}-vmlinuz* | tail -1)
		INITRD_FILE=$(ls ${IMAGE_PREFIX}-initrd.img* | tail -1)

		${QEMU_PATH}${QEMU} \
			-m 1G -serial mon:stdio -netdev user,id=net \
			-drive file=${IMAGE_FILE},discard=unmap,if=none,id=disk,format=raw \
			-kernel ${KERNEL_FILE} -append "${KERNEL_CMDLINE}" \
			-initrd ${INITRD_FILE} ${QEMU_EXTRA_ARGS} "$@"
fi
