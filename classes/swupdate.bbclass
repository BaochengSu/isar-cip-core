#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Christian Storm <christian.storm@siemens.com>
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#  Felix Moessbauer <felix.moessbauer@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit template

SWU_ROOTFS_TYPE ?= "squashfs"
SWU_ROOTFS_NAME ?= "${IMAGE_FULLNAME}"
# compression type as defined by swupdate (zlib or zstd). Set to empty string to disable compression
SWU_COMPRESSION_TYPE ?= "zlib"
SWU_ROOTFS_PARTITION_NAME ?= "${SWU_ROOTFS_NAME}.${SWU_ROOTFS_TYPE}${@get_swu_compression_type(d)}"
SWU_VERSION ?= "0.2"
SWU_NAME ?= "cip software update"
# space separated list of supported hw. Leave empty to leave out
SWU_HW_COMPAT ?= ""

SWU_IMAGE_FILE ?= "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.swu"
SWU_DESCRIPTION_FILE ?= "sw-description"
SWU_ADDITIONAL_FILES ?= "linux.efi ${SWU_ROOTFS_PARTITION_NAME}"
SWU_SIGNED ?= ""
SWU_SIGNATURE_EXT ?= "sig"
SWU_SIGNATURE_TYPE ?= "rsa"

SWU_BUILDCHROOT_IMAGE_FILE ?= "${PP_DEPLOY}/${@os.path.basename(d.getVar('SWU_IMAGE_FILE'))}"

IMAGE_TYPEDEP:swu = "wic ${SWU_ROOTFS_TYPE}${@get_swu_compression_type(d)}"
IMAGER_INSTALL:swu += "cpio ${@'openssl' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"

IMAGE_SRC_URI:swu = "file://${SWU_DESCRIPTION_FILE}.tmpl"
IMAGE_TEMPLATE_FILES:swu = "${SWU_DESCRIPTION_FILE}.tmpl"
IMAGE_TEMPLATE_VARS:swu = " \
    SWU_ROOTFS_PARTITION_NAME \
    TARGET_IMAGE_UUID \
    ABROOTFS_PART_UUID_A \
    ABROOTFS_PART_UUID_B \
    SWU_HW_COMPAT_NODE \
    SWU_COMPRESSION_NODE \
    SWU_VERSION \
    SWU_NAME"

python(){
    # create SWU_HW_COMPAT_NODE based on list of supported hw
    hw_compat = d.getVar('SWU_HW_COMPAT')
    if hw_compat:
        hw_entries = ', '. join(['"' + h + '"' for h in hw_compat.split()])
        d.setVar('SWU_HW_COMPAT_NODE',
            'hardware-compatibility: [ ' + hw_entries +' ];')
    else:
        d.setVar('SWU_HW_COMPAT_NODE', '')

    # create SWU_COMPRESSION_NODE node if compression is enabled
    calgo = d.getVar('SWU_COMPRESSION_TYPE')
    if calgo:
        d.setVar('SWU_COMPRESSION_NODE', 'compressed = "' + calgo + '";')
    else:
        d.setVar('SWU_COMPRESSION_NODE', '')
}


# convert between swupdate compressor name and imagetype extension
def get_swu_compression_type(d):
    swu_ct = d.getVar('SWU_COMPRESSION_TYPE', True)
    if not swu_ct:
        return ''
    swu_to_image = {'zlib': '.gz', 'zstd': '.zst'}
    if swu_ct not in swu_to_image:
        bb.fatal('requested SWU_COMPRESSION_TYPE is not supported by swupdate')
    return swu_to_image[swu_ct]

# This imagetype is neither machine nor distro specific. Hence, we cannot
# use paths in FILESOVERRIDES. Manual modifications of this variable are
# discouradged and hard to implement. Instead, we register this path explicitly.
# We append to the path, so locally provided config files are preferred
FILESEXTRAPATHS:append = ":${LAYERDIR_cip-core}/recipes-core/images/swu"

do_image_swu[depends] += "${PN}:do_transform_template"
do_image_swu[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_image_swu[cleandirs] += "${WORKDIR}/swu"
IMAGE_CMD:swu() {
    rm -f '${SWU_IMAGE_FILE}'
    cp '${WORKDIR}/${SWU_DESCRIPTION_FILE}' '${WORKDIR}/swu/${SWU_DESCRIPTION_FILE}'

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
        done | cpio -ovL -H crc > "${SWU_BUILDCHROOT_IMAGE_FILE}"'
}

python do_check_swu_partition_uuids() {
    for u in ['A', 'B']:
        if not d.getVar('ABROOTFS_PART_UUID_' + u):
            bb.fatal('ABROOTFS_PART_UUID_' + u + ' not set')
}

addtask check_swu_partition_uuids before do_image_swu
