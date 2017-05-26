#!/bin/bash
export kernel=Werewolf
export outdir=/home/reddragon/Werewolf-Stock
export makeopts="-j$(nproc)"
export zImagePath="build/arch/arm64/boot/Image.gz-dtb"
export KBUILD_BUILD_USER=USA-RedDragon
export KBUILD_BUILD_HOST=EdgeOfCreation
export CROSS_COMPILE="ccache /android-src/deso/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-gnu-6.x/bin/aarch64-linux-gnu-"
export ARCH=arm64
export shouldclean="0"
export shouldupload="0"

export version=$(cat version)
export RDIR=$(pwd)


function build() {
    if [[ $shouldclean =~ "1" ]] ; then
        rm -rf build
    fi
    export deviceconfig="werewolf_$1_defconfig"
    export device="$1"
    mkdir -p build

    make -C ${RDIR} O=build ${makeopts} ${deviceconfig}
    make -C ${RDIR} O=build ${makeopts}

    if [ -a ${zImagePath} ] ; then
        cp ${zImagePath} zip/zImage-dtb
        cd zip
        zip -q -r ${kernel}-${device}-${version}.zip anykernel.sh  META-INF tools zImage-dtb
    else
        echo -e "\n\e[31m***** Build Failed *****\e[0m\n"
    fi

    if ! [ -d ${outdir} ] ; then
        mkdir ${outdir}
    fi

    if [ -a ${kernel}-${device}-${version}.zip ] ; then
        mv -v ${kernel}-${device}-${version}.zip ${outdir}
    fi

    cd ${RDIR}

    rm -f zip/zImage-dtb

    if [[ $shouldupload =~ "1" ]] ; then
        gdrive upload -p 0B9LNaOklMVBANU0zbDBKQlBEeTg /home/reddragon/Werewolf-Stock/${kernel}-${device}-${version}.zip
    fi
}

export devicetobuild=$1

if [[ $2 =~ "clean" ]] ; then
    shouldclean="1"
fi

if [[ $3 =~ "upload" ]] ; then
    shouldclean="1"
    shouldupload="1"
fi

if [[ $devicetobuild =~ "all" ]] ; then
    build h910   # att
    build h918   # tmo
    build vs995  # vzw
#    build us996  # usc
    build ls997  # spr
else
    build $1
fi
