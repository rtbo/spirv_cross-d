cmake_minimum_required(VERSION 3.1)

set (CMAKE_CXX_STANDARD 14)

add_library(spirv_cross_cpp STATIC
    spirv_cfg.cpp
    spirv_cross.cpp
    spirv_glsl.cpp
    spirv_hlsl.cpp
    spirv_msl.cpp
    spirv_cross_util.cpp
    wrapper.cpp
)
