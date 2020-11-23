
project('spirv_cross-d', ['d', 'cpp'],
    version: '0.5.0',
    default_options: 'cpp_std=c++14',
)

cpp_sources = [
    'cpp/spirv_cfg.cpp',
    'cpp/spirv_cross_parsed_ir.cpp',
    'cpp/spirv_cross_util.cpp',
    'cpp/spirv_cross.cpp',
    'cpp/spirv_glsl.cpp',
    'cpp/spirv_parser.cpp',
    'cpp/wrapper.cpp',
]

cpp_inc = include_directories('cpp')

cpp_lib = static_library('spirvcrossd_cpp', cpp_sources,
    include_directories: 'cpp',
    install: false,
)

d_sources = [
    'src/spv.d',
    'src/spirv_cross/native.d',
    'src/spirv_cross/package.d',
]

d_inc = include_directories('src')


d_lib = library('spirv_cross_d', d_sources,
    include_directories: d_inc,
    link_whole: cpp_lib,
    install: true,
)

d_dep = declare_dependency(
    include_directories: d_inc,
    link_with: d_lib,
)

import('pkgconfig').generate(d_lib,
    name: 'spirv_cross_d',
    subdirs: 'd/spirv_cross_d',
    version: meson.project_version(),
    description: 'Khronos SPIRV-Cross bindings for D',
)

install_subdir('src/spirv_cross',
    install_dir: 'include/d/spirv_cross_d',
)
install_data('src/spv.d',
    install_dir: 'include/d/spirv_cross_d',
)

subdir('example')
