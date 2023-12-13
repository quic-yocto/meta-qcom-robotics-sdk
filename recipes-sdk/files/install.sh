#!/bin/bash

# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

SDK_NAME="QIRP_SDK"

FOUND_PKGS=""
PKG_LIST_DIR="/data/"
PKG_LIST_FILE="$PKG_LIST_DIR/$SDK_NAME.list"

ALL_PKGS="\
    qirp-sdk \
"

# check permission for execute this script
function check_permission() {
    if [ "$(whoami)" != "root" ]; then
        echo "ERROR: need root permission"
        exit 1
    fi
}

# scan packages in current path
function scan_packages() {
    FOUND_PKGS=`find . -name "*.ipk" -o -name "*.deb" \
        | grep -v "\-dbg_" \
        | grep -v "\-dev_" \
        | grep -v "\-staticdev_" \
        | tr '\n' ' '`
}

# install packages and save list to file
function install_packages() {
    
    if lsb_release -a 2>/dev/null | grep -q "Ubuntu"; then
        install_command="dpkg -i --force-overwrite --force-depends "
    else
        install_command="opkg install --force-reinstall --force-depends --force-overwrite"
    fi

    for PKG_FILE in $FOUND_PKGS; do
        $install_command $PKG_FILE
    done

    if [ ! -d "$PKG_LIST_DIR" ]; then
        mkdir -p "$PKG_LIST_DIR"
    fi

    if [ -f "$PKG_LIST_FILE" ]; then
        rm -f "$PKG_LIST_FILE"
    fi

    for pkg in $FOUND_PKGS; do
        pkg_name=`echo $pkg | awk -F'/' '{print $NF}' | awk -F'_' '{print $1}'`
        echo $pkg_name >> $PKG_LIST_FILE
    done
}

function main() {

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo ">>> Install scripts for $SDK_NAME"
    echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    echo

    check_permission

    if [ -f $PKG_LIST_FILE ]; then
        printf "WARN: $SDK_NAME has installed, "
        while true; do
            read -p "Do you wish to install anyway? (Y/N)" yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) exit 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi

    scan_packages
    for pkg in $ALL_PKGS; do
        if echo "$FOUND_PKGS" | grep -q "$pkg"; then
            echo "NOTE: found package: '$pkg'"
        else
            echo "ERROR: not found package: '$pkg'"
            exit 1
        fi
    done

    install_packages
}

main "$@"
