inherit ros_distro_${ROS_DISTRO} pkgconfig
inherit ros_component robotics-package

DESCRIPTION = "Package for performing neural network model inference"
AUTHOR = "Na Song <nasong@qti.qualcomm.com>"
ROS_AUTHOR = "Na Song"
SECTION = "devel"
LICENSE = "BSD-3-Clause-Clear"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/${LICENSE};md5=7a434440b651f4a472ca93716d01033a"

ROS_CN = "qrb_ros_nn_inference"
ROS_BPN = "qrb_ros_nn_inference"

ROS_BUILD_DEPENDS = " \
    rclcpp \
    std-msgs \
    ament-index-cpp \
    rclcpp-components \
    qrb-inference-manager \
    qrb-ros-tensor-list-msgs \
"

ROS_BUILDTOOL_DEPENDS = " \
    ament-cmake-auto-native \
"

ROS_EXPORT_DEPENDS = " \
    rclcpp \
    ament-index-cpp \
"

ROS_BUILDTOOL_EXPORT_DEPENDS = ""

ROS_EXEC_DEPENDS = " \
    rclcpp \
    rclcpp-components \
    qrb-ros-tensor-list-msgs \
"

ROS_TEST_DEPENDS = " \
    ament-lint-auto \
    ament-lint-common \
    ament-cmake-gtest \
    ament-cmake-copyright \
    ament-cmake-cppcheck \
    ament-cmake-cpplint \
    ament-cmake-flake8 \
    ament-cmake-lint-cmake \
    ament-cmake-pep257 \
    ament-cmake-uncrustify \
    ament-cmake-xmllint \
    rclcpp-components \
"

DEPENDS = "${ROS_BUILD_DEPENDS} ${ROS_BUILDTOOL_DEPENDS}"
DEPENDS += "${ROS_EXPORT_DEPENDS} ${ROS_BUILDTOOL_EXPORT_DEPENDS} ${ROS_TEST_DEPENDS}"

RDEPENDS:${PN} += "${ROS_EXEC_DEPENDS}"

SRC_URI = "git://github.com/qualcomm-qrb-ros/qrb_ros_nn_inference.git;protocol=https;branch=stable/1.0.0;subdir=${BPN}-${PV} \
           file://0003-fix-stop-leaking-DSP-mappings-when-a-signal-arrives.patch;striplevel=1;patchdir=${UNPACKDIR}/${BPN}-${PV} \
"
SRCREV = "8fe767525171346fa00797c8eef1585746b299a9"
S = "${UNPACKDIR}/${BPN}-${PV}/${ROS_CN}"

ROS_BUILD_TYPE = "ament_cmake"
inherit ros_${ROS_BUILD_TYPE}

inherit robotics-package
