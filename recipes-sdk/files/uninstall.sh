#!/bin/bash

# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

SDK_NAME="QIRP_SDK"

REMOVE_PKGS=()
PKG_LIST_FILE="/opt/qcom/qirp-sdk/data/$SDK_NAME.list"

# check permission for execute this script
function check_permission() {
    if [ "$(whoami)" != "root" ]; then
        echo "ERROR: need root permission"
        exit 1
    fi
}

function main() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo ">>> Uninstall scripts for $SDK_NAME"
    echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    echo

    check_permission

    if [ ! -f $PKG_LIST_FILE ]; then
        echo "ERROR: $SDK_NAME has not installed"
        exit 1
    fi

    if lsb_release -a 2>/dev/null | grep -q "Ubuntu"; then
        uninstall_command="dpkg -r --force-depends"
    else
        uninstall_command="opkg remove --force-depends --force-remove"
    fi

    for pkg in `cat $PKG_LIST_FILE`; do
        REMOVE_PKGS="$REMOVE_PKGS $pkg"
    done

    for PKG_FILE in $REMOVE_PKGS; do
        $uninstall_command $PKG_FILE
    done

    rm -rf $PKG_LIST_FILE
}

main "$@"
