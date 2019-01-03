module spirv_cross.native;

package:

import spirv_cross;
static import spv;

extern (C) nothrow:

void* sc_d_gc_alloc(in size_t sz)
{
    import core.memory : GC;

    return GC.malloc(sz);
}

struct ScCompiler;
struct ScCompilerGlsl;

struct ScGcCallbacks
{
    extern (C) nothrow void* function(in size_t sz) alloc;
}

extern (D) @property auto gcCallbacks()
{
    return ScGcCallbacks(&sc_d_gc_alloc);
}

enum ScResult
{
    success,
    compilationError,
    error,
    unhandled,
}

extern (D) ScCompilerGlsl* sc_compiler_as_glsl(ScCompiler* compiler)
{
    return cast(ScCompilerGlsl*) compiler;
}

extern (D) ScCompiler* sc_compiler_glsl_as_base(ScCompilerGlsl* compiler)
{
    return cast(ScCompiler*) compiler;
}

// generic compiler functions

void sc_compiler_delete(ScCompiler* compiler);

string sc_compiler_get_error_string(const(ScCompiler)* compiler);

ScResult sc_compiler_compile(ScCompiler* compiler, out string result);

ScResult sc_compiler_get_name(const(ScCompiler)* compiler, uint id, out string result);

ScResult sc_compiler_set_decoration(ScCompiler* compiler, uint id,
        spv.Decoration decoration, uint argument);

ScResult sc_compiler_set_decoration_string(ScCompiler* compiler, uint id,
        spv.Decoration dec, string str);

ScResult sc_compiler_set_name(ScCompiler* compiler, uint id, string str);

// get_decoration_bitset

ScResult sc_compiler_has_decoration(const(ScCompiler)* compiler, uint id,
        spv.Decoration decoration, out bool result);

ScResult sc_compiler_get_decoration(const(ScCompiler)* compiler, uint id,
        spv.Decoration decoration, out uint result);

ScResult sc_compiler_get_decoration_string(const(ScCompiler)* compiler, uint id,
        spv.Decoration decoration, out string result);

ScResult sc_compiler_unset_decoration(ScCompiler* compiler, uint id, spv.Decoration decoration);

ScResult sc_compiler_get_type(const(ScCompiler)* compiler, uint id, out const(SPIRType)* result);

ScResult sc_compiler_get_type_from_variable(const(ScCompiler)* compiler,
        uint id, out const(SPIRType)* result);

ScResult sc_compiler_get_non_pointer_type_id(const(ScCompiler)* compiler,
        uint type_id, out uint result);

ScResult sc_compiler_get_non_pointer_type(const(ScCompiler)* compiler, uint id,
        out const(SPIRType)* result);

// is_sampled_image type to be implemented in D

ScResult sc_compiler_get_storage_class(const(ScCompiler)* compiler, uint id,
        out spv.StorageClass result);

ScResult sc_compiler_get_fallback_name(const(ScCompiler)* compiler, uint id, out string result);

ScResult sc_compiler_get_block_fallback_name(const(ScCompiler)* compiler, uint id, out string result);

ScResult sc_compiler_get_member_name(const(ScCompiler)* compiler, uint id,
        uint index, out string result);

ScResult sc_compiler_get_member_decoration(const(ScCompiler)* compiler, uint id,
        uint index, spv.Decoration decoration, out uint result);

ScResult sc_compiler_get_member_decoration_string(const(ScCompiler)* compiler,
        uint id, uint index, spv.Decoration decoration, out string result);

ScResult sc_compiler_set_member_name(ScCompiler* compiler, uint id, uint index, const string name);

ScResult sc_compiler_get_member_qualified_name(const(ScCompiler)* compiler,
        uint id, uint index, out string result);

ScResult sc_compiler_set_member_qualified_name(ScCompiler* compiler, uint id,
        uint index, string name);

// get_member_decoration_bitset

ScResult sc_compiler_has_member_decoration(const(ScCompiler)* compiler, uint id,
        uint index, spv.Decoration decoration, out bool result);

ScResult sc_compiler_set_member_decoration(ScCompiler* compiler, uint id,
        uint index, spv.Decoration decoration, uint arg);

ScResult sc_compiler_set_member_decoration_string(ScCompiler* compiler, uint id,
        uint index, spv.Decoration decoration, string arg);

ScResult sc_compiler_unset_member_decoration(ScCompiler* compiler, uint id,
        uint index, spv.Decoration decoration);

// get_fallback_member_name in D

ScResult sc_compiler_get_active_buffer_ranges(const(ScCompiler)* compiler,
        uint id, out BufferRange[] result);

ScResult sc_compiler_get_declared_struct_size(const(ScCompiler)* compiler,
        const(SPIRType)* type, out size_t result);

ScResult sc_compiler_get_declared_struct_size_runtime_array(const(ScCompiler)* compiler,
        const(SPIRType)* type, size_t array_size, out size_t result);

ScResult sc_compiler_get_declared_struct_member_size(const(ScCompiler)* compiler,
        const(SPIRType)* type, uint index, out size_t result);

ScResult sc_compiler_get_active_interface_variables(const(ScCompiler)* compiler, out uint[] result);

ScResult sc_compiler_set_enabled_interface_variables(ScCompiler* compiler,
        const(uint)[] active_variables);

ScResult sc_compiler_get_shader_resources(const(ScCompiler)* compiler, out ShaderResources result);

ScResult sc_compiler_get_shader_resources_for_vars(const(ScCompiler)* compiler,
        const(uint)[] active_variables, out ShaderResources result);

ScResult sc_compiler_set_remapped_variable_state(ScCompiler* compiler, uint id, bool remap_enable);

ScResult sc_compiler_get_remapped_variable_state(const(ScCompiler)* compiler, uint id,
        out bool result);

ScResult sc_compiler_set_subpass_input_remapped_components(ScCompiler* compiler,
        uint id, uint components);

ScResult sc_compiler_get_subpass_input_remapped_components(
        const(ScCompiler)* compiler, uint id, out uint result);

ScResult sc_compiler_get_entry_points_and_stages(const(ScCompiler)* compiler, out EntryPoint[] result);

ScResult sc_compiler_set_entry_point(ScCompiler* compiler, string entry,
        spv.ExecutionModel excution_model);

ScResult sc_compiler_rename_entry_point(ScCompiler* compiler, string old_name,
        string new_name, spv.ExecutionModel execution_model);

// get_entry_point?

ScResult sc_compiler_get_cleansed_entry_point_name(const(ScCompiler)* compiler,
        string name, spv.ExecutionModel execution_model, out string result);

// execution_mod_bitset

ScResult sc_compiler_unset_execution_mode(ScCompiler* compiler, spv.ExecutionMode mode);

ScResult sc_compiler_set_execution_mode(ScCompiler* compiler,
        spv.ExecutionMode execution_mode, uint arg0, uint arg1, uint arg2);

ScResult sc_compiler_get_execution_mode_argument(const(ScCompiler)* compiler,
        spv.ExecutionMode execution_mode, uint index, out uint result);

ScResult sc_compiler_get_execution_model(const(ScCompiler)* compiler, out spv.ExecutionModel result);

ScResult sc_compiler_get_work_group_size_specialization_constants(const(ScCompiler)* compiler,
        out SpecializationConstant x, out SpecializationConstant y,
        out SpecializationConstant z, out uint result);

ScResult sc_compiler_build_dummy_sampler_for_combined_images(ScCompiler* compiler, out uint result);

ScResult sc_compiler_build_combined_image_samples(ScCompiler* compiler);

ScResult sc_compiler_get_combined_image_samplers(const(ScCompiler)* compiler,
        out CombinedImageSampler[] result);

// remap_callback

ScResult sc_compiler_get_specialization_constants(const(ScCompiler)* compiler,
        out SpecializationConstant[] result);

// get_constant

ScResult sc_compiler_get_current_id_bound(const(ScCompiler)* compiler, out uint result);

ScResult sc_compiler_type_struct_member_offset(const(ScCompiler)* compiler,
        const(SPIRType)* type, uint index, out uint result);

ScResult sc_compiler_type_struct_member_array_stride(const(ScCompiler)* compiler,
        const(SPIRType)* type, uint index, out uint result);

ScResult sc_compiler_type_struct_member_matrix_stride(const(ScCompiler)* compiler,
        const(SPIRType)* type, uint index, out uint result);

ScResult sc_compiler_get_binary_offset_for_decoration(const(ScCompiler)* compiler,
        uint id, spv.Decoration decoration, out uint word_offset, out bool result);

ScResult sc_compiler_buffer_is_hlsl_counter_buffer(const(ScCompiler)* compiler,
        uint id, out bool result);

ScResult sc_compiler_buffer_get_hlsl_counter_buffer(const(ScCompiler)* compiler,
        uint id, out uint counter_id, out bool result);

ScResult sc_compiler_get_declared_capabilities(const(ScCompiler)* compiler,
        out spv.Capability[] result);

ScResult sc_compiler_get_declared_extensions(const(ScCompiler)* compiler, out string[] result);

ScResult sc_compiler_get_remapped_declared_block_name(const(ScCompiler)* compiler,
        uint id, out string result);

// buffer_block_flags

// GLSL compiler funcs

ScResult sc_compiler_glsl_new(const(uint)[] ir, ScGcCallbacks gc_callbacks,
        out ScCompilerGlsl* result, out string error);

ScResult sc_compiler_glsl_get_options(const(ScCompilerGlsl)* compiler, out ScOptionsGlsl result);

ScResult sc_compiler_glsl_set_options(ScCompilerGlsl* compiler, const(ScOptionsGlsl)* options);

ScResult sc_compiler_glsl_get_partial_source(ScCompilerGlsl* compiler, out string result);

ScResult sc_compiler_glsl_add_header_line(ScCompilerGlsl* compiler, string str);

ScResult sc_compiler_glsl_require_extension(ScCompilerGlsl* compiler, string ext);

ScResult sc_compiler_glsl_flatten_buffer_block(ScCompilerGlsl* compiler, uint id);
