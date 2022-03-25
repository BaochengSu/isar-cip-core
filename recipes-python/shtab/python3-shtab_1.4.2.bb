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

inherit dpkg

SRC_URI = " \
    https://github.com/iterative/shtab/archive/refs/tags/v1.4.2.tar.gz;downloadfilename=${PN}-${PV}.tar.gz \
    file://0001-Lower-requirements-on-setuptools.patch \
    file://rules \
    "
SRC_URI[sha256sum] = "5e6ef745c223ef1a01a2db491a8ec5c02c8291067328b17695c9a44f5b7d6fe6"

S = "${WORKDIR}/shtab-${PV}"

DEBIAN_BUILD_DEPENDS = " \
    dh-python, \
    python3-all, \
    python3-setuptools, \
    python3-setuptools-scm:native, \
    "

export DEB_BUILD_PROFILES = "nocheck"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
