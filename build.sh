#!/bin/bash
##
#  Copyright (C) 2015, Samsung Electronics, Co., Ltd.
#  Written by System S/W Group, S/W Platform R&D Team,
#  Mobile Communication Division.
#
#  Edited by Gabriel 
##

set -e -o pipefail

PLATFORM=sc8830
DEFCONFIG=j1mini3g_defconfig
OC_DEFCONFIG=j1mini3g-OC_defconfig
NAME=LightKernel
VERSION=LightKernel-v6
OC_VERSION=LightKernel-v6-OC

if [ -d $(pwd)/out ]; then
 rm -rf $(pwd)/out;
fi;

if [ -f $(pwd)/kernel_zip/tools/Image ]; then
 rm -f $(pwd)/kernel_zip/tools/Image;
fi;

if [ -f $(pwd)/kernel_zip/tools/dt.img ]; then
 rm -f $(pwd)/kernel_zip/tools/dt.img;
fi;

export KBUILD_BUILD_USER=Gabriel
export KBUILD_BUILD_HOST=Ubuntu
export ARCH=arm
export CROSS_COMPILE=$(pwd)/toolchain/bin/arm-eabi-

KERNEL_PATH=$(pwd)
KERNEL_ZIP=${KERNEL_PATH}/kernel_zip
KERNEL_IMAGE=${KERNEL_ZIP}/tools/Image
DT_IMG=${KERNEL_ZIP}/tools/dt.img
EXTERNAL_MODULE_PATH=${KERNEL_PATH}/external_module
OUTPUT_PATH=${KERNEL_PATH}/out

JOBS=$(nproc --all)

# Colors
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

function build() {
	clear;
	export LOCALVERSION=-${VERSION}
	KERNEL_ZIP_NAME=${VERSION}_kernel_$(date +%F).zip
	BUILD_START=$(date +"%s");
	echo -e "$cyan"
	echo "***********************************************";
	echo "              Compiling LightKernel             ";
	echo -e "***********************************************$nocol";
	echo -e "$red";

	if [ ! -e ${OUTPUT_PATH} ]; then
		mkdir ${OUTPUT_PATH};
	fi;

	echo -e "Initializing defconfig...$nocol";
	make O=out ${DEFCONFIG};
	echo -e "$red";
	echo -e "Building kernel...$nocol";
	if [ -d "out/arch/arm/boot/dts" ]; then
		rm out/arch/arm/boot/dts/*;
	fi;
	make O=out -j${JOBS};
	make O=out -j${JOBS} dtbs;
	./scripts/mkdtimg.sh -i ${KERNEL_PATH}/arch/arm/boot/dts/ -o dt.img;
	find ${KERNEL_PATH} -name "Image" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	find ${KERNEL_PATH} -name "dt.img" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	cp out/drivers/net/wireless/sc2331/sprdwl.ko ${KERNEL_ZIP}/tools;
	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo -e "$yellow";
	echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
}


function oc_build() {
	clear;
	export LOCALVERSION=-${OC_VERSION}
	KERNEL_ZIP_NAME=${OC_VERSION}_kernel_$(date +%F).zip
	BUILD_START=$(date +"%s");
	echo -e "$cyan"
	echo "***********************************************";
	echo "              Compiling LightKernel (OC)          	     ";
	echo -e "***********************************************$nocol";
	echo -e "$red";

	if [ ! -e ${OUTPUT_PATH} ]; then
		mkdir ${OUTPUT_PATH};
	fi;

	echo -e "Initializing defconfig...$nocol";
	make O=out ${OC_DEFCONFIG};
	echo -e "$red";
	echo -e "Building kernel...$nocol";
	if [ -d "out/arch/arm/boot/dts" ]; then
		rm out/arch/arm/boot/dts/*;
	fi;
	make O=out -j${JOBS};
	make O=out -j${JOBS} dtbs;
	./scripts/mkdtimg.sh -i ${KERNEL_PATH}/arch/arm/boot/dts/ -o dt.img;
	find ${KERNEL_PATH} -name "Image" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	find ${KERNEL_PATH} -name "dt.img" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	cp out/drivers/net/wireless/sc2331/sprdwl.ko ${KERNEL_ZIP}/tools;
	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo -e "$yellow";
	echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
}


function make_zip() {
	echo -e "$red";
	echo -e "Making flashable zip...$nocol";

	cd ${KERNEL_PATH}/kernel_zip;
	zip -r ${KERNEL_ZIP_NAME} ./;
	mv ${KERNEL_ZIP_NAME} ${KERNEL_PATH};
}

function rm_if_exist() {
	if [ -e $1 ]; then
		rm -rf $1;
	fi;
}

function clean() {
	echo -e "$red";
	echo -e "Cleaning build environment...$nocol";
	make -j${JOBS} mrproper;

	rm_if_exist ${KERNEL_ZIP_NAME};
	rm_if_exist ${OUTPUT_PATH};
	rm_if_exist ${DT_IMG};

	echo -e "$yellow";
	echo -e "Done!$nocol";
}

oc_build
make_zip
