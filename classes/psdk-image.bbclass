# Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# psdk-image.bbclass
# Purpose:
#   Provides the QIRP SDK packaging flow for robotics images.
#   After the image SDK is generated, this class collects the toolchain,
#   setup scripts, sample content, runtime scripts, and runtime packages,
#   then assembles them into a distributable SDK archive.
#
# Main responsibilities:
#   1. Collect the standard SDK toolchain from the deploy directory.
#   2. Copy setup and runtime helper scripts into the SDK layout.
#   3. Import sample projects and scripts from local sources or git repositories.
#   4. Collect runtime packages based on packagegroup dependency lists.
#   5. Produce the final SDK tarball through an sstate-enabled task.
#
# Typical usage:
#   Used by robotics image recipes such as qcom-robotics-image to create a releasable QIRP SDK bundle.
#
TOOLCHAIN_PATH = "${DEPLOY_DIR}/sdk"
SDK_PN = "qirp-sdk"
SDK_VERSION = "2.7.0"

# Collect the standard SDK toolchain and copy it into the SDK's toolchain/
# directory. If no matching toolchain is found, the task only emits a warning.
# Function: process_toolchain
process_toolchain() {
    bbnote "Processing toolchain..."
    if find "${TOOLCHAIN_PATH}" -maxdepth 1 -name "${TOOLCHAIN_OUTPUTNAME}*" | grep -q .; then
        bbnote "Standard SDK Toolchain found in ${TOOLCHAIN_PATH}, copy to ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/toolchain/"
        install -d ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/toolchain
        find ${TOOLCHAIN_PATH} -type f -name "${TOOLCHAIN_OUTPUTNAME}*" -exec cp {} ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/toolchain/ \;
    else
        bbwarn "No Standard SDK Toolchain found in ${TOOLCHAIN_PATH}, Please Note it!"
    fi
}

# Function: process_setup_sh
# Copy setup.sh into the SDK root so the extracted SDK can be initialized
# conveniently by end users.
process_setup_sh() {
    bbnote "Processing setup.sh..."
    SETUP_SH_PATH="${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/setup.sh"
    if [ -f "${SETUP_SH_PATH}" ]; then
        bbnote "setup.sh found in ${SETUP_SH_PATH}, copy to ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/"
        install -d ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/
        cp ${SETUP_SH_PATH} ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/
    else
        bbwarn "No setup.sh found in ${SETUP_SH_PATH}, Please Note it!"
    fi
}

# Function: process_qir_samples
# Collect sample projects and helper scripts defined in the configuration files.
# Supported sources include remote git repositories and local directories.
# This function also filters content by channel and supports both monorepo-style
# samples and individually cloned projects.
process_qir_samples() {
    bbnote "Processing QIR samples..."
    
    # Process the files in the content_config.json
    CONFIG_FILE="${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/content_config.json"
    if [ ! -f "${CONFIG_FILE}" ]; then
        bbwarn "Config file ${CONFIG_FILE} not found, skipping samples processing"
        return
    fi
    
    jq -c '.samples[]' $CONFIG_FILE | while read line; do
        name=$(echo $line | jq -r '.name')
        ros_pkg_name=$(echo $line | jq -r '.name' | tr '-' '_')
        to_dir="${QIRP_SSTATE_IN_DIR}/${SDK_PN}/$(echo $line | jq -r '.to')"

        bbnote "  Processing sample: $name"
        bbnote "  Target directory: $to_dir"
        
        install -d "${to_dir}"
        
        # Copy ${source_dir} to ${to_dir}
        source_dir="${DEPLOY_DIR}/sample_source_code/${name}"
        if [ -d "${source_dir}" ]; then
            bbnote "  Copying entire directory ${source_dir} to ${to_dir}/${ros_pkg_name}"
            cp -rf "${source_dir}" "${to_dir}/${ros_pkg_name}" 2>/dev/null || bbwarn "Failed to copy ${name}"
        else
            bbwarn "  Source directory ${source_dir} does not exist, skipping sample: $name"
        fi

    done

    # Process scripts from config file
    jq -c '.scripts[]' $CONFIG_FILE | while read line; do
        from_local="${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/$(echo $line | jq -r '.from_local')"
        to="${QIRP_SSTATE_IN_DIR}/${SDK_PN}/$(echo $line | jq -r '.to')"

        if [ -d "$from_local" ]; then
            # Ensure target directory exists
            install -d $(dirname "$to")
            cp -r "$from_local" "$to"
            bbnote "Copy sample source from $from_local to $to"
        else
            bbwarn "Source directory $from_local does not exist, skipping"
        fi
    done

    # Process sample.json
    SAMPLE_JSON="${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/samples.json"
    if [ -f "$SAMPLE_JSON" ]; then
        # Ensure target directory exists
        install -d ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/qirp-samples/
        cp "$SAMPLE_JSON" ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/qirp-samples/
        bbnote "Copied samples.json to ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/qirp-samples/"
    fi
}

# Function: process_runtime
# Collect runtime delivery content, including installation scripts and binary
# packages resolved from packagegroup dependency lists, then package them as a
# runtime tarball for target-side installation.
process_runtime() {
    bbnote "Processing runtime packages for ${PN}..."
    
    INSTALL_SCRIPT_PATH="${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/install.sh"
    UNINSTALL_SCRIPT_PATH="${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/uninstall.sh"
    QIRP_UPGRADE_PATH="${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/qirp-upgrade.sh"

    # Create runtime directories under SDK_PN
    bbnote "Creating runtime package directory"
    install -d ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/packages
    install -d ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/scripts

    # Copy script files if they exist
    for script_file in "${INSTALL_SCRIPT_PATH}" "${UNINSTALL_SCRIPT_PATH}" "${QIRP_UPGRADE_PATH}"; do
        if [ -f "${script_file}" ]; then
            bbnote "Copying ${script_file} to ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/scripts/"
            cp "${script_file}" ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/scripts/
        else
            bbwarn "Script file ${script_file} not found, skipping"
        fi
    done

    if echo "${PN}" | grep -q proprietary; then
        # Proprietary image: three packagegroups
        LIST_FILES=" \
            ${ROBOTICS_PACKAGEGROUP_LIST_DIR}/packagegroup-robotics-opensource.list \
            ${ROBOTICS_PACKAGEGROUP_LIST_DIR}/packagegroup-oss-with-prop-deps.list \
            ${ROBOTICS_PACKAGEGROUP_LIST_DIR}/packagegroup-robotics-proprietary.list \
        "
        bbnote "Processing proprietary image with 3 packagegroup lists"
    else
        # Open-source image: one packagegroup
        LIST_FILES="${ROBOTICS_PACKAGEGROUP_LIST_DIR}/packagegroup-robotics-opensource.list"
        bbnote "Processing open-source image with 1 packagegroup list"
    fi
    
    # Check if list files exist - exit with error if any are missing
    missing_files=""
    for list_file in ${LIST_FILES}; do
        if [ ! -f "${list_file}" ]; then
            missing_files="${missing_files} $(basename ${list_file})"
        fi
    done
    
    if [ -n "${missing_files}" ]; then
        bbfatal "Missing packagegroup list files:${missing_files}. Make sure packagegroups have been built with do_collect_rdepends task before generating SDK."
    fi
    
    # Read package list from files and copy packages
    PACKAGE_SRC_DIR="${DEPLOY_DIR}/${IMAGE_PKGTYPE}/${PACKAGE_ARCH}/"
    
    if [ ! -d "${PACKAGE_SRC_DIR}" ]; then
        bbfatal "Package source directory ${PACKAGE_SRC_DIR} does not exist. Make sure packages have been built."
    fi
    
    # Collect all package names (deduplicate)
    ALL_PACKAGES=""
    for list_file in ${LIST_FILES}; do
        if [ -f "${list_file}" ]; then
            bbnote "Reading package list from: ${list_file}"
            while read pkg; do
                pkg=$(echo $pkg | xargs)  # Remove whitespace
                # Skip empty lines and comments - use grep instead of [[ ]]
                if [ -n "${pkg}" ] && ! echo "${pkg}" | grep -q '^#'; then
                    ALL_PACKAGES="${ALL_PACKAGES} ${pkg}"
                fi
            done < "${list_file}"
        fi
    done
    
    # Deduplicate
    UNIQUE_PACKAGES=$(echo "${ALL_PACKAGES}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    package_count=$(echo "${UNIQUE_PACKAGES}" | wc -w)
    bbnote "Found ${package_count} unique packages to copy"
    
    # Copy package files
    copied_count=0
    for pkg in ${UNIQUE_PACKAGES}; do
        # Recursively search for package files in ${DEPLOY_DIR}/${IMAGE_PKGTYPE}/ directory tree
        bbnote "Searching for package: ${pkg}*.${IMAGE_PKGTYPE}"
        found_files=$(find ${DEPLOY_DIR}/${IMAGE_PKGTYPE}/ -name "${pkg}*.${IMAGE_PKGTYPE}" -type f 2>/dev/null | grep -v -E "(src|dev|dbg)-" || true)
        
        if [ -n "${found_files}" ]; then
            bbnote "Found package files for ${pkg}:"
            for file in ${found_files}; do
                bbnote "  - ${file}"
            done
            
            bbnote "Copying ${pkg} packages"
            # Use cp -f to force overwrite if duplicate files exist
            cp -f ${found_files} ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/packages/
            # Count the number of copied files
            file_count=$(echo "${found_files}" | wc -w)
            copied_count=$(expr $copied_count + $file_count)
        else
            bbwarn "Package ${pkg} not found in ${DEPLOY_DIR}/${IMAGE_PKGTYPE}/ directory tree"
        fi
    done
    
    bbnote "Successfully copied ${copied_count} packages"

    tar -zcf ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/${SDK_PN}.tar.gz -C ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime packages scripts

    rm -rf ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/packages
    rm -rf ${QIRP_SSTATE_IN_DIR}/${SDK_PN}/runtime/scripts

}

# Main function: do_generate_qirp_sdk
# Execute the complete QIRP SDK generation flow and create the final
# ${SDK_PN}_${SDK_VERSION}.tar.gz archive.
do_generate_qirp_sdk(){
    bbnote "Starting QIRP SDK generation..."
    
    # Create base SDK directory structure
    bbnote "Creating base SDK directory: ${QIRP_SSTATE_IN_DIR}/${SDK_PN}"
    install -d ${QIRP_SSTATE_IN_DIR}/${SDK_PN}
    
    # 1. Process toolchain
    process_toolchain
    
    # 2. Process setup.sh
    process_setup_sh
    
    # 3. Process QIRP samples
    process_qir_samples
    
    # 4. Process runtime packages
    process_runtime

    # Create final SDK package
    cd ${QIRP_SSTATE_IN_DIR}
    tar -zcf ${QIRP_SSTATE_IN_DIR}/${SDK_PN}_${SDK_VERSION}.tar.gz ./${SDK_PN}/*
    
    # Clean up temporary directories
    rm -rf ${QIRP_SSTATE_IN_DIR}/${SDK_PN}
    
    bbnote "QIRP SDK generation completed: ${QIRP_SSTATE_IN_DIR}/${SDK_PN}_${SDK_VERSION}.tar.gz"
}

do_generate_qirp_sdk[file-checksums] = " \
    ${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/install.sh:True \
    ${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/uninstall.sh:True \
    ${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/qirp-upgrade.sh:True \
    ${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/setup.sh:True \
    ${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/content_config.json:True \
    ${ROBIOTICS_LAYER_DIR}/recipes-sdk/files/samples.json:True \
"

# Add task dependencies so the packagegroup dependency lists are generated
# before runtime package collection starts.
# Add dependency on packagegroup RDEPENDS collection tasks
python () {
    pn = d.getVar("PN")
    
    # Check if this is a robotics image
    if pn in ["qcom-robotics-image", "qcom-robotics-proprietary-image"]:
        # Determine which packagegroups to depend on
        if "proprietary" in pn:
            pkg_groups = [
                "packagegroup-robotics-opensource",
                "packagegroup-oss-with-prop-deps",
                "packagegroup-robotics-proprietary"
            ]
        else:
            pkg_groups = ["packagegroup-robotics-opensource"]
        
        # Add dependencies
        
        for pkg_group in pkg_groups:
            for task in ["do_generate_qirp_sdk", "do_populate_sdk", "do_populate_sdk_ext"]:
                d.appendVarFlag(task, "depends",
                                " {}:do_collect_rdepends".format(pkg_group))

        # for pkg_group in pkg_groups:
        #     d.appendVarFlag('do_generate_qirp_sdk', 'depends', 
        #                    ' {}:do_collect_rdepends'.format(pkg_group))
        
        bb.note("Added dependencies for {}: {}".format(pn, ", ".join(pkg_groups)))
        
        # Add dependencies on sample source code copy tasks
        # Read content_config.json to get list of samples
        import json
        import os
        
        robotics_layer_dir = d.getVar("ROBIOTICS_LAYER_DIR")
        config_file = os.path.join(robotics_layer_dir, "recipes-sdk/files/content_config.json")
        
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    config_data = json.load(f)
                
                samples = config_data.get("samples", [])
                sample_names = [sample.get("name") for sample in samples if sample.get("name")]
                
                if sample_names:
                    bb.note("Adding dependencies on sample source copy tasks for: {}".format(", ".join(sample_names)))
                    for sample_name in sample_names:
                        d.appendVarFlag('do_generate_qirp_sdk', 'depends',
                                       ' {}:do_copy_source_to_deploy'.format(sample_name))
                else:
                    bb.note("No samples found in content_config.json")
            except Exception as e:
                bb.warn("Failed to read or parse content_config.json: {}".format(str(e)))
        else:
            bb.warn("content_config.json not found at: {}".format(config_file))
}

SSTATETASKS += "do_generate_qirp_sdk "
QIRP_SSTATE_OUT_DIR = "${DEPLOY_DIR}/qirpsdk_artifacts/${MACHINE}/"
QIRP_SSTATE_IN_DIR = "${DEPLOY_DIR}/factory/"

do_generate_qirp_sdk[sstate-inputdirs] = "${QIRP_SSTATE_IN_DIR}"
do_generate_qirp_sdk[sstate-outputdirs] = "${QIRP_SSTATE_OUT_DIR}"
do_generate_qirp_sdk[dirs] = "${QIRP_SSTATE_IN_DIR} ${QIRP_SSTATE_OUT_DIR}"
do_generate_qirp_sdk[cleandirs] = "${QIRP_SSTATE_OUT_DIR}"
do_generate_qirp_sdk[stamp-extra-info] = "${MACHINE_ARCH}"

python do_generate_qirp_sdk_setscene () {
    sstate_setscene(d)
}
addtask do_generate_qirp_sdk_setscene

do_generate_qirp_sdk[depends] += "jq-native:do_populate_sysroot git-native:do_populate_sysroot"
addtask do_generate_qirp_sdk after do_populate_sdk
