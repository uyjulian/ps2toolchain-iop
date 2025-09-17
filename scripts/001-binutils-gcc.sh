#!/bin/bash
# 001-binutils-gcc.sh by ps2dev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

download_src()
{
  # Checking if a specific Git reference has been passed in parameter $1
  if test -n "$1"; then
    REPO_REF="$1"
    printf 'Using specified repo reference %s\n' "$REPO_REF"
  fi

  if test ! -d "$REPO_FOLDER"; then
    git clone --depth 1 --no-checkout -b "$REPO_REF" "$REPO_URL" "$REPO_FOLDER"
  else
    git -C "$REPO_FOLDER" remote set-url origin "$REPO_URL"
  fi
  git -C "$REPO_FOLDER" fetch origin "$REPO_REF" --depth=1
}

## Read information from the configuration file.
source "$(dirname "$0")/../config/ps2toolchain-iop-config.sh"

## Download the source code.
REPO_URL="$PS2TOOLCHAIN_IOP_BINUTILS_REPO_URL"
REPO_REF="$PS2TOOLCHAIN_IOP_BINUTILS_DEFAULT_REPO_REF"
REPO_FOLDER="$(s="$REPO_URL"; s=${s##*/}; printf "%s" "${s%.*}")"

download_src

REPO_FOLDER_BINUTILS="$REPO_FOLDER"

## Download the source code.
REPO_URL="$PS2TOOLCHAIN_IOP_GCC_REPO_URL"
REPO_REF="$PS2TOOLCHAIN_IOP_GCC_DEFAULT_REPO_REF"
REPO_FOLDER="$(s="$REPO_URL"; s=${s##*/}; printf "%s" "${s%.*}")"

download_src

REPO_FOLDER_GCC="$REPO_FOLDER"

# Combine the binutils and GCC trees
mkdir -p "binutils-gcc-combined"

git -C "$REPO_FOLDER_BINUTILS" archive --format=tar FETCH_HEAD | tar -C "binutils-gcc-combined" -xBf -
git -C "$REPO_FOLDER_GCC" archive --format=tar FETCH_HEAD | tar -C "binutils-gcc-combined" -xBf -

REPO_FOLDER="binutils-gcc-combined"

cd "$REPO_FOLDER"

## Download needed libs which will be built alongside Binutils and GCC
./contrib/download_prerequisites

TARGET="mipsel-none-elf"
TARGET_ALIAS="iop"
TARG_XTRA_OPTS=""
TARGET_CFLAGS="-O2 -gdwarf-2 -gz"
OSVER=$(uname)

## If using MacOS Apple, workaround the fdopen header issue
## (Remove once a GCC version with integrated zlib 1.3.1 is used)
if [ "$(uname -s)" = "Darwin" ]; then
  TARG_XTRA_OPTS="--with-system-zlib"
fi

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Create and enter the toolchain/build directory
rm -rf "build-$TARGET"
mkdir "build-$TARGET"
cd "build-$TARGET"

## Configure the build.
CFLAGS_FOR_TARGET="$TARGET_CFLAGS" \
CXXFLAGS_FOR_TARGET="$TARGET_CFLAGS" \
../configure \
  --quiet \
  --prefix="$PS2DEV/$TARGET_ALIAS" \
  --target="$TARGET" \
  --enable-languages="c,c++" \
  --with-float=soft \
  --with-headers=no \
  --without-newlib \
  --without-cloog \
  --without-ppl \
  --disable-decimal-float \
  --disable-libada \
  --disable-libatomic \
  --disable-libffi \
  --disable-libgomp \
  --disable-libmudflap \
  --disable-libquadmath \
  --disable-libssp \
  --disable-libstdcxx-pch \
  --disable-multilib \
  --disable-shared \
  --disable-threads \
  --disable-target-libiberty \
  --disable-target-zlib \
  --disable-nls \
  --disable-tls \
  --disable-libstdcxx \
  --disable-separate-code \
  --disable-sim \
  --without-static-standard-libraries \
  --with-python=no \
  $TARG_XTRA_OPTS

## Compile and install.
make --quiet -j "$PROC_NR"
make --quiet -j "$PROC_NR" install-strip
make --quiet -j "$PROC_NR" clean

## Exit the build directory.
cd ..
