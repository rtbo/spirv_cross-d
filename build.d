/+ dub.sdl:
    dependency "dbuild" version="*"
+/

import dbuild;
import std.file;
import std.path;

void main()
{
    auto spvcDir = __FILE_FULL_PATH__.dirName();
    auto src = localSource(buildPath(spvcDir, "cpp"));
    auto cmake = CMake.create().buildSystem();
    auto bld = Build
        .dubWorkDir()
        .src(src)
        .release()
        .target(libTarget("spirv_cross_cpp"))
        .build(cmake);
    const flagFilename = buildPath(spvcDir, "linker_flags.txt");
    write(flagFilename, bld.artifact("spirv_cross_cpp")~"\n");
}
