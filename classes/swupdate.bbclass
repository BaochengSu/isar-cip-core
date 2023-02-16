#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Christian Storm <christian.storm@siemens.com>
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
ROOTFS_PARTITION_NAME ?= "${IMAGE_FULLNAME}.wic.p4.gz"

SWU_IMAGE_FILE ?= "${DEPLOY_DIR_IMAGE}/${PN}-${DISTRO}-${MACHINE}.swu"
SWU_DESCRIPTION_FILE ?= "sw-description"
SWU_ADDITIONAL_FILES ?= "linux.efi ${ROOTFS_PARTITION_NAME}"
SWU_SIGNED ?= ""
SWU_SIGNATURE_EXT ?= "sig"
SWU_SIGNATURE_TYPE ?= "rsa"

BUILDCHROOT_IMAGE_FILE ?= "${PP_DEPLOY}/${@os.path.basename(d.getVar('SWU_IMAGE_FILE'))}"

IMAGE_TYPEDEP:wic += "squashfs"
IMAGE_TYPEDEP:swu = "wic"
IMAGER_INSTALL:swu += "cpio ${@'openssl' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"

IMAGE_SRC_URI:swu = "file://${SWU_DESCRIPTION_FILE}.tmpl"
IMAGE_TEMPLATE_FILES:swu = "${SWU_DESCRIPTION_FILE}.tmpl"
IMAGE_TEMPLATE_VARS:swu = "ROOTFS_PARTITION_NAME TARGET_IMAGE_UUID ABROOTFS_PART_UUID_A ABROOTFS_PART_UUID_B"

# This imagetype is neither machine nor distro specific. Hence, we cannot
# use paths in FILESOVERRIDES. Manual modifications of this variable are
# discouradged and hard to implement. Instead, we register this path explicitly.
# We append to the path, so locally provided config files are preferred
FILESEXTRAPATHS:append = ":${LAYERDIR_cip-core}/recipes-core/images/swu"

do_image_swu[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_image_swu[cleandirs] += "${WORKDIR}/swu"
IMAGE_CMD:swu() {
    rm -f '${SWU_IMAGE_FILE}'
    cp '${WORKDIR}/${SWU_DESCRIPTION_FILE}' '${WORKDIR}/swu/${SWU_DESCRIPTION_FILE}'

    # Compress files if requested
    for file in ${SWU_ADDITIONAL_FILES}; do
        basefile=$(basename "$file" .gz)
        if [ "$basefile" = "$file" ]; then
            continue
        fi
        for uncompressed in "${WORKDIR}/$basefile" "${DEPLOY_DIR_IMAGE}/$basefile"; do
            if [ -e "$uncompressed" ]; then
                rm  -f "$uncompressed.gz"
                if [ -x "$(command -v pigz)" ]; then
                    pigz "$uncompressed"
                else
                    gzip "$uncompressed"
                fi
                break
            fi
        done
    done

    # Create symlinks for files used in the update image
    for file in ${SWU_ADDITIONAL_FILES}; do
        if [ -e "${WORKDIR}/$file" ]; then
            ln -s "${PP_WORK}/$file" "${WORKDIR}/swu/$file"
        else
            ln -s "${PP_DEPLOY}/$file" "${WORKDIR}/swu/$file"
        fi
    done

    image_do_mounts

    # Prepare for signing
    export sign='${@'x' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}'
    if [ -n "$sign" ]; then
        cp -f '${SIGN_KEY}' '${WORKDIR}/dev.key'
        test -e '${SIGN_CRT}' && cp -f '${SIGN_CRT}' '${WORKDIR}/dev.crt'
    fi

    sudo -E chroot ${BUILDCHROOT_DIR} sh -c ' \
        # Fill in file check sums
        for file in ${SWU_ADDITIONAL_FILES}; do
            sed -i "s:$file-sha256:$(sha256sum "${PP_WORK}/swu/"$file | cut -f 1 -d " "):g" \
                "${PP_WORK}/swu/${SWU_DESCRIPTION_FILE}"
        done
        cd "${PP_WORK}/swu"
        for file in "${SWU_DESCRIPTION_FILE}" ${SWU_ADDITIONAL_FILES}; do
            echo "$file"
            if [ -n "$sign" -a "${SWU_DESCRIPTION_FILE}" = "$file" ]; then
                if [ "${SWU_SIGNATURE_TYPE}" = "rsa" ]; then
                    openssl dgst \
                        -sha256 -sign "${PP_WORK}/dev.key" "$file" \
                        > "$file.${SWU_SIGNATURE_EXT}"
                elif [ "${SWU_SIGNATURE_TYPE}" = "cms" ]; then
                    openssl cms \
                        -sign -in "$file" \
                        -out "$file"."${SWU_SIGNATURE_EXT}" \
                        -signer "${PP_WORK}/dev.crt" \
                        -inkey "${PP_WORK}/dev.key" \
                        -outform DER -nosmimecap -binary
                fi
                echo "$file.${SWU_SIGNATURE_EXT}"
           fi
        done | cpio -ovL -H crc > "${BUILDCHROOT_IMAGE_FILE}"'
}
