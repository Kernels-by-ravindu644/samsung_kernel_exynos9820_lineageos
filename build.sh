#!/bin/bash
# Copyright (c) 2026 ravindu644 <droidcasts@protonmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Build script for exynos9820/9825 LineageOS kernel

set -euo pipefail

SCRIPT_DIR="$(dirname $(readlink -fq "$0"))"
cd "${SCRIPT_DIR}"

KERNEL_VERSION="$(make kernelversion 2>/dev/null)"
MODEL="${1:-beyondx}"

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

# device configuration
declare -A DEVICES=(
    ["beyond0lte"]="exynos9820-beyond0lte_defconfig"
    ["beyond1lte"]="exynos9820-beyond1lte_defconfig"
    ["beyond2lte"]="exynos9820-beyond2lte_defconfig"
    ["beyondx"]="exynos9820-beyondx_defconfig"
    ["d1"]="exynos9820-d1_defconfig"
    ["d1x"]="exynos9820-d1x_defconfig"
    ["d2s"]="exynos9820-d2s_defconfig"
    ["d2x"]="exynos9820-d2x_defconfig"
    ["f62"]="exynos9820-f62_defconfig"
)

# Validate that the requested model exists in your device list
if [[ -z "${DEVICES[$MODEL]-}" ]]; then
    echo "Error: Unknown model '${MODEL}'."
    echo "Supported models: ${!DEVICES[*]}"
    exit 1
fi

# store the defconfig for the requested model
read KERNEL_DEFCONFIG <<< "${DEVICES[${MODEL}]}"

build_kernel(){
    # cleanup
    make "${BUILD_OPTIONS[@]}" clean && \
        make "${BUILD_OPTIONS[@]}" mrproper

    # make default configuration.
    make "${BUILD_OPTIONS[@]}" "${KERNEL_DEFCONFIG}"

    # configure the kernel
    #make "${BUILD_OPTIONS[@]}" menuconfig

    # build the kernel
    make "${BUILD_OPTIONS[@]}" Image

    # copy the built kernel to the dist directory
    cp "${SCRIPT_DIR}/out/arch/arm64/boot/Image" "${SCRIPT_DIR}/dist"
}

echo "Building kernel for ${MODEL}..." && \
    build_kernel
