#!/bin/sh

set -eux

VERSION="5.0"

UNAME=$(uname);
if [ "${UNAME}" = "Darwin" ];
then
    OS="macos";
else
    if [ "${UNAME}" = "Linux" ];
    then
        UBUNTU_RELEASE=$(lsb_release -r 2>/dev/null | cut -f2);
        case "${UBUNTU_RELEASE}" in
            18.04) OS="ubuntu1804";;
            16.04) OS="ubuntu1604";;
            15.10) OS="ubuntu1510";;
            14.04) OS="ubuntu1404";;
            *) echo "Unsupported distro!"; exit 1;;
        esac
    fi
fi

if [ "macos" != "${OS}" ];
then
    dpkg -s libssl-dev | grep Status | grep -q install 2> /dev/null
    if [ $? -ne 0 ];
    then
        set +x
        echo "Installing"
        set -x
        sudo apt-get install -y clang libicu-dev uuid-dev pkg-config libssl-dev
    fi

    SWIFTFILE="swift-${VERSION}-RELEASE-ubuntu${UBUNTU_RELEASE}";
    if [ -d "${PWD}/${SWIFTFILE}" ];
    then
        set +x
        echo "Swift ${VERSION} already downloaded."
        set -x
    else
        wget "https://swift.org/builds/swift-${VERSION}-release/${OS}/swift-${VERSION}-RELEASE/${SWIFTFILE}.tar.gz"
        tar -zxf "${SWIFTFILE}.tar.gz"
        export PATH="${PWD}/${SWIFTFILE}/usr/bin:${PATH}"
    fi
fi

set +ux
