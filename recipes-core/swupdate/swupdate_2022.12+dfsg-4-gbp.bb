#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-gbp

require swupdate.inc

DEPENDS += "libebgenv-dev"

DEB_BUILD_PROFILES += "nodoc"
DEB_BUILD_OPTIONS += "nodoc"

SRC_URI = "git://salsa.debian.org/debian/swupdate.git;protocol=https;branch=debian/master"
SRCREV ="aa9edf070567fa5b3e942c270633a8feef49dad8"
SRC_URI += "file://0001-d-rules-Add-option-for-suricatta_lua.patch"

# deactivate signing and hardware compability for simple a/b rootfs update
DEB_BUILD_PROFILES:append:no-signed-swu = "pkg.swupdate.nosigning"
DEB_BUILD_PROFILES += "pkg.swupdate.nohwcompat"
DEB_BUILD_PROFILES:append:suricatta-lua = "pkg.swupdate.suricattalua"

# add cross build and deactivate testing for arm based builds
DEB_BUILD_PROFILES += "cross nocheck"
DEB_BUILD_PROFILES:append:bullseye = " pkg.swupdate.bpo"

