cmake_minimum_required(VERSION 3.1)

set (CMAKE_CXX_STANDARD 14)

if(MSVC)
    set(CMAKE_CXX_FLAGS_RELEASE "/MT")
    set(CMAKE_CXX_FLAGS_DEBUG "/MTd")
endif()

add_library(spirv_cross_cpp STATIC
    spirv_cfg.cpp
    spirv_cross.cpp
    spirv_glsl.cpp
    spirv_hlsl.cpp
    spirv_msl.cpp
    spirv_cross_util.cpp
    wrapper.cpp
)
install(TARGETS spirv_cross_cpp DESTINATION lib)
