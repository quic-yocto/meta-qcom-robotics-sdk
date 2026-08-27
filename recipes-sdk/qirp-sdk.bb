#License applicable to the recipe file only,  not to the packages installed by this recipe.
LICENSE = "BSD-3-Clause-Clear"

inherit psdk-base psdk-package psdk-pickup

CONFIGFILE = "${@d.getVar('CONFIG_SELECT')}"
SRC_URI = "file://${@d.getVar('CONFIG_SELECT')}"
SRC_URI =+ "file://install.sh"
SRC_URI =+ "file://uninstall.sh"
SRC_URI =+ "file://qirp-setup.sh"
SRC_URI =+ "file://qirp-upgrade.sh"
SRC_URI =+ "file://samples.json"
SRC_URI =+ "file://qrb_ros_samples_scripts/"

# The path infos of qirp content
OSS_CHANNEL_FLAG = "${@bb.utils.contains_any('BBFILE_COLLECTIONS', 'qcom-robotics-extras', 'false', 'true', d)}"
TOOLCHAIN_PATH = "${DEPLOY_DIR}/sdk"
SETUP_PATH = "${FILE_DIRNAME}/files/setup.sh"

# The name and version of qirp SDK artifact
SDK_PN = "qirp-sdk"
PV = "2.6.2"
FILES:${PN} = "/usr/share/qirp-setup.sh"

# The functionality of qirp SDK
RDEPENDS:${PN}:append = " qti-robotics "
RDEPENDS:${PN}:append:qcom-custom-bsp = "${@bb.utils.contains_any('BBFILE_COLLECTIONS', 'qti-qim-product-sdk', '', ' qti-qim-product-sdk ', d)}"

DEPENDS:append = " \
    jq-native \
    git-native \
    qti-robotics \
"

DEPENDS:append:qcom-custom-bsp = "${@bb.utils.contains_any('BBFILE_COLLECTIONS', 'qti-qim-product-sdk', '', ' qti-qim-product-sdk ', d)}"
