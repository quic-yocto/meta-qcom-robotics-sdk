#License applicable to the recipe file only,  not to the packages installed by this recipe.
LICENSE = "BSD-3-Clause-Clear"

require sample-code.inc
inherit psdk-base psdk-package psdk-pickup psdk-sample

SRC_URI = "file://${@d.getVar('CONFIG_SELECT')}"
SRC_URI =+ "file://install.sh"
SRC_URI =+ "file://uninstall.sh"

# The path infos of qirp content
SAMPLES_PATH = "${QIRP_TOP_DIR}/../sources/robotics/qirp-oss/Product_SDK_Samples"
TOOLCHAIN_PATH = "${DEPLOY_DIR}/sdk"
SETUP_PATH = "${FILE_DIRNAME}/files/setup.sh"

# The name and version of qirp SDK artifact
SDK_PN = "qirp-sdk"
PV = "2.0.0"

# This recipe is an example to fetch QIRF sample apps
# DEPENDS += "robotics-sample"

# The functionality of qirp SDK
DEPENDS += "${@bb.utils.contains_any('MACHINE', 'qcm6490', 'qti-robotics', "", d)}"
