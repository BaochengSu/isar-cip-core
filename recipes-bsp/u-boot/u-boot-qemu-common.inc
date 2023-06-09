#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-bsp/u-boot/u-boot-common.inc

U_BOOT_BIN = "u-boot.bin"

DEPLOYDIR_U_BOOT = "${WORKDIR}/deploy-u-boot"
SSTATETASKS += "do_deploy"

do_deploy[cleandirs] += "${DEPLOYDIR_U_BOOT}"
do_deploy[sstate-inputdirs] = "${DEPLOYDIR_U_BOOT}"
do_deploy[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy() {
    dpkg --fsys-tarfile "${WORKDIR}/u-boot-${MACHINE}_${PV}_${DISTRO_ARCH}.deb" | \
        tar xOf - "./usr/lib/u-boot/${MACHINE}/${U_BOOT_BIN}" \
        > "${DEPLOYDIR_U_BOOT}/firmware.bin"
}

python do_deploy_setscene () {
    sstate_setscene(d)
}
addtask do_deploy_setscene

addtask deploy after do_dpkg_build before do_deploy_deb
