# Copyright (c) 2025 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

# To include host packages in SDK
#TOOLCHAIN_HOST_TASK:append = " nativesdk-protobuf-compiler "

# To include target packages in SDK
#TOOLCHAIN_TARGET_TASK:append = " resize-partitions"

#TOOLCHAIN_TARGET_TASK:append = " opencv"


# To provide tools for ROS node compile in SDK
TOOLCHAIN_HOST_TASK:append = "${@bb.utils.contains_any('DISTRO_FEATURES', 'ros2-humble ros2-jazzy', ' \
    nativesdk-ament-package \
    nativesdk-python3-colcon-common-extensions \
    nativesdk-python3-numpy \
    nativesdk-rosidl-adapter \
    nativesdk-rosidl-cli \
    nativesdk-rosidl-cmake \
    nativesdk-rosidl-generator-c \
    nativesdk-rosidl-generator-cpp \
    nativesdk-rosidl-parser \
    nativesdk-rosidl-typesupport-c \
    nativesdk-rosidl-typesupport-cpp \
    nativesdk-rosidl-typesupport-fastrtps-c \
    nativesdk-rosidl-typesupport-fastrtps-cpp \
    nativesdk-rosidl-typesupport-introspection-c \
    nativesdk-rosidl-typesupport-introspection-cpp \
', '', d)}"

# To provide libs for ROS node compile in SDK
ROS_SDK_TARGET_PACKAGES:append = "${@bb.utils.contains('DISTRO_FEATURES', 'ros2-jazzy', ' \
    python-cmake-module \
', '', d)}"


TOOLCHAIN_TARGET_TASK:remove = "qirp-sdk"

# Add default packages from meta-ros ros-sdk.inc
TOOLCHAIN_HOST_TASK:append = "${@(' ' + (d.getVar('ROS_SDK_HOST_PACKAGES') or '')) if d.getVar('PN') != 'buildtools-tarball' else ''}"

# NOTE: fmt-staticdev is intentionally NOT listed here. oe-core's fmt recipe
# builds shared-only (-DBUILD_SHARED_LIBS=ON, kept for the spdlog ABI patch),
# so fmt-staticdev is an empty package (no libfmt.a) and no RPM is generated
# for it - do_populate_sdk then fails with "Unable to find a match:
# fmt-staticdev". fmt headers and libfmt.so still reach the SDK via fmt-dev
# pulled in by the ROS packages. octomap/osqp-vendor do ship static libs.
TOOLCHAIN_TARGET_TASK:append = "${@(' ' + (d.getVar('ROS_SDK_TARGET_PACKAGES') or '') + ' sed octomap-staticdev osqp-vendor-staticdev') if d.getVar('PN') != 'buildtools-tarball' else ''}"

# esdk fix for populate_sdk_ext:
# 1. BB_SETSCENE_ENFORCE_IGNORE_TASKS: The inner eSDK build uses %:* to allow
#    all BUILD TARGET tasks to run from scratch, but this expands only to the
#    specific targets (qcom-robotics-proprietary-image, esp-qcom-image, etc.).
#    Dependency recipes like packagegroup-robotics-opensource are NOT targets,
#    so their tasks (e.g. do_collect_rdepends from rdepends-collector.bbclass)
#    are not covered and fail with "setscene ignore_tasks".
#    Fix: add *:do_collect_rdepends to allow it to run from scratch.
BB_SETSCENE_ENFORCE_IGNORE_TASKS:append = " *:do_collect_rdepends"
