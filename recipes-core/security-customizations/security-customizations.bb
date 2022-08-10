#
# CIP Security, generic profile
#
# Copyright (c) Toshiba Corporation, 2020
#
# Authors:
#  Venkata Pyla <venkata.pyla@toshiba-tsip.com>#
#
# SPDX-License-Identifier: MIT
#

require recipes-core/customizations/common.inc

DESCRIPTION = "CIP Security image for IEC62443-4-2 evaluation"

SRC_URI += "file://postinst"

DEPENDS += "sshd-regen-keys"
DEBIAN_DEPENDS += ", sshd-regen-keys, libpam-google-authenticator"

