#!/bin/bash
set -e

apt update
apt install -y gzip cpio patchelf

# Extract necessary files from the operating system image.
rm -rf system ramdisk
mkdir system-tmp
mount -o loop OpenHarmony-v6.1-Release/OpenHarmony/out/rk3568/packages/phone/images/system.img system-tmp
cp -r system-tmp system
umount system-tmp
rm -rf system-tmp
mkdir ramdisk
cp OpenHarmony-v6.1-Release/OpenHarmony/out/rk3568/packages/phone/images/ramdisk.img ramdisk/ramdisk.img.gz
cd ramdisk
gunzip ramdisk.img.gz
cpio -i -F ramdisk.img
rm ramdisk.img
cd ..
cp system/system/lib64/libc++_shared.so ramdisk/lib64/

# Complete the FHS directory.
ln -s ../bin ramdisk/usr/bin
ln -s ../lib ramdisk/usr/lib
ln -s ../lib64 ramdisk/usr/lib64
mkdir ramdisk/opt
mkdir ramdisk/tmp
mkdir ramdisk/root
chmod 700 ramdisk/root

# These files are not needed because init is not required in the container environment.
rm ramdisk/init
rm ramdisk/bin/init_early
rm ramdisk/lib64/libinit_stub_empty.so
rm ramdisk/lib64/libinit_module_engine.so
rm ramdisk/lib64/platformsdk/libsec_shared.z.so
rm ramdisk/lib64/chipset-sdk-sp/libsec_shared.z.so
rm ramdisk/lib64/platformsdk/librestorecon.z.so
rm ramdisk/lib64/libload_policy.z.so

# This file is only used by SELinux-related command-line tools and can be removed from the container.
rm ramdisk/lib64/libsepol.z.so

# For toybox and curl.
cp system/system/lib64/platformsdk/libcrypto_openssl.z.so ramdisk/lib64/platformsdk/

# For curl.
cp curl-8.8.0-ohos-arm64/bin/curl ramdisk/bin/
patchelf --replace-needed libssl.so.3 libssl_openssl.z.so ramdisk/bin/curl
patchelf --replace-needed libcrypto.so.3 libcrypto_openssl.z.so ramdisk/bin/curl
patchelf --replace-needed libz.so.1 libshared_libz.z.so ramdisk/bin/curl
cp system/system/lib64/platformsdk/libssl_openssl.z.so ramdisk/lib64/platformsdk/
cp system/system/lib64/chipset-sdk-sp/libshared_libz.z.so ramdisk/lib64/platformsdk/
mkdir -p ramdisk/etc/ssl/certs
cp system/system/etc/ssl/certs/cacert.pem ramdisk/etc/ssl/certs/

# This NOTICE.txt file was copied from system.img and is located in system/etc/NOTICE.txt.
# I have removed the files not included in this container image from the NOTICE.txt and added an item for /bin/curl.
# When the container image changes, the content inside NOTICE.txt needs to be updated.
temp_a=$(mktemp)
temp_b=$(mktemp)
find ramdisk -type f | sed 's/^ramdisk//' | sort > $temp_a
cat NOTICE.txt | awk NF | grep '^/[a-zA-Z]' | sort > $temp_b
if ! cmp -s $temp_a $temp_b; then
    echo "NOTICE.txt does not match the files in the actual image, NOTICE.txt needs to be updated."
    diff -u $temp_a $temp_b
    exit 1
fi

# /etc/passwd and /etc/group are not third-party dependencies and are intentionally excluded from the NOTICE.txt file.
echo "root:x:0:0:root:/root:/bin/sh" > ramdisk/etc/passwd
echo "root:x:0:" > ramdisk/etc/group

cp NOTICE.txt ramdisk/etc/
