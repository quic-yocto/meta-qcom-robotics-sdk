# Copyright (c) 2025 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# rdepends-collector.bbclass
# Purpose:
#   Collects direct RDEPENDS from a packagegroup recipe and writes the result
#   into ROBOTICS_PACKAGEGROUP_LIST_DIR as a plain package list file.
#
# Main responsibilities:
#   1. Add a do_collect_rdepends task after package output is generated.
#   2. Read the packagegroup's direct runtime dependencies.
#   3. Write one package name per line into a deploy-side list file.
#   4. Always append qirp-sdk so the SDK package is included in generated images.
#   5. Remove generated list files during cleanup.
#
# Relationship to other classes:
#   The generated *.list files are consumed by psdk-image.bbclass when it
#   collects runtime packages for the final QIRP SDK archive.

# register sstate tasks
SSTATETASKS += "do_collect_rdepends"

# add private staging
ROBOTICS_PACKAGEGROUP_LIST_STAGING_DIR = "${WORKDIR}/packagegroup-lists-staging"

# task write to private staging dir
do_collect_rdepends[sstate-inputdirs] = "${ROBOTICS_PACKAGEGROUP_LIST_STAGING_DIR}"
# recover from sstate dir
do_collect_rdepends[sstate-outputdirs] = "${ROBOTICS_PACKAGEGROUP_LIST_DIR}"
# ensure input/output path exist
do_collect_rdepends[dirs] = "${ROBOTICS_PACKAGEGROUP_LIST_STAGING_DIR} ${ROBOTICS_PACKAGEGROUP_LIST_DIR}"

# clean staging path before run task
do_collect_rdepends[cleandirs] = "${ROBOTICS_PACKAGEGROUP_LIST_STAGING_DIR}"
# sperate different MACHINE_ARCH sstate cache
do_collect_rdepends[stamp-extra-info] = "${MACHINE_ARCH}"

# Add task: collect RDEPENDS after packagegroup build
addtask do_collect_rdepends after do_package_write before do_build

# Add a variable for the mandatory SDK package and include it in vardeps
ROBOTICS_SDK_PACKAGE ?= "qirp-sdk"
do_collect_rdepends[vardeps] = "RDEPENDS:${PN} ROBOTICS_SDK_PACKAGE"

# setscene function required by BitBake to recognise do_collect_rdepends as a
# sstate-restorable task. Without this, runqueue.py skips the task from the
# setscene candidate list (it checks for tid + "_setscene" in taskentries), so
# the eSDK inner bitbake never attempts sstate restore and instead tries to run
# the task directly, which is then blocked by BB_SETSCENE_ENFORCE_IGNORE_TASKS.
python do_collect_rdepends_setscene() {
    sstate_setscene(d)
}
addtask do_collect_rdepends_setscene

# Function: do_collect_rdepends
# Collect direct runtime dependencies from the current packagegroup and write
# them into ${ROBOTICS_PACKAGEGROUP_LIST_DIR}/${PN}.list for later SDK packaging use.
python do_collect_rdepends() {
    """
    Collect packagegroup RDEPENDS and write to file
    Only collects direct RDEPENDS, not dependencies of dependencies
    """
    import os
    pn = d.getVar("PN")

    bb.note("Collecting RDEPENDS for packagegroup: {}".format(pn))

    # Get RDEPENDS
    rdepends_var = 'RDEPENDS:{}'.format(pn)
    rdepends = d.getVar(rdepends_var) or ""
    if not rdepends:
        bb.warn("RDEPENDS for {} is empty (will be added later)".format(pn))
        rdepends = ""

    # Write into the private staging dir so sstate can package it correctly.
    # sstate copies staging -> ROBOTICS_PACKAGEGROUP_LIST_DIR on restore.
    list_dir = d.getVar("ROBOTICS_PACKAGEGROUP_LIST_STAGING_DIR")
    os.makedirs(list_dir, exist_ok=True)

    list_file = os.path.join(list_dir, "{}.list".format(pn))

    with open(list_file, 'w') as f:
        for pkg in rdepends.split():
            pkg_clean = pkg.strip()
            if pkg_clean:
                f.write("{}\n".format(pkg_clean))
        # qirp-sdk is a standalone package that must be present in all images.
        sdk_package = d.getVar("ROBOTICS_SDK_PACKAGE") or "qirp-sdk"
        f.write("{}\n".format(sdk_package))

    package_count = len(rdepends.split())
    bb.note("Wrote {} packages to {}".format(package_count, list_file))
}

# Function: do_clean_rdepends
# Remove only this recipe's list file during cleanall so stale package lists
# are not reused by later builds. Note: do_cleansstate already removes the file
# via the sstate manifest, so this task only handles the non-sstate path
# (e.g. when the file was written directly without going through sstate).
addtask do_clean_rdepends before do_cleanall

do_clean_rdepends() {
    rm -f ${ROBOTICS_PACKAGEGROUP_LIST_DIR}/${PN}.list
}
