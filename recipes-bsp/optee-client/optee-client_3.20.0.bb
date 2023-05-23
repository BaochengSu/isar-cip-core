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

inherit dpkg

DESCRIPTION = "OPTee Client"

PROVIDES = "libteec1 optee-client-dev tee-supplicant"

SRC_URI += "https://github.com/OP-TEE/optee_client/archive/${PV}.tar.gz;downloadfilename=optee_client-${PV}.tar.gz \
    file://control.tmpl \
    file://rules.tmpl \
    file://tee-supplicant.service"
SRC_URI[sha256sum] = "69414c424b8dbed11ce1ae0d812817eda2ef4f42a1bef762e5ca3b6fed80764c"

S = "${WORKDIR}/optee_client-${PV}"

TEE_FS_PARENT_PATH ?= "/var/lib/optee-client/data/tee"
# To use the builtin RPMB emulation, empty this
RPMB_EMU_BUILD_OPT ?= "RPMB_EMU=0"

TEMPLATE_FILES = "rules.tmpl control.tmpl"
TEMPLATE_VARS += "TEE_FS_PARENT_PATH RPMB_EMU_BUILD_OPT"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize

    cp -f ${WORKDIR}/tee-supplicant.service \
        ${S}/debian/tee-supplicant.service
    echo "/usr/sbin/*" > ${S}/debian/tee-supplicant.install
    echo "lib/optee_armtz/" > ${S}/debian/tee-supplicant.dirs
    echo "usr/lib/tee-supplicant/plugins/" >> ${S}/debian/tee-supplicant.dirs

    echo "usr/lib/*/libteec*.so.*" > ${S}/debian/libteec1.install

    echo "usr/include/*" > ${S}/debian/optee-client-dev.install
    echo "usr/lib/*/lib*.so" >> ${S}/debian/optee-client-dev.install
}
