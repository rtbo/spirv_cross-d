# spirv_cross-d

D bindings to [Khronos' SPIRV-Cross](https://github.com/KhronosGroup/SPIRV-Cross)


Automatically builds and statically links to the C++ library through a provided C wrapper.

On Windows X86 DMD, only mscoff libs are supported. (Dub flag --arch=x86_mscoff)


## Example:

```d
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
```
