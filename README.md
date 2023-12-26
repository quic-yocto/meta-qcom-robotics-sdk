# Welcome to the QIRP SDK

This is the layer designed to generate **QIRP**(**Q**ualcomm **I**ntelligent **R**obotics **P**roduct) SDK. The QIRP SDK is designed to help customers to quickly develop applications on Qualcomm robotics platforms. 

This documentation is intended to help you understand the basic features of the QIRP SDK and get started using it quickly.

In this documentation, you will learn:

- What is the QIRP SDK ?
- How to sync and build QIRP SDK
- How to install and uninstall QIRP SDK
- How to develop application with QIRP SDK

Let's get started !

# Introduction

QIRP SDK collects artifacts from various functional SDKs, and selectively picks the libs which are useful for robotics use cases. Once the QIRP SDK is setup, the libs from other functional SDKs are also ready for use. The functional SDKs include but are not limited to SNPE SDK, QIM SDK, Robotics Function SDK. In the future, more and more Qualcomm SDKs will be integrated into the QIRP SDK. 

The QIRP SDK is advantageous as it provides the following:

- Various libs for applications, such as AI, multimedia, robotics specific libs.
- Various modules, which is not only useful for verifying SDK functions, but also serve as a reference or code base for helping developers to quickly develop their own applications.
- A cross-compile toolchain, which integrates common build tools, such as `aarch64-oe-linux-gcc`, `make`, `cmake`, and `pkg-config`. Developers can build their applications with familiar tools.
- Tools and scripts to help customer accelerate the development.
- Documents that describe how to set up the QIRP SDK and tutorials on how to quickly start to develop your own applications.
- (Future feature) Robotics IDE will be launched to support development with QIRP SDK.
# QIRP SDK Generation

The initial generation of the QIRP SDK includes the software synchronization and compilation procedures.

1. Download code base
```shell
repo init -u https://github.com/quic-yocto/qcom-manifest -b qcom-linux-kirkstone -m qcom-6.6.00-QLI.1.0-Ver.1.0_robotics.xml

repo sync
```

2. Build the docker image

NOTE: The Dockerfile is in `codebase/ layers/meta-qcom-robotics/files/Dockerfile/Dockerfile`.

```shell
docker build --build-arg IMAGE_OS=focal \
    --build-arg HOST_USER_ID=$(id -u ${USER}) \
    --build-arg HOST_GROUP_ID=$(id -g ${USER}) \
    --build-arg HOST_USER=${USER} \
    --build-arg HOST_GROUP=$(getent group $(id -g ${USER}) | cut -d ':' -f 1) \
    --build-arg USER_EMAIL=<Your Email> \
    -f Dockerfile -t <image_name> .
```

3. Run the docker

```shell
docker run --rm -d -it  -u $(id -u ${USER}) -v <worskspace>:<worskspace> --privileged --name=<container_name> <image_name>  /bin/bash
```

4. Enter the docker

```shell
docker exec -it -u $(id -u ${USER}) <container_name> /bin/bash
```

5. Generate QIRP SDK
```shell
MACHINE=qcm6490 DISTRO=qcom-robotics-ros2-humble source setup-robotics-environment

../qirp-build qcom-robotics-full-image
```

Then `qirp-sdk_<qirp_version>.tar.gz` will be in `build-qcom-robotics-ros2-humble/tmp-glibc/deploy/artifacts` directory

# Application Development

This section introduces how to develop applications on linux machine with QIRP SDK.
## Set up the development environment

### Set up the cross-compile environment

To set up the environment for application development, follow these steps:

1. Decompress the QIRP SDK.

Change to the artifacts directory.

``` shell
cd $qirp_workspace/build-qcom-robotics-ros2-humble/tmp-glibc/deploy/artifacts
```

Decompress the package using the `tar` command.

``` shell
tar -zxf qirp-sdk_<qirp_version>.tar.gz
```

**Note:**  The `qirp-sdk_<qirp_version>.tar.gz` is in the deployed path of QIRP artifacts. The <qirp_version> changes with each release, such as 2.0.0, 2.0.1. For example, the whole package name can be qirp-sdk_2.0.0.tar.gz. For all released versions, see QIRP SDK overview.

Check the decompressed files.

``` shell
tree qirp-sdk -L 1
├── runtime
├── setup.sh
└── toolchain
```

2. Set up the QIRP cross-compile environment.

``` shell
cd qirp-sdk
source setup.sh
```

### Set up the run-time environment

Ensure that the device is connected to the host machine.

To deploy the QIRP artifacts, push the QIRP files to the device using the following commands.

``` shell
cd qirp-sdk
adb devices
adb shell mount -o remount,rw /
adb push qirp-sdk /runtime/qirp-sdk /data/
adb shell "chmod +x /data/runtime/qirp-sdk/*.sh"
adb shell "/data/runtime/qirp-sdk/install.sh"
```

This section introduces how to develop applications on linux machine with QIRP SDK.

## Compile and run the sample code

The following examples provide a general procedure for developing an application using the QIRP SDK.

**CMakeHelloWorld**

1. Clone an OSS project from github.

``` shell
git clone https://github.com/MattClarkson/CMakeHelloWorld.git
```

2. Compile the application using these commands

``` shell
source setup.sh
cd CMakeHelloWorld/ && cmake .
make
```

3. Push the generated binary to the device.

``` shell
adb devices
adb push hello /data
adb shell
./data/hello
```

