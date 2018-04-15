#! /bin/bash

if ! [ -x "$(command -v cmake)" ]; then
    echo "Error. CMake is not installed" >&2
    exit 1
fi

if [ -x "$(command -v ninja)" ]; then
    GEN=Ninja
else
    GEN=Makefile
fi

BUILD_TYPE=Release

PACKAGE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/..
CPP_DIR=$PACKAGE_DIR/cpp
LIB_DIR=$PACKAGE_DIR/lib


function build_sc() {
    ARCH=$1
    if [ $ARCH = "x86" ] ; then
        FLAG=-m32
    else
        FLAG=-m64
    fi

    BUILD_DIR=${PACKAGE_DIR}/build/sc_cpp_${ARCH}_${BUILD_TYPE}
    mkdir -p $BUILD_DIR || exit 1
    cd $BUILD_DIR

    cmake -G $GEN -DCMAKE_BUILD_TYPE=$BUILD_TYPE $CPP_DIR -DCMAKE_CXX_FLAGS=$FLAG || exit 1
    cmake --build $BUILD_DIR || exit 1

    mkdir -p $LIB_DIR/posix-$ARCH
    cp *.a $LIB_DIR/posix-$ARCH
}

build_sc x86
build_sc x86_64
