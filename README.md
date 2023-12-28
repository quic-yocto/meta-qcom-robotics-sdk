# Welcome to Qualcomm Intelligent Robotics Product (QIRP) SDK

This is the layer designed to generate **QIRP**(**Q**ualcomm **I**ntelligent **R**obotics **P**roduct) SDK. The QIRP SDK is designed to deliver out-of-box robotics samples and easy-to-develop experience on Qualcomm robotics platforms.

This documentation is intended to help you understand the basic features of the QIRP SDK and get started it quickly. And you will learn:

- What is the QIRP SDK
- How to sync and build QIRP SDK
- How to install and uninstall QIRP SDK
- How to develop application with QIRP SDK

# Introduction

QIRP SDK collects artifacts from various Qualcomm SDKs, and selectively picks the libs for robotics use cases.

The QIRP SDK is advantageous as it provides the following:

out-of-box samples:
- Various modules. Not only useful for verifying SDK functions, These modules also serve as a reference or code base for helping developers to quickly develop their own applications.
- e2e scenario samples. Help developers to evaluate the robotics platforms as systematic solution.

easy-to-develop experience
- Various libs for robotics applications, such as AI, multimedia, robotics specific libs.
- Integrated cross-compile toolchain, which includes common build tools, such as `aarch64-oe-linux-gcc`, `make`, `cmake`, and `ros core`. Developers can build their applications with their familiar approaches.
- Tools and scripts to help customer accelerate the development.
- Documents that describe how to set up the QIRP SDK and tutorials on how to quickly start to develop your own applications.
- (Planning Features)Robotics IDE will be launched to support development with QIRP SDK.

NOTE: This release provides ROS2 core enablement only, other features are expected in future release.

# QIRP SDK Generation

**QIRP packages are generated combined with Qualcomm Linux 1.0 base in Alpha release. Further, QIRP will also support standalone way to generated SDK packages later.**

The initial generation of the QIRP SDK includes the software synchronization and compilation procedures.

1. HOST setup

Refer to [qcom-manifest/README.md](https://github.com/quic-yocto/qcom-manifest/blob/qcom-linux-kirkstone/README.md#host-setup) setup the host environment.

2. Download code base

```shell
repo init -u https://github.com/quic-yocto/qcom-manifest -b qcom-linux-kirkstone -m qcom-6.6.00-QLI.1.0-Ver.1.1_robotics.xml

repo sync -c -j8
```

3. Environment setup for QIRP generation

In order to unify the compilation environment, the compilation of QIRP SDK will be completed in docker, so the following additional packages are required.
```shell
apt install docker.io
```

- Docker build

NOTE: The Dockerfile is in `<codebase>/layers/meta-qcom-robotics/files/Dockerfile/Dockerfile`.

```shell
cp <codebase>/layers/meta-qcom-robotics/files/Dockerfile/Dockerfile .

docker build --build-arg IMAGE_OS=focal \
    --build-arg HOST_USER_ID=$(id -u ${USER}) \
    --build-arg HOST_GROUP_ID=$(id -g ${USER}) \
    --build-arg HOST_USER=${USER} \
    --build-arg HOST_GROUP=$(getent group $(id -g ${USER}) | cut -d ':' -f 1) \
    --build-arg USER_EMAIL=<Your Email> \
    -f Dockerfile -t <image_name> .
```

NOTE: You can replace `<image_name>` with the custom docker image name.

e.g.
```shell
docker build --build-arg IMAGE_OS=focal \
    --build-arg HOST_USER_ID=$(id -u ${USER}) \
    --build-arg HOST_GROUP_ID=$(id -g ${USER}) \
    --build-arg HOST_USER=${USER} \
    --build-arg HOST_GROUP=$(getent group $(id -g ${USER}) | cut -d ':' -f 1) \
    --build-arg USER_EMAIL=visitor@mail.com \
    -f Dockerfile -t my_docker_image .
```

- Docker run

```shell
export CODEBASE=/path/to/host/codebase

docker run --rm -d -it  -u $(id -u ${USER}) -v $CODEBASE:/path/in/container/workspace --privileged --name=<container_name> <image_name> /bin/bash
```
*If you encounter network problems, please try running again.*

NOTE: The `/path/to/host/codebase:/path/in/container/workspace` means that the host path `/path/to/host/codebase` will be mapped to the container path `/path/in/container/workspace`. The `<container_name>` is your custom container image name.

e.g.
```shell
export CODEBASE=/path/to/host/codebase

docker run --rm -d -it  -u $(id -u ${USER}) -v $CODEBASE:/home/qirp-workspace --privileged --name=my_container_name my_docker_image /bin/bash
```

- Docker exec

Switch into container rootfs.
```shell
docker exec -it -u $(id -u ${USER}) <container_name> /bin/bash
```

e.g.
```shell
docker exec -it -u $(id -u ${USER}) my_container_name /bin/bash
```

4. Generate QIRP SDK

```shell
MACHINE=qcm6490 DISTRO=qcom-robotics-ros2-humble source setup-robotics-environment

../qirp-build qcom-robotics-full-image
```

Then `qirp-sdk_<qirp_version>.tar.gz` will be in `build-qcom-robotics-ros2-humble/tmp-glibc/deploy/artifacts` directory

# Application Development

This section will introduce how to develop applications on linux machine with QIRP SDK.

NOTE: Before application development, please refer to [meta-qcom-robotics/README.md](https://github.com/quic-yocto/meta-qcom-robotics/blob/kirkstone/README.md) flash the image into your Qualcomm robotics platforms.
## Set up the development environment

### Set up the cross-compile environment

To set up the environment for application development, follow these steps:

1. Decompress the QIRP SDK.

Exit docker and change to the artifacts directory.

``` shell
exit

cd <codebase>/build-qcom-robotics-ros2-humble/tmp-glibc/deploy/artifacts
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
adb devices
adb push ./runtime/qirp-sdk /opt/runtime/
adb shell "chmod +x /opt/runtime/qirp-sdk/*.sh"
adb shell "/opt/runtime/qirp-sdk/install.sh"
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
adb push hello /opt/
adb shell
./opt/hello
```

NOTE: For the further development, please refer to QIRP SDK documents, to be released later.

