
spirv_cross_cpp_sources = [
    'spirv_cfg.cpp',
    'spirv_cross_parsed_ir.cpp',
    'spirv_cross_util.cpp',
    'spirv_cross.cpp',
    'spirv_glsl.cpp',
    'spirv_parser.cpp',
    'wrapper.cpp',
]

spirv_cross_cpp_inc = include_directories('.')

spirv_cross_cpp_lib = static_library('spirvcrossd_cpp', spirv_cross_cpp_sources,
    include_directories: spirv_cross_cpp_inc,
    install: false,
)
