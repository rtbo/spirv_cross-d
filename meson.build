
project('spirv_cross-d', ['d', 'cpp'],
    version: '0.5.0',
    default_options: 'cpp_std=c++14',
)

subdir('cpp')

spirv_cross_sources = [
    'src/spv.d',
    'src/spirv_cross/native.d',
    'src/spirv_cross/package.d',
]

spirv_cross_inc = include_directories('src')

spirv_cross_lib = library('spirv_cross_d',spirv_cross_sources,
    include_directories: spirv_cross_inc,
    link_with: spirv_cross_cpp_lib,
    install: true,
    version: meson.project_version(),
    soversion: 0,
)

spirv_cross_dep = declare_dependency(
    include_directories: spirv_cross_inc,
    link_with: spirv_cross_lib,
)

import('pkgconfig').generate(spirv_cross_lib,
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
