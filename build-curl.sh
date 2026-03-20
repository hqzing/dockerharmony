#!/bin/bash
set -e

# Setup ohos-sdk
curl -fLO https://repo.huaweicloud.com/openharmony/os/6.0-Release/ohos-sdk-windows_linux-public.tar.gz
mkdir /opt/ohos-sdk
tar -zxf ohos-sdk-windows_linux-public.tar.gz -C /opt/ohos-sdk
cd /opt/ohos-sdk/linux
unzip -q native-*.zip
cd - >/dev/null

# Setup env
LLVM_BIN=/opt/ohos-sdk/linux/native/llvm/bin
export CC=$LLVM_BIN/aarch64-unknown-linux-ohos-clang
export CXX=$LLVM_BIN/aarch64-unknown-linux-ohos-clang++
export LD=$LLVM_BIN/ld.lld
export AR=$LLVM_BIN/llvm-ar
export AS=$LLVM_BIN/llvm-as
export NM=$LLVM_BIN/llvm-nm
export OBJCOPY=$LLVM_BIN/llvm-objcopy
export OBJDUMP=$LLVM_BIN/llvm-objdump
export RANLIB=$LLVM_BIN/llvm-ranlib
export STRIP=$LLVM_BIN/llvm-strip

# Build openssl
curl -fLO https://github.com/openssl/openssl/releases/download/openssl-3.0.9/openssl-3.0.9.tar.gz
tar -zxf openssl-3.0.9.tar.gz
cd openssl-3.0.9/
./Configure --prefix=/opt/openssl-3.0.9-ohos-arm64 linux-aarch64
make -j$(nproc)
make install
cd ..

# Build zlib
curl -fLO https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
tar -zxf zlib-1.3.1.tar.gz
cd zlib-1.3.1
./configure --prefix=/opt/zlib-1.3.1-ohos-arm64
make -j$(nproc)
make install
cd ..

# Build curl. Static linking with libcurl but dynamic linking with other libraries(libc, openssl, zlib).
curl -fLO  https://curl.se/download/curl-8.8.0.tar.gz
tar -zxf curl-8.8.0.tar.gz
cd curl-8.8.0/
./configure \
    --host=aarch64-linux \
    --prefix=/opt/curl-8.8.0-ohos-arm64 \
    --enable-static \
    --disable-shared \
    --with-openssl=/opt/openssl-3.0.9-ohos-arm64 \
    --with-zlib=/opt/zlib-1.3.1-ohos-arm64 \
    --with-ca-bundle=/etc/ssl/certs/cacert.pem \
    --with-ca-path=/etc/ssl/certs \
    CPPFLAGS="-D_GNU_SOURCE"
make -j$(nproc)
make install
cd ..

# Remove old files if exists
rm -rf curl-8.8.0-ohos-arm64

# Copy the build artifacts to the current directory
cp -r /opt/curl-8.8.0-ohos-arm64 ./

# Clean up
rm -rf *.tar.gz openssl-3.0.9 zlib-1.3.1 curl-8.8.0
rm -rf /opt/ohos-sdk /opt/openssl-3.0.9-ohos-arm64 /opt/zlib-1.3.1-ohos-arm64 /opt/curl-8.8.0-ohos-arm64
