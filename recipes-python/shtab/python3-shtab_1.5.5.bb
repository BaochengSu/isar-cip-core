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
    https://github.com/iterative/shtab/archive/refs/tags/v1.5.5.tar.gz;downloadfilename=${PN}-${PV}.tar.gz \
    file://rules \
    "
# modify for debian buster build
SRC_URI_append_buster = " file://0001-Lower-requirements-on-setuptools.patch"

SRC_URI[sha256sum] = "b8183c7ee95f28d2f9e17bbe040d5e58070e272f8a0db2f8a601917da8cf8e26"

S = "${WORKDIR}/shtab-${PV}"

DEBIAN_BUILD_DEPENDS = " \
    dh-python, \
    libpython3-all-dev, \
    python3-all-dev:any, \
    python3-setuptools, \
    python3-setuptools-scm:native, \
    python3-wheel:native, \
    python3-toml:native, \
    "

DEB_BUILD_PROFILES = "nocheck"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
