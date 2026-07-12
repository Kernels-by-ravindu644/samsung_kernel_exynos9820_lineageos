#!/bin/bash
# Copyright (c) 2026 ravindu644 <droidcasts@protonmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Build script for exynos9820/9825 LineageOS kernel

set -euo pipefail

SCRIPT_DIR="$(dirname $(readlink -fq "$0"))"
cd "${SCRIPT_DIR}"

KERNEL_VERSION="$(make kernelversion 2>/dev/null)"

# init & update git submodules
git submodule update --init --recursive

# download & install clang-r563880c
if [ ! -d "${HOME}/toolchains/clang-r563880c" ]; then
    echo -e "Cloning clang-r563880c..."
    mkdir -p "${HOME}/toolchains/clang-r563880c" && cd "${HOME}/toolchains/clang-r563880c"

    curl -LO "https://github.com/ravindu644/Android-Kernel-Tutorials/releases/download/toolchains/clang-r563880c.tar.gz" || {
    echo "Failed to download clang-r563880c. Please check your internet connection and try again." && exit 1
    }

    tar -xf clang-r563880c.tar.gz && rm clang-r563880c.tar.gz
    cd "${SCRIPT_DIR}"
fi

# cleanup before building
rm -rf "${SCRIPT_DIR}/"{out,dist} && \
    mkdir -p "${SCRIPT_DIR}/"{out,dist}

# export toolchain paths
export PATH="${HOME}/toolchains/clang-r563880c/bin:${PATH}"

# build options for the kernel
export BUILD_OPTIONS=(
    -C "${SCRIPT_DIR}"
    O="${SCRIPT_DIR}/out"
    -j$(nproc)
    ARCH=arm64
    LLVM=1
    LLVM_IAS=1
    HOSTCC=gcc
    HOSTCXX=g++
)

build_kernel(){
    # cleanup
    make "${BUILD_OPTIONS[@]}" clean && \
        make "${BUILD_OPTIONS[@]}" mrproper

    # make default configuration.
    make "${BUILD_OPTIONS[@]}" exynos9820-beyond2lte_defconfig

    # configure the kernel
    #make "${BUILD_OPTIONS[@]}" menuconfig

    # build the kernel
    make "${BUILD_OPTIONS[@]}" Image

    # copy the built kernel to the dist directory
    cp "${SCRIPT_DIR}/out/arch/arm64/boot/Image" "${SCRIPT_DIR}/dist"
}

build_kernel
