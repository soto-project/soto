#!/bin/sh

VERSION="4.1.3"

UNAME=$(uname);
if [ "Darwin" = "${UNAME}" ];
then
    OS="macos";
else
    if [ "Linux" = "${UNAME}" ];
    then
        UBUNTU_RELEASE=$(lsb_release -r 2>/dev/null | cut -f2);
        case "${UBUNTU_RELEASE}" in
            16.04) OS="ubuntu1604";;
            15.10) OS="ubuntu1510";;
            14.04) OS="ubuntu1404";;
            *) echo "Unsupported distro!"; exit 1;;
        esac
    fi
fi

if [ "macos" = "${OS}" ];
then
    brew install libressl
else
    sudo apt-get install -y clang libicu-dev uuid-dev pkg-config libssl-dev

    SWIFTFILE="swift-${VERSION}-RELEASE-ubuntu${UBUNTU_RELEASE}";
    if [ -d "${PWD}/${SWIFTFILE}" ];
    then
        echo "Swift ${VERSION} already downloaded."
    else
        wget "https://swift.org/builds/swift-${VERSION}-release/${OS}/swift-${VERSION}-RELEASE/${SWIFTFILE}.tar.gz"
        tar -zxf "${SWIFTFILE}.tar.gz"
        export PATH="${PWD}/${SWIFTFILE}/usr/bin:${PATH}"
    fi
fi
