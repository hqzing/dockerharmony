#!/bin/bash
set -e

apt update
apt install -y \
    bison \
    ccache \
    default-jdk \
    flex \
    gcc-arm-linux-gnueabi \
    gcc-arm-none-eabi \
    genext2fs \
    liblz4-tool \
    libssl-dev \
    libtinfo5 \
    mtd-utils \
    mtools \
    openssl \
    ruby \
    scons \
    unzip \
    u-boot-tools \
    zip \
    python-is-python3 \
    pkg-config \
    aria2 \
    cmake \
    autoconf \
    libtool

WORKDIR=$(pwd)

# Download OpenHarmony source code
rm -rf OpenHarmony-v6.0-Release code-v6.0-Release.tar.gz
aria2c -s 16 -x 16 -k 1M https://repo.huaweicloud.com/openharmony/os/6.0-Release/code-v6.0-Release.tar.gz
tar -zxf code-v6.0-Release.tar.gz
cd OpenHarmony-v6.0-Release/OpenHarmony

# Disable HiLog because the container does not include the HiLog service.
cd third_party/musl/
patch -p1 < $WORKDIR/disable-hilog.patch
cd ../../

# Build OpenHarmony operating system image, output in out/rk3568/packages/phone/images/
./build.sh --product-name rk3568 --target-cpu arm64
