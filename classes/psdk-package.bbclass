# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

SSTATETASKS += "do_generate_product_sdk "
SSTATE_OUT_DIR = "${DEPLOY_DIR}/artifacts/"
SSTATE_IN_DIR = "${QIRP_TOP_DIR}/${SDK_PN}"
TMP_SSTATE_IN_DIR = "${QIRP_TOP_DIR}/${SDK_PN}_tmp"
SAMPLES_PATH ?= "NULL"
TOOLCHAIN_PATH ?= "NULL"
TOOLS_PATH ?= "NULL"
README_PATH ?= "NULL"
SETUP_PATH ?= "NULL"

python __anonymous () {
    package_type = d.getVar("IMAGE_PKGTYPE", True)
    if package_type == "ipk":
        bb.build.addtask('do_package_write_ipk', 'do_populate_sysroot', 'do_packagedata', d)
        bb.build.addtask('do_generate_product_sdk', 'do_populate_sysroot', 'do_package_write_ipk', d)
        d.appendVarFlag('do_package_write_ipk', 'prefuncs', ' do_reorganize_pkg_dir')
    elif package_type == "deb":
        bb.build.addtask('do_package_write_deb', 'do_populate_sysroot', 'do_packagedata', d)
        bb.build.addtask('do_generate_product_sdk', 'do_populate_sysroot', 'do_package_write_deb', d)
        d.appendVarFlag('do_package_write_deb', 'prefuncs', ' do_reorganize_pkg_dir')
}

addtask do_generate_product_sdk_setscene
do_generate_product_sdk[postfuncs] += "organize_sdk_file"
do_generate_product_sdk[sstate-inputdirs] = "${SSTATE_IN_DIR}"
do_generate_product_sdk[sstate-outputdirs] = "${SSTATE_OUT_DIR}"
do_generate_product_sdk[dirs] = "${SSTATE_IN_DIR} ${SSTATE_OUT_DIR} ${TMP_SSTATE_IN_DIR}"
do_generate_product_sdk[cleandirs] = "${SSTATE_IN_DIR} ${SSTATE_OUT_DIR} ${TMP_SSTATE_IN_DIR}"
do_generate_product_sdk[stamp-extra-info] = "${MACHINE_ARCH}"

# Add a task to generate product sdk
do_generate_product_sdk () {
    # generate Product SDK package
    if [ ! -d ${TMP_SSTATE_IN_DIR}/${SDK_PN} ]; then
        mkdir -p ${TMP_SSTATE_IN_DIR}/${SDK_PN}/
    fi
    cp -r ${WORKDIR}/*install.sh ${TMP_SSTATE_IN_DIR}/${SDK_PN}/
    cp ${DEPLOY_DIR}/${IMAGE_PKGTYPE}/${PACKAGE_ARCH}/${PN}_*.${IMAGE_PKGTYPE} ${TMP_SSTATE_IN_DIR}/${SDK_PN}/
    cd ${TMP_SSTATE_IN_DIR}
    tar -zcf ${SSTATE_IN_DIR}/${SDK_PN}.tar.gz ./${SDK_PN}/*
}

# Add a task to copy sample code/toolchain/setup scripts,
# and orgnanize as finial sdk artifact
organize_sdk_file () {
    # orgnanize runtime packages
    if ls ${SSTATE_IN_DIR}/${SDK_PN}* >/dev/null 2>&1; then
        install -d ${SSTATE_IN_DIR}/${SDK_PN}/runtime
        mv ${SSTATE_IN_DIR}/${SDK_PN}*.tar.gz ${SSTATE_IN_DIR}/${SDK_PN}/runtime/
    else
        bbfatal "No ${SDK_PN} packages generated, Robotics SDK functions will be missed! Please check and retry!"
    fi

    # orgnanize QIRP sample codes
    if ls ${SAMPLES_PATH}/* >/dev/null 2>&1; then
        install -d ${SSTATE_IN_DIR}/${SDK_PN}/sample-code
        cp -r ${SAMPLES_PATH}/* ${SSTATE_IN_DIR}/${SDK_PN}/sample-code/
    else
        bbwarn "No Sample codes found in ${SAMPLES_PATH}, Please Note it!"
    fi

    # orgnanize robotics sample codes
    if ls ${RECIPE_SYSROOT}/robotics-sample/* >/dev/null 2>&1; then
       install -d ${SSTATE_IN_DIR}/${SDK_PN}/sample-code/Robotics-Modules
       cp -r ${RECIPE_SYSROOT}/robotics-sample/* ${SSTATE_IN_DIR}/${SDK_PN}/sample-code/Robotics-Modules
    fi

    # orgnanize toolchain
    if ls ${TOOLCHAIN_PATH}/* >/dev/null 2>&1; then
        install -d ${SSTATE_IN_DIR}/${SDK_PN}/toolchain
        cp -r ${TOOLCHAIN_PATH}/* ${SSTATE_IN_DIR}/${SDK_PN}/toolchain/
    else
        bbwarn "No SDK Toolchain found in ${TOOLCHAIN_PATH}, Please Note it!"
    fi

    # orgnanize tools
    if ls ${TOOLS_PATH}/* >/dev/null 2>&1; then
        install -d ${SSTATE_IN_DIR}/${SDK_PN}/tools
        cp -r ${TOOLS_PATH}/* ${SSTATE_IN_DIR}/${SDK_PN}/tools/
    else
        bbwarn "No Tools found in ${TOOLS_PATH}, Please Note it!"
    fi

    # orgnanize README docs
    if ls ${README_PATH} >/dev/null 2>&1; then
        cp -r ${README_PATH} ${SSTATE_IN_DIR}/${SDK_PN}/
    else
        bbwarn "No README docs found in ${README_PATH}, Please Note it!"
    fi

    # orgnanize setup.sh script
    if ls ${SETUP_PATH} >/dev/null 2>&1; then
        cp -r ${SETUP_PATH} ${SSTATE_IN_DIR}/${SDK_PN}/
    else
        bbwarn "No setup.sh script found in ${SETUP_PATH}, Please Note it!"
    fi

    # organize all files as finial sdk
    cd ${SSTATE_IN_DIR}
    tar -zcf ${SSTATE_IN_DIR}/${SDK_PN}_${PV}.tar.gz ./${SDK_PN}/*
    rm -r ${SSTATE_IN_DIR}/${SDK_PN}
}

python do_generate_product_sdk_setscene() {
    sstate_setscene(d)
}
