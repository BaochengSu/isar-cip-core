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

inherit dpkg-raw

DESCRIPTION = "CIP Core image demo & test customizations"

SRC_URI = " \
    file://postinst \
    file://ethernet \
    file://99-silent-printk.conf \
    file://99-watchdog.conf"

DEPENDS += "sshd-regen-keys"

DEBIAN_DEPENDS = " \
    ifupdown, isc-dhcp-client, net-tools, iputils-ping, ssh, sshd-regen-keys, \
    rt-tests, stress-ng"

do_install() {
	install -v -d ${D}/etc/network/interfaces.d
	install -v -m 644 ${WORKDIR}/ethernet ${D}/etc/network/interfaces.d/

	install -v -d ${D}/etc/sysctl.d
	install -v -m 644 ${WORKDIR}/99-silent-printk.conf ${D}/etc/sysctl.d/

	install -v -d ${D}/usr/lib/systemd/system.conf.d
	install -v -m 0644 ${WORKDIR}/99-watchdog.conf ${D}/usr/lib/systemd/system.conf.d
}
