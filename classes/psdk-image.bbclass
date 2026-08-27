# Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear
TOOLCHAIN_PATH = "${DEPLOY_DIR}/sdk"

SDK_VERSION = "2.6.2"

do_generate_qirp_sdk(){
    # orgnanize toolchain
    if ls ${TOOLCHAIN_PATH}/* | xargs -n1 basename | grep ${TOOLCHAIN_OUTPUTNAME} >/dev/null 2>&1; then
        bbnote "Standard SDK Toolchain found in ${TOOLCHAIN_PATH}, copy to {QIRP_SSTATE_IN_DIR}/${SDK_PN}/toolchain/"
        install -d ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/toolchain
        find ${TOOLCHAIN_PATH} -type f -name "${TOOLCHAIN_OUTPUTNAME}*" -exec cp {} ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/toolchain/ \;
    else
        bbwarn "No Standard SDK Toolchain found in ${TOOLCHAIN_PATH}, Please Note it!"
    fi
    cd ${QIRP_SSTATE_IN_DIR}
    tar -zcf ${QIRP_SSTATE_IN_DIR}/${SDK_PN}_${SDK_VERSION}.tar.gz ./${SDK_PN}/*
    rm -rf ${QIRP_SSTATE_IN_DIR}/${SDK_PN}
}
addtask do_generate_qirp_sdk after do_populate_sdk

SDK_PN = "qirp-sdk"
SSTATETASKS += "do_generate_qirp_sdk "
QIRP_SSTATE_OUT_DIR = "${DEPLOY_DIR}/qirpsdk_artifacts/${MACHINE}/"
QIRP_SSTATE_IN_DIR = "${QIRP_OUTPUT}"

do_generate_qirp_sdk[sstate-inputdirs] = "${QIRP_SSTATE_IN_DIR}"
do_generate_qirp_sdk[sstate-outputdirs] = "${QIRP_SSTATE_OUT_DIR}"
do_generate_qirp_sdk[dirs] = "${QIRP_SSTATE_IN_DIR} ${QIRP_SSTATE_OUT_DIR}"
do_generate_qirp_sdk[cleandirs] = "${QIRP_SSTATE_OUT_DIR}"
do_generate_qirp_sdk[stamp-extra-info] = "${MACHINE_ARCH}"
addtask do_generate_qirp_sdk_setscene

python __anonymous () {
    d.appendVarFlag("do_generate_qirp_sdk", 'depends', 'qirp-sdk:do_generate_product_sdk')
}
