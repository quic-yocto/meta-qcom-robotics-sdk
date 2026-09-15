# Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# robotics-package.bbclass
# Purpose:
#   Provides common packaging behavior for robotics SDK components.
#   This class adjusts install layout, package splitting, package metadata,
#   and selected QA / shlibs behaviors to better match robotics and ROS-style
#   deliverables, including Ubuntu-targeted packaging scenarios.
#
# Main responsibilities:
#   1. Optionally relocate installed files under a configured package prefix.
#   2. Define how runtime, -dev, -staticdev, and -dbg packages are exposed.
#   3. Control RPROVIDES / PROVIDES behavior for the main package outputs.
#   4. Adjust QA and shlibs processing for ROS / Ubuntu integration cases.
#   5. Override package composition dynamically based on dependency settings.
#
SDK_NAME = "qirp"

pkg_dest = " "

# Function: do_move_opt
# Move installed content under ${pkg_dest} when a non-root destination is used.
# This helps recipes share a consistent SDK-oriented install layout.
do_move_opt() {
    if [ "${pkg_dest}" = "/" ] || [ "${pkg_dest}" = " " ]; then
        bbnote "pkg_dest set to root , did not need copy"
    else
        bbnote "copy file from / to ${pkg_dest}"
        install -d ${D}/${pkg_dest}
        for item in ${D}/*; do
            if [ -d "$item" ] && [ "$item" != "${D}/opt" ]; then
                cp -r "$item" "${D}/${pkg_dest}"
            fi
        done
    fi
}

do_install[postfuncs] += "do_move_opt"

# Function: do_copy_source_to_deploy
# Copy all files from S directory to ${DEPLOY_DIR}/sample_source_code/${BPN}/
# This happens after do_patch and before do_package to capture patched source code.
do_copy_source_to_deploy() {
    # Create destination directory: ${DEPLOY_DIR}/sample_source_code/${BPN}/
    dest_dir="${DEPLOY_DIR}/sample_source_code/${BPN}"
    
    # Remove directory if it exists, then recreate it
    if [ -d "${dest_dir}" ]; then
        bbnote "Removing existing directory: ${dest_dir}"
        rm -rf "${dest_dir}"
    fi
    
    install -d "${dest_dir}"
    
    # Copy all files from S directory
    if [ -d "${S}" ]; then
        bbnote "Copying source files from ${S} to ${dest_dir}"
        cp -r "${S}/"* "${dest_dir}/"
    else
        bbwarn "Source directory ${S} does not exist, skipping source copy"
    fi
}

# Add task: copy source to deploy directory after patching
addtask do_copy_source_to_deploy after do_compile before do_package

AUTO_LIBNAME_PKGS = ""

FILES:${PN} += " \
    ${pkg_dest}${bindir} \
    ${pkg_dest}${sbindir} \
    ${pkg_dest}${base_bindir} \
    ${pkg_dest}${base_sbindir} \
    ${pkg_dest}${libexecdir} \
    ${pkg_dest}${sysconfdir} \
"

PROVIDES += "${PN}"

RPROVIDES:${PN} += "${PN}"

FILES:${PN}-dev = "${pkg_dest}${includedir} ${pkg_dest}${base_libdir}/lib*${SOLIBSDEV} \
                ${pkg_dest}${libdir}/lib*${SOLIBSDEV} ${pkg_dest}${libdir}/*.la \
                ${pkg_dest}${libdir}/*.o ${pkg_dest}${libdir}/pkgconfig ${pkg_dest}${datadir}/pkgconfig \
                ${pkg_dest}${datadir}/aclocal ${pkg_dest}${base_libdir}/*.o \
                ${pkg_dest}${libdir}/${BPN}/*.la ${pkg_dest}${base_libdir}/*.la \
                ${pkg_dest}${libdir}/cmake ${pkg_dest}${datadir}/cmake"
SECTION:${PN}-dev = "devel"
PROVIDES += "${PN}-dev"
RPROVIDES:${PN}-dev += "${PN}-dev"
RDEPENDS:${PN}-dev = "${PN} (= ${EXTENDPKGV})"

FILES:${PN}-staticdev = "${pkg_dest}${libdir}/*.a ${pkg_dest}${base_libdir}/*.a ${pkg_dest}${libdir}/${BPN}/*.a"
SECTION:${PN}-staticdev = "devel"
PROVIDES += "${PN}-staticdev"
RPROVIDES:${PN}-staticdev += "${PN}-staticdev"
RDEPENDS:${PN}-staticdev = "${PN}-dev (= ${EXTENDPKGV})"

FILES:${PN}-dbg = "${pkg_dest}${libdir}/debug"

ROS_EXEC_DEPENDS ?= " "
ROS_BUILD_DEPENDS ?= " "

RDEPENDS:${PN}:remove = "${@remove_rdepends(d)}"

INSANE_SKIP:${PN} += "installed-vs-shipped"
INSANE_SKIP:${PN} += "already-stripped"
INSANE_SKIP:${PN} += "${@skip_ros_dev_so_check(d)}"

# while enable ubuntu target compilation ,stop the shlibs

PACKAGEFUNCS:remove = "${@packages_funcs(d)}"

# Function: skip_ros_dev_so_check
# Return the QA check name to skip when ROS dependency settings indicate that
# development symlink validation should not be enforced.
def skip_ros_dev_so_check(d):
    ros_exec_depends = d.getVar("ROS_EXEC_DEPENDS") or ""
    ros_build_depends = d.getVar("ROS_BUILD_DEPENDS") or ""
    if ros_exec_depends.strip() or ros_build_depends.strip():
        return "dev-so"
    return ""
# Function: packages_funcs
# Disable selected package shlibs processing for Ubuntu-targeted ROS builds
# where the default shared library scanning behavior is not desired.
def packages_funcs(d):
    ros_exec_depends = d.getVar("ROS_EXEC_DEPENDS") or ""
    ros_build_depends = d.getVar("ROS_BUILD_DEPENDS") or ""
    ubuntu_version = d.getVar("UBUNTU_VERSION") or ""
    if (ros_exec_depends.strip() or ros_build_depends.strip()) and ubuntu_version.strip():
        return "package_do_shlibs"
    return ""
# Function: remove_rdepends
# Remove automatically generated runtime dependencies for ROS / Ubuntu builds
# when ROS dependency variables explicitly define the desired package content.
def remove_rdepends(d):
    ros_exec_depends = d.getVar("ROS_EXEC_DEPENDS") or ""
    ros_build_depends = d.getVar("ROS_BUILD_DEPENDS") or ""
    ubuntu_version = d.getVar("UBUNTU_VERSION") or ""
    if (ros_exec_depends.strip() or ros_build_depends.strip()) and ubuntu_version.strip():
        return ros_exec_depends
    return ""
# Function: get_runtime_depends
# Helper to read the runtime dependency string for a specific package name.
def get_runtime_depends(PN, d):
    runtime_depends = d.getVar('RDEPENDS:{}'.format(PN))
    if runtime_depends:
        return runtime_depends
    return " "

# Function: __anonymous
# Configure package splitting and package architecture dynamically based on
# ROS dependency variables and the target Ubuntu integration mode.
python __anonymous(){
    package_name = d.getVar("PN")
    ros_exec_depends = d.getVar("ROS_EXEC_DEPENDS") or ""
    ros_build_depends = d.getVar("ROS_BUILD_DEPENDS") or ""
    if not ros_exec_depends.strip() and not ros_build_depends.strip():
        target_package_name = "{}-dev {}-staticdev {} {}-dbg".format(package_name, package_name, package_name, package_name)
    else:
        target_package_name = "{} {}-dbg".format(package_name, package_name)
    d.setVar("PACKAGES", target_package_name)

    soc_arch = d.getVar("MACHINE_ARCH")
    d.setVar('PACKAGE_ARCH', soc_arch)

    ubuntu_version = d.getVar("UBUNTU_VERSION") or ""
    if (ros_exec_depends.strip() or ros_build_depends.strip()) and ubuntu_version.strip():
        d.setVarFlag('do_package_qa', 'noexec', '1')
}
