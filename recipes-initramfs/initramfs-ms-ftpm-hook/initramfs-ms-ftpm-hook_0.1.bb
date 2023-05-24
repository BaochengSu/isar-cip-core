#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

SRC_URI += " \
    file://ms-ftpm.hook \
    file://ms-ftpm.script \
    "

DEBIAN_DEPENDS = "initramfs-tools, tee-supplicant"

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/initramfs-tools/scripts/local-bottom"

do_install() {
    install -m 0755 "${WORKDIR}/ms-ftpm.hook" \
        "${D}/usr/share/initramfs-tools/hooks/ms-ftpm"
    install -m 0755 "${WORKDIR}/ms-ftpm.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-bottom/ms-ftpm"
}
