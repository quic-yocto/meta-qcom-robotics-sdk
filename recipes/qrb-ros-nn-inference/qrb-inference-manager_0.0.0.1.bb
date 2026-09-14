inherit ros_distro_${ROS_DISTRO} pkgconfig
inherit ros_component robotics-package

DESCRIPTION = "Lib of qrb-ros-nn-inference"
AUTHOR = "Na Song <nasong@qti.qualcomm.com>"
ROS_AUTHOR = "Na Song"
SECTION = "devel"
LICENSE = "BSD-3-Clause-Clear"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/${LICENSE};md5=7a434440b651f4a472ca93716d01033a"

ROS_CN = "qrb_inference_manager"
ROS_BPN = "qrb_inference_manager"

BUILD_DEPENDS = " \
    qairt-sdk \
    tensorflow-lite \
"

ROS_BUILD_DEPENDS = " \
"

ROS_BUILDTOOL_DEPENDS = " \
    ament-cmake-auto-native \
"

ROS_EXPORT_DEPENDS = " \
"

ROS_BUILDTOOL_EXPORT_DEPENDS = ""

ROS_EXEC_DEPENDS = " \
    rclcpp \
    qairt-sdk \
    tensorflow-lite \
"

ROS_TEST_DEPENDS = " \
    ament-lint-auto \
    ament-lint-common \
"

DEPENDS = "${BUILD_DEPENDS} ${ROS_BUILD_DEPENDS} ${ROS_BUILDTOOL_DEPENDS}"
DEPENDS += "${ROS_EXPORT_DEPENDS} ${ROS_BUILDTOOL_EXPORT_DEPENDS} ${ROS_TEST_DEPENDS}"

RDEPENDS:${PN} += "${ROS_EXEC_DEPENDS}"

#Disable the split of debug information into -dbg files
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

SRC_URI = "git://github.com/qualcomm-qrb-ros/qrb_ros_nn_inference.git;protocol=https;branch=stable/1.0.0;subdir=${BPN}-${PV} \
           file://0001-feat-replace-tflite-Cpp-API-to-C-API.patch;striplevel=2 \
           file://0002-feat-modify-TFLite-C-API.patch;striplevel=2 \
           file://0003-fix-stop-leaking-DSP-mappings-when-a-signal-arrives.patch;striplevel=1;patchdir=${UNPACKDIR}/${BPN}-${PV} \
"
SRCREV = "8fe767525171346fa00797c8eef1585746b299a9"
S = "${UNPACKDIR}/${BPN}-${PV}/${ROS_CN}"

ROS_BUILD_TYPE = "ament_cmake"

inherit ros_${ROS_BUILD_TYPE}

# QAIRT(QNN) headers are installed under ${includedir}/QNN/, but upstream includes
# use e.g. #include "QnnInterface.h" (without QNN/ prefix). Add include path here.
CPPFLAGS:append = " -I${RECIPE_SYSROOT}${includedir}/QNN"
CXXFLAGS:append = " -I${RECIPE_SYSROOT}${includedir}/QNN"

inherit robotics-package
