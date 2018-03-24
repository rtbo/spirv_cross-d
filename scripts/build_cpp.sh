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
BUILD_DIR=$PACKAGE_DIR/.dub/build/sc_cpp_$BUILD_TYPE

mkdir -p $BUILD_DIR
cd $BUILD_DIR

cmake -G $GEN -DCMAKE_BUILD_TYPE=$BUILD_TYPE $CPP_DIR
cmake --build $BUILD_DIR

cp $BUILD_DIR/libspirv_cross_cpp.a $PACKAGE_DIR
