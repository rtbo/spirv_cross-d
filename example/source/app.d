import std.stdio;

import spirv_cross;
import spirv_cross.native;

void main()
{
    auto spirv = cast(immutable(uint)[])import("shader.vert.spv");

    string error_msg;

    SpvCompilerGlsl *cl;
    spv_compiler_glsl_new(spirv, cl, error_msg);

    SpvGlslCompilerOptions opts;
    spv_compiler_glsl_get_options(cl, &opts);
    opts.ver = 130;
    spv_compiler_glsl_set_options(cl, &opts);

    string str;
    spv_compiler_compile(spv_compiler_glsl_as_base(cl), str, error_msg);

    writeln(str);
}
