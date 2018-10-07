#!/bin/bash
#
# Stock kernel for LG Electronics msm8996 devices build script by jcadduono
# -modified by stendro
#
################### BEFORE STARTING ################
#
# download a working toolchain and extract it somewhere and configure this
# file to point to the toolchain's root directory.
#
# once you've set up the config section how you like it, you can simply run
# ./build.sh [VARIANT]
#
# optional: specify "twrp" after [VARIANT] to enable TWRP config options.
##################### VARIANTS #####################
#
# H850		= International (Global)
#		LGH850   (LG G5)
#
# H830		= T-Mobile (US)
#		LGH830   (LG G5)
#
# RS988		= Unlocked (US)
#		LGRS988  (LG G5)
#
#   *************************
#
# H910		= AT&T (US)
#		LGH910   (LG V20)
#
# H915		= Canada (CA)
#		LGH915   (LG V20)
#
# H918		= T-Mobile (US)
#		LGH918   (LG V20)
#
# US996		= US Cellular & Unlocked (US)
#		LGUS996  (LG V20)
#
# US996Santa	= US Cellular & Unlocked (US)
#		LGUS996  (LG V20) (Unlocked with Engineering Bootloader)
#
# VS995		= Verizon (US)
#		LGVS995  (LG V20)
#
# H990DS/TR	= International (Global)
#		LGH990   (LG V20) (TR = Single sim)
#
# LS997		= Sprint (US)
#		LGLS997  (LG V20)
#
# F800K/L/S	= Korea (KR)
#		LGF800   (LG V20)
#
#   *************************
#
# H870		= International (Global)
#		LGH870   (LG G6)
#
# US997		= US Cellular & Unlocked (US)
#		US997    (LG G6)
#
# H872		= T-Mobile (US)
#		LGH872   (LG G6)
#
###################### CONFIG ######################

# root directory of this kernel (this script's location)
RDIR=$(pwd)

# version number
VER=$(cat "$RDIR/VERSION")

# twrp configuration
[ "$2" ] && IS_TWRP=$2
if [ "$IS_TWRP" = "twrp" ]; then
  echo "TWRP configuration selected"
fi
export CROSS_COMPILE=aarch64-linux-gnu-

# select cpu threads
CPU_THREADS=$(grep -c "processor" /proc/cpuinfo)
THREADS=$((CPU_THREADS + 1))

# directory containing cross-compiler
GCC_COMP=$HOME/linaro-7.2.1
#CCACHE symbolic link directory should contain links to the ccache executable named
# ${CROSS_COMPILE}-gcc ie ln -s /usr/bin/ccacbe $CCACHEDIR/aarch64-linux-gnu-gxc
CCACHEDIR=${HOME}/ccache
# compiler version
GCC_VER=$(${GCC_COMP}/bin/${CROSS_COMPILE}gcc --version | head -n 1 | cut -f1 -d')' | \
cut -f2 -d'(')

############## SCARY NO-TOUCHY STUFF ###############

ABORT() {
	echo "Error: $*"
	exit 1
}
export PATH=${GCC_COMP}/bin:${PATH}
export KBUILD_BUILD_USER=phoenix591
export KBUILD_BUILD_HOST=xda
export ARCH=arm64
export USE_CCACHE=1
export KBUILD_COMPILER_STRING=$GCC_VER
if [ "${USE_CCACHE}" -eq 1 ]; then
	export PATH=${CCACHEDIR}:${PATH}
fi
# selected device
[ "$1" ] && DEVICE=$1
[ "$DEVICE" ] || ABORT "No device specified"

export LOCALVERSION=${DEVICE}_${VER}-mk2000

# link device name to lg config files
if [ "$DEVICE" = "H850" ]; then
  DEVICE_DEFCONFIG=h1_global_com-perf_defconfig
elif [ "$DEVICE" = "H830" ]; then
  DEVICE_DEFCONFIG=h1_tmo_us-perf_defconfig
elif [ "$DEVICE" = "RS988" ]; then
  DEVICE_DEFCONFIG=h1_lra_us-perf_defconfig
elif [ "$DEVICE" = "H870" ]; then
  DEVICE_DEFCONFIG=lucye_global_com-perf_defconfig
elif [ "$DEVICE" = "US997" ]; then
  DEVICE_DEFCONFIG=lucye_nao_us-perf_defconfig
elif [ "$DEVICE" = "H872" ]; then
  DEVICE_DEFCONFIG=lucye_tmo_us-perf_defconfig
elif [ "$DEVICE" = "H990DS" ]; then
  DEVICE_DEFCONFIG=elsa_global_com-perf_defconfig
elif [ "$DEVICE" = "H990TR" ]; then
  DEVICE_DEFCONFIG=elsa_cno_cn-perf_defconfig
elif [ "$DEVICE" = "US996" ]; then
  DEVICE_DEFCONFIG=elsa_nao_us-perf_defconfig
elif [ "$DEVICE" = "US996Santa" ]; then
  DEVICE_DEFCONFIG=elsa_usc_us-perf_defconfig
elif [ "$DEVICE" = "LS997" ]; then
  DEVICE_DEFCONFIG=elsa_spr_us-perf_defconfig
elif [ "$DEVICE" = "VS995" ]; then
  DEVICE_DEFCONFIG=elsa_vzw-perf_defconfig
elif [ "$DEVICE" = "H918" ]; then
  DEVICE_DEFCONFIG=elsa_tmo_us-perf_defconfig
elif [ "$DEVICE" = "H910" ]; then
  DEVICE_DEFCONFIG=elsa_att_us-perf_defconfig
elif [ "$DEVICE" = "H915" ]; then
  DEVICE_DEFCONFIG=elsa_global_ca-perf_defconfig
elif [ "$DEVICE" = "F800K" ]; then
  DEVICE_DEFCONFIG=elsa_kt_kr-perf_defconfig
elif [ "$DEVICE" = "F800L" ]; then
  DEVICE_DEFCONFIG=elsa_lgu_kr-perf_defconfig
elif [ "$DEVICE" = "F800S" ]; then
  DEVICE_DEFCONFIG=elsa_skt_kr-perf_defconfig
fi

# check for stuff
[ -f "$RDIR/arch/$ARCH/configs/${DEVICE_DEFCONFIG}" ] \
	|| ABORT "$DEVICE_DEFCONFIG not found in $ARCH configs!"

[ -x "${GCC_COMP}/bin/${CROSS_COMPILE}gcc" ] \
	|| ABORT "Cross-compiler not found at: ${GCC_COMP}/bin/${CROSS_COMPILE}gcc"

[ "$GCC_VER" ] || ABORT "Couldn't get GCC version"
if [ "${USE_CCACHE}" -eq 1 ] && [ ! -L "${CCACHEDIR}/${CROSS_COMPILE}gcc" ]; then
	echo "Ccache symlink not found at ${CCACHEDIR}/${CROSS_SCOMPILE}gcc"
	read -rp  "Do you wish to continue without ccache? (y/n)" ccachefail
	case ccachefail in
		[yY] | [yY][Ee][Ss] ) continue ;;
		*) exit 1 ;;
	esac
fi

# build commands
CLEAN_BUILD() {
	echo "Cleaning build..."
	rm -rf build
}

SETUP_BUILD() {
	echo "Creating kernel config..."
	mkdir -p build
	make -C "$RDIR" O=build "$DEVICE_DEFCONFIG" \
		|| ABORT "Failed to set up build"
	if [ "$IS_TWRP" = "twrp" ]; then
	  echo "include mk2000_twrp_conf" >> build/.config
	fi
}

BUILD_KERNEL() {
	echo "Compiling..."
	while ! make -C "$RDIR" O=build -j"$THREADS"; do
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

PREPARE_NEXT() {
	echo "$DEVICE" > build/DEVICE \
		|| echo "Failed to reflect device"
	if grep -q 'KERNEL_COMPRESSION_LZ4=y' build/.config; then
	  echo lz4 > build/COMPRESSION \
		|| echo "Failed to reflect compression method"
	else
	  echo gz > build/COMPRESSION \
		|| echo "Failed to reflect compression method"
	fi
}

cd "$RDIR" || ABORT "Failed to enter $RDIR!"
echo "Building $LOCALVERSION..."
echo "Using $GCC_VER..."

CLEAN_BUILD &&
SETUP_BUILD &&
BUILD_KERNEL &&
INSTALL_MODULES &&
PREPARE_NEXT &&
echo "Finished building $LOCALVERSION -- Run ./copy_finished.sh"
cp build/arch/arm64/boot/Image.lz4-dtb ./Image-${1,,}.lz4-dtb
