
ex_sources = [
    'source/app.d'
]

ex_deps = [ d_dep ]

ex_exe = executable('exemple', ex_sources,
    include_directories: include_directories('source'),
    dependencies: [ d_dep ],
    d_import_dirs: include_directories('views'),
)
