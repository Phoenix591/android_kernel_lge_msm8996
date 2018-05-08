#!/bin/bash
# TWRP kernel for LG Electronics msm8996 devices build script by jcadduono

################### BEFORE STARTING ################
#
# download a working toolchain and extract it somewhere and configure this
# file to point to the toolchain's root directory.
#
# once you've set up the config section how you like it, you can simply run
# ./build.sh [VARIANT]
#
##################### VARIANTS #####################
#
# h820   = AT&T (US)
#          LGH820   (LG G5)
#
# h830   = T-Mobile (US)
#          LGH830   (LG G5)
#
# ls992  = Sprint (US)
#          LGLS992  (LG G5)
#
# us992  = US Cellular (US)
#          LGUS992  (LG G5)
#
# vs987  = Verizon (US)
#          LGVS987  (LG G5)
#
# rs987  = LTE Rural America (US)
#          LGRS987  (LG G5)
#
# rs988  = Unlocked (US)
#          LGRS988  (LG G5)
#
# h831   = Canada
#          LGH831   (LG G5)
#
# h850   = International (Global)
#          LGH850   (LG G5)
#
# h860n  = Dual Sim (China / Hong Kong)
#          LGH860N  (LG G5)
#
# f700k  = KT Corporation (Korea)
#          LGF700K  (LG G5)
#
# f700l  = LG Uplus (Korea)
#          LGF700L  (LG G5)
#
# f700s  = SK Telecom (Korea)
#          LGF700S  (LG G5)
#
#   ************************
#
# h910   = AT&T (US)
#          LGH910   (LG V20)
#
# h918   = T-Mobile (US)
#          LGH918   (LG V20)
#
# ls997  = Sprint (US)
#          LGLS997  (LG V20)
#
# us996  = US Cellular & Unlocked (US)
#          LGUS996  (LG V20)
#
# vs995  = Verizon (US)
#          LGVS995  (LG V20)
#
# h915   = Canada
#          LGH915   (LG V20)
#
# h990   = International (Global)
#          LGH990   (LG V20)
#
# h990tr = Dual Sim (China / Hong Kong)
#          LGH990TR (LG V20)
#
# f800k  = KT Corporation (Korea)
#          LGF800K  (LG V20)
#
# f800l  = LG Uplus (Korea)
#          LGF800L  (LG V20)
#
# f800s  = SK Telecom (Korea)
#          LGF800S  (LG V20)
#
###################### CONFIG ######################

# root directory of LGE msm8996 git repo (default is this script's location)
RDIR=$(pwd)

[ "$VER" ] ||
# version number
VER=$(cat "$RDIR/VERSION")

# directory containing cross-compile arm64 toolchain
TOOLCHAIN=$HOME/linaro-7.2.1
#linaro-6.4/

CPU_THREADS=$(grep -c "processor" /proc/cpuinfo)
# amount of cpu threads to use in kernel make process
THREADS=$((CPU_THREADS + 1))

############## SCARY NO-TOUCHY STUFF ###############

ABORT() {
	[ "$1" ] && echo "Error: $*"
	exit 1
}

export ARCH=arm64
export CROSS_COMPILE=$TOOLCHAIN/bin/aarch64-linux-gnu-

[ -x "${CROSS_COMPILE}gcc" ] ||
ABORT "Unable to find gcc cross-compiler at location: ${CROSS_COMPILE}gcc"

[ "$TARGET" ] || TARGET=twrp
[ "$1" ] && DEVICE=$1
[ "$DEVICE" ] || DEVICE=h918

DEFCONFIG=${TARGET}_defconfig
DEVICE_DEFCONFIG=device_lge_${DEVICE}

[ -f "$RDIR/arch/$ARCH/configs/${DEFCONFIG}" ] ||
ABORT "Config $DEFCONFIG not found in $ARCH configs!"

[ -f "$RDIR/arch/$ARCH/configs/${DEVICE_DEFCONFIG}" ] ||
ABORT "Device config $DEVICE_DEFCONFIG not found in $ARCH configs!"

KDIR="$RDIR/build/arch/$ARCH/boot"
export LOCALVERSION=$TARGET-$DEVICE-$VER
export KCFLAGS='-march=armv8.1-a+crc+crypto -mtune=cortex-a57 --param l1-cache-line-size=64 --param l1-cache-size=32 --param l2-cache-size=512 -O2 -fno-use-linker-plugin'
export KCFLAGS=$KCFLAGS' -Wno-bool-operation -Wno-format-overflow -Wno-misleading-indentation -Wno-tautological-compare -Wno-array-bounds -Wno-format-truncation -Wno-duplicate-decl-specifier -Wno-memset-elt-size'
CLEAN_BUILD() {
	echo "Cleaning build..."
	rm -rf build
}

SETUP_BUILD() {
	echo "Creating kernel config for $LOCALVERSION..."
	mkdir -p build
	make -C "$RDIR" O=build "$DEFCONFIG" \
		DEVICE_DEFCONFIG="$DEVICE_DEFCONFIG" \
		|| ABORT "Failed to set up build"
}

BUILD_KERNEL() {
	echo "Starting build for $LOCALVERSION..."
	while ! make -C "$RDIR" O=build -j"$THREADS" KCFLAGS+="$KCFLAGS"; do
		read -rp "Build failed. Retry? " do_retry
		case $do_retry in
			Y|y) continue ;;
			*) return 1 ;;
		esac
	done
}

INSTALL_MODULES() {
	grep -q 'CONFIG_MODULES=y' build/.config || return 0
	echo "Installing kernel modules to build/lib/modules..."
	make -C "$RDIR" O=build \
		INSTALL_MOD_PATH="." \
		INSTALL_MOD_STRIP=1 \
		modules_install
	rm build/lib/modules/*/build build/lib/modules/*/source
}

cd "$RDIR" || ABORT "Failed to enter $RDIR!"

CLEAN_BUILD &&
SETUP_BUILD &&
BUILD_KERNEL &&
INSTALL_MODULES &&
cp build/arch/arm64/boot/Image.lz4-dtb $RDIR/Image-$1.lz4-dtb &&
echo "Finished building $LOCALVERSION!"
