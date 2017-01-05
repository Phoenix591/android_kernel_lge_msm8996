#!/bin/bash
export kernel=Werewolf
export device=H910
export deviceconfig=cyanogenmod_h918_defconfig
export outdir=/home/reddragon/Werewolf
export makeopts="-j$(nproc)"
export zImagePath="build/arch/arm64/boot/Image.gz-dtb"
export KBUILD_BUILD_USER=USA-RedDragon
export KBUILD_BUILD_HOST=EdgeOfCreation
export CROSS_COMPILE="/home/reddragon/Downloads/aarch64-linux-gnu/bin/aarch64-linux-gnu-"
export ARCH=arm64

export version=$(cat version)
export RDIR=$(pwd)

if [[ $1 =~ "clean" ]] ; then
    rm -rf build
fi

mkdir -p build

make -C ${RDIR} O=build ${makeopts} ${deviceconfig}
make -C ${RDIR} O=build ${makeopts}

if [ -a ${zImagePath} ] ; then
    cp ${zImagePath} zip/zImage-dtb
    find -name '*.ko' -exec cp -av {} zip//modules/ \;
    cd zip
    zip -q -r ${kernel}-${device}-${version}.zip anykernel.sh  META-INF tools modules zImage-dtb
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
rm -f zip/modules/*
