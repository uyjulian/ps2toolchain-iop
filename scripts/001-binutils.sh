#!/bin/bash
# binutils.sh by Julian Uy (uyjulian@gmail.com)
# Based on binutils-2.25.1.sh by SP193 (ysai187@yahoo.com)
# Based on binutils-2.14.sh by Naomi Peori (naomi@peori.ca)
# There is poor support for the "dvp" because I never worked with it
# and don't actually understand why the old changes were necessary.

BINUTILS_VERSION=2.25.1
## Download the source code.
SOURCE=http://ftpmirror.gnu.org/binutils/binutils-$BINUTILS_VERSION.tar.bz2
wget --continue $SOURCE || { exit 1; }

## Unpack the source code.
echo Decompressing Binutils $BINUTILS_VERSION. Please wait.
rm -Rf binutils-$BINUTILS_VERSION && tar xfj binutils-$BINUTILS_VERSION.tar.bz2 || { exit 1; }

## Enter the source directory and patch the source code.
cd binutils-$BINUTILS_VERSION || { exit 1; }

if [ -e ../../patches/binutils-$BINUTILS_VERSION-PS2.patch ]; then
	cat ../../patches/binutils-$BINUTILS_VERSION-PS2.patch | patch -p1 || { exit 1; }
fi

target_names=("iop")
targets=("mipsel-ps2-irx")
extra_opts=("")

OSVER=$(uname)
if [ ${OSVER:0:10} == MINGW64_NT ]; then
	TARG_XTRA_OPTS="--build=x86_64-w64-mingw32 --host=x86_64-w64-mingw32"
else
	TARG_XTRA_OPTS=""
fi

## Determine the maximum number of processes that Make can work with.
if [ ${OSVER:0:5} == MINGW ]; then
	PROC_NR=$NUMBER_OF_PROCESSORS
elif [ ${OSVER:0:6} == Darwin ]; then
	PROC_NR=$(sysctl -n hw.ncpu)
else
	PROC_NR=$(nproc)
fi

echo "Building with $PROC_NR jobs"

## For each target...
for ((i=0; i<${#target_names[@]}; i++)); do
	TARG_NAME=${target_names[i]}
	TARGET=${targets[i]}
	TARG_XTRA_OPTS=${extra_opts[i]}

	## Create and enter the build directory.
	mkdir build-$TARG_NAME && cd build-$TARG_NAME || { exit 1; }

	## Configure the build.
	../configure --quiet --disable-build-warnings --prefix="$PS2DEV/$TARG_NAME" --target="$TARGET" $TARG_XTRA_OPTS || { exit 1; }

	## Compile and install.
	make --quiet clean && make --quiet -j $PROC_NR CFLAGS="$CFLAGS -O2" LDFLAGS="$LDFLAGS -s" && make --quiet install && make --quiet clean || { exit 1; }

	## Exit the build directory.
	cd .. || { exit 1; }

	## End target.
done
