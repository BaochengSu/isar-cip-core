#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

SQUASHFS_EXCLUDE_DIRS += "home var"

inherit squashfs-img
inherit wic-img
inherit swupdate-img

IMAGE_INSTALL += "etc-overlay-fs"

INITRAMFS_RECIPE ?= "cip-core-initramfs"
INITRD_IMAGE = "${INITRAMFS_RECIPE}-${DISTRO}-${MACHINE}.initrd.img"

do_wic_image[depends] += "${INITRAMFS_RECIPE}:do_build"

IMAGE_INSTALL += "home-fs"
IMAGE_INSTALL += "tmp-fs"

image_configure_fstab() {
    sudo tee '${IMAGE_ROOTFS}/etc/fstab' << EOF
# Begin /etc/fstab
/dev/root	/		auto		defaults,ro			0	0
LABEL=var	/var		auto		defaults			0	0
proc		/proc		proc		nosuid,noexec,nodev		0	0
sysfs		/sys		sysfs		nosuid,noexec,nodev		0	0
devpts		/dev/pts	devpts		gid=5,mode=620			0	0
tmpfs		/run		tmpfs		nodev,nosuid,size=500M,mode=755	0	0
devtmpfs	/dev		devtmpfs	mode=0755,nosuid		0	0
# End /etc/fstab
EOF
}

addtask do_wic_image after do_squashfs_image

addtask do_swupdate_image after do_wic_image
