import std.stdio;

import spirv_cross;

void main()
{
    auto spirv = cast(immutable(uint)[])import("shader.vert.spv");

    auto cl = new SpvCompilerGlsl(spirv);
    scope(exit) cl.dispose();

    auto opts = cl.options;
    opts.ver = 130;
    cl.options = opts;

    writeln(cl.compile());
}
