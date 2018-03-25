module spirv_cross.native;

import spirv_cross;

extern(C) nothrow:

void *spv_d_gc_alloc(size_t sz) {
    import core.memory : GC;
    return GC.malloc(sz);
}

struct SpvCompiler;
struct SpvCompilerGlsl;
struct SpvCompilerMsl;
struct SpvCompilerHlsl;


enum SpvResult
{
    Success,
    CompilationError,
    Error,
    Unhandled,
}


SpvResult spv_compiler_glsl_new(in uint[] ir,
                                out SpvCompilerGlsl *compiler,
                                out string error_msg);

SpvCompiler *spv_compiler_glsl_as_base(SpvCompilerGlsl *compiler) {
    return cast(SpvCompiler*)compiler;
}


void spv_compiler_glsl_get_options(in SpvCompilerGlsl *compiler,
                                   SpvGlslCompilerOptions *options);

void spv_compiler_glsl_set_options(SpvCompilerGlsl *compiler,
                                   in SpvGlslCompilerOptions *options);

SpvResult spv_compiler_glsl_build_combined_image_samplers(SpvCompilerGlsl *compiler,
                                                          out string error_msg);


SpvResult spv_compiler_hlsl_new(in uint[] ir,
                                out SpvCompilerHlsl *compiler,
                                out string error_msg);

SpvCompiler *spv_compiler_hlsl_as_base(SpvCompilerHlsl *compiler) {
    return cast(SpvCompiler*)compiler;
}


void spv_compiler_hlsl_get_options(in SpvCompilerHlsl *compiler,
                                    SpvHlslCompilerOptions *options);
void spv_compiler_hlsl_set_options(SpvCompilerHlsl *compiler,
                                   in SpvHlslCompilerOptions *options);

void spv_compiler_hlsl_set_root_constant_layout(SpvCompilerHlsl *compiler,
                                                in SpvHlslRootConstant[] constants);

SpvResult spv_compiler_msl_new(in uint[] ir,
                               out SpvCompilerMsl *compiler,
                               out string error_msg);

SpvCompiler *spv_compiler_msl_as_base(SpvCompilerMsl *compiler) {
    return cast(SpvCompiler*)compiler;
}

void spv_compiler_msl_get_options(in SpvCompilerMsl *compiler,
                                  SpvMslCompilerOptions *options);

void spv_compiler_msl_set_options(SpvCompilerMsl *compiler,
                                  in SpvMslCompilerOptions *options);

SpvResult spv_compiler_msl_compile(SpvCompilerMsl *compiler,
                                   in SpvMslVertexAttr[] vat_overrides,
                                   in SpvMslResourceBinding[] res_overrides,
                                   out string shader,
                                   out string error_msg);


SpvCompilerGlsl *spv_compiler_as_glsl(SpvCompiler *compiler) {
    return cast(SpvCompilerGlsl*)compiler;
}
SpvCompilerHlsl *spv_compiler_as_hlsl(SpvCompiler *compiler) {
    return cast(SpvCompilerHlsl*)compiler;
}
SpvCompilerMsl *spv_compiler_as_msl(SpvCompiler *compiler) {
    return cast(SpvCompilerMsl*)compiler;
}

void spv_compiler_delete(SpvCompiler *compiler);

SpvResult spv_compiler_get_decoration(in SpvCompiler *compiler,
                                      in uint id,
                                      in SpvDecoration decoration,
                                      out uint result,
                                      out string error_msg);

SpvResult spv_compiler_set_decoration(SpvCompiler *compiler,
                                      in uint id,
                                      in SpvDecoration decoration,
                                      in uint argument,
                                      out string error_msg);

SpvResult spv_compiler_get_entry_points(in SpvCompiler *compiler,
                                        out SpvEntryPoint[] entry_points,
                                        out string error_msg);

SpvResult spv_compiler_get_cleansed_entry_point_name(in SpvCompiler *compiler,
                                                     in string original_entry_point_name,
                                                     in SpvExecutionModel execution_model,
                                                     out string compiled_entry_point_name,
                                                     out string error_msg);

SpvResult spv_compiler_get_shader_resources(in SpvCompiler *compiler,
                                            out SpvShaderResources shader_resources,
                                            out string error_msg);

SpvResult spv_compiler_get_specialization_constants(in SpvCompiler *compiler,
                                                    out SpvSpecializationConstant[] constants,
                                                    out string error_msg);

SpvResult spv_compiler_set_scalar_constant(SpvCompiler *compiler,
                                           in uint id,
                                           in ulong constant,
                                           out string error_msg);

SpvResult spv_compiler_get_type(in SpvCompiler *compiler,
                                in uint id,
                                out SpvType spirv_type,
                                out string error_msg);

SpvResult spv_compiler_get_member_name(in SpvCompiler *compiler,
                                       in uint id,
                                       in uint index,
                                       out string name,
                                       out string error_msg);

SpvResult spv_compiler_get_member_decoration(in SpvCompiler *compiler,
                                             in uint id,
                                             in uint index,
                                             in SpvDecoration decoration,
                                             out uint result,
                                             out string error_msg);

SpvResult spv_compiler_set_member_decoration(SpvCompiler *compiler,
                                             in uint id,
                                             in uint index,
                                             in SpvDecoration decoration,
                                             in uint argument,
                                             out string error_msg);

SpvResult spv_compiler_get_declared_struct_size(in SpvCompiler *compiler,
                                                in uint id,
                                                out uint result,
                                                out string error_msg);

SpvResult spv_compiler_get_declared_struct_member_size(in SpvCompiler *compiler,
                                                       in uint id,
                                                       in uint index,
                                                       out uint result,
                                                       out string error_msg);

SpvResult spv_compiler_rename_interface_variable(SpvCompiler *compiler,
                                                 in SpvResource[] resources,
                                                 in uint location,
                                                 in string name,
                                                 out string error_msg);

SpvResult spv_compiler_compile(SpvCompiler *compiler,
                               out string shader,
                               out string error_msg);
