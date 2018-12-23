

#include "spirv.hpp"
#include "spirv_cross.hpp"
#include <cstddef>
#include <cstdint>

using std::size_t;
using std::uint32_t;

// ABI compliant representation of D array
template <typename T> struct ScDArray
{
    size_t length;
    T *ptr;
};

// D string alias
using ScDString = ScDArray<const char>;

extern "C" {

// forward decl.
struct ScCompiler;
struct ScCompilerGlsl;

// return type to indicate if a C++ exception was thrown
enum class ScResult
{
    Success,
    CompilationError,
    Error,
    Unhandled,
};

// callbacks to allocate memory by the D runtime
struct ScGcCallbacks
{
    void *(*alloc)(const std::size_t len);
};

// generic compiler types

struct SPIRType;

struct Resource
{
    uint32_t id;
    uint32_t type_id;
    uint32_t base_type_id;
    ScDString name;
};

struct ShaderResources
{
    ScDArray<Resource> uniform_buffers;
    ScDArray<Resource> storage_buffers;
    ScDArray<Resource> stage_inputs;
    ScDArray<Resource> stage_outputs;
    ScDArray<Resource> subpass_inputs;
    ScDArray<Resource> storage_images;
    ScDArray<Resource> sampled_images;
    ScDArray<Resource> atomic_counters;
    ScDArray<Resource> push_constant_buffers;
    ScDArray<Resource> separate_images;
    ScDArray<Resource> separate_samplers;
};

struct EntryPoint
{
    ScDString name;
    spv::ExecutionModel execution_model;
};

// generic compiler functions

void sc_compiler_delete(ScCompiler *compiler);

ScDString sc_compiler_get_error_string(const ScCompiler *compiler);

ScResult sc_compiler_compile(ScCompiler *compiler, ScDString *result);

ScResult sc_compiler_get_name(const ScCompiler *compiler, uint32_t id,
                              ScDString *result);

ScResult sc_compiler_set_decoration(ScCompiler *compiler, uint32_t id,
                                    spv::Decoration decoration,
                                    uint32_t argument);

ScResult sc_compiler_set_decoration_string(ScCompiler *compiler, uint32_t id,
                                           spv::Decoration dec,
                                           ScDString string);

ScResult sc_compiler_set_name(ScCompiler *compiler, uint32_t id,
                              ScDString string);

// get_decoration_bitset

ScResult sc_compiler_has_decoration(const ScCompiler *compiler, uint32_t id,
                                    spv::Decoration decoration, bool *result);

ScResult sc_compiler_get_decoration(const ScCompiler *compiler, uint32_t id,
                                    spv::Decoration decoration,
                                    uint32_t *result);

ScResult sc_compiler_get_decoration_string(const ScCompiler *compiler,
                                           uint32_t id,
                                           spv::Decoration decoration,
                                           ScDString *result);

ScResult sc_compiler_unset_decoration(ScCompiler *compiler, uint32_t id,
                                      spv::Decoration decoration);

ScResult sc_compiler_get_type(const ScCompiler *compiler, uint32_t id,
                              const SPIRType **result);

ScResult sc_compiler_get_type_from_variable(const ScCompiler *compiler,
                                            uint32_t id,
                                            const SPIRType **result);

ScResult sc_compiler_get_non_pointer_type_id(const ScCompiler *compiler,
                                             uint32_t type_id,
                                             uint32_t *result);

ScResult sc_compiler_get_non_pointer_type(const ScCompiler *compiler,
                                          uint32_t id, const SPIRType **result);

// is_sampled_image type to be implemented in D

ScResult sc_compiler_get_storage_class(const ScCompiler *compiler, uint32_t id,
                                       spv::StorageClass *result);

ScResult sc_compiler_get_fallback_name(const ScCompiler *compiler, uint32_t id,
                                       ScDString *result);

ScResult sc_compiler_get_block_fallback_name(const ScCompiler *compiler,
                                             uint32_t id, ScDString *result);

ScResult sc_compiler_get_member_name(const ScCompiler *compiler, uint32_t id,
                                     uint32_t index, ScDString *result);

ScResult sc_compiler_get_member_decoration(const ScCompiler *compiler,
                                           uint32_t id, uint32_t index,
                                           spv::Decoration decoration,
                                           uint32_t *result);

ScResult sc_compiler_get_member_decoration_string(const ScCompiler *compiler,
                                                  uint32_t id, uint32_t index,
                                                  spv::Decoration decoration,
                                                  ScDString *result);

ScResult sc_compiler_set_member_name(ScCompiler *compiler, uint32_t id,
                                     uint32_t index, ScDString name);

ScResult sc_compiler_get_member_qualified_name(const ScCompiler *compiler,
                                               uint32_t id, uint32_t index,
                                               ScDString *result);

ScResult sc_compiler_set_member_qualified_name(ScCompiler *compiler,
                                               uint32_t id, uint32_t index,
                                               ScDString name);

// get_member_decoration_bitset

ScResult sc_compiler_has_member_decoration(const ScCompiler *compiler,
                                           uint32_t id, uint32_t index,
                                           spv::Decoration decoration,
                                           bool *result);

ScResult sc_compiler_set_member_decoration(ScCompiler *compiler, uint32_t id,
                                           uint32_t index,
                                           spv::Decoration decoration,
                                           uint32_t arg);

ScResult sc_compiler_set_member_decoration_string(ScCompiler *compiler,
                                                  uint32_t id, uint32_t index,
                                                  spv::Decoration decoration,
                                                  ScDString arg);

ScResult sc_compiler_unset_member_decoration(ScCompiler *compiler, uint32_t id,
                                             uint32_t index,
                                             spv::Decoration decoration);

// get_fallback_member_name in D

ScResult sc_compiler_get_active_buffer_ranges(
    const ScCompiler *compiler, uint32_t id,
    ScDArray<spirv_cross::BufferRange> *result);

ScResult sc_compiler_get_declared_struct_size(const ScCompiler *compiler,
                                              const SPIRType *type,
                                              size_t *result);

ScResult sc_compiler_get_declared_struct_size_runtime_array(
    const ScCompiler *compiler, const SPIRType *type, size_t array_size,
    size_t *result);

ScResult sc_compiler_get_declared_struct_member_size(const ScCompiler *compiler,
                                                     const SPIRType *type,
                                                     uint32_t index,
                                                     size_t *result);

ScResult sc_compiler_get_active_interface_variables(const ScCompiler *compiler,
                                                    ScDArray<uint32_t> *result);

ScResult sc_compiler_set_enabled_interface_variables(
    ScCompiler *compiler, ScDArray<uint32_t> active_variables);

ScResult sc_compiler_get_shader_resources(const ScCompiler *compiler,
                                          ShaderResources *result);

ScResult
sc_compiler_get_shader_resources_for_vars(const ScCompiler *compiler,
                                          ScDArray<uint32_t> active_variables,
                                          ShaderResources *result);

ScResult sc_compiler_set_remapped_variable_state(ScCompiler *compiler,
                                                 uint32_t id,
                                                 bool remap_enable);

ScResult sc_compiler_get_remapped_variable_state(const ScCompiler *compiler,
                                                 uint32_t id, bool *result);

ScResult sc_compiler_set_subpass_input_remapped_components(ScCompiler *compiler,
                                                           uint32_t id,
                                                           uint32_t components);

ScResult sc_compiler_get_subpass_input_remapped_components(
    const ScCompiler *compiler, uint32_t id, uint32_t *result);

ScResult sc_compiler_get_entry_points_and_stages(const ScCompiler *compiler,
                                                 ScDArray<EntryPoint> *result);

ScResult sc_compiler_set_entry_point(ScCompiler *compiler, ScDString entry,
                                     spv::ExecutionModel excution_model);

ScResult sc_compiler_rename_entry_point(ScCompiler *compiler,
                                        ScDString old_name, ScDString new_name, spv::ExecutionModel execution_model);

// get_entry_point?

ScResult sc_compiler_get_cleansed_entry_point_name(
    const ScCompiler *compiler, ScDString name,
    spv::ExecutionModel execution_model, ScDString *result);

// execution_mod_bitset

ScResult sc_compiler_unset_execution_mode(ScCompiler *compiler,
                                          spv::ExecutionMode mode);

ScResult sc_compiler_set_execution_mode(ScCompiler *compiler,
                                        spv::ExecutionMode execution_mode,
                                        uint32_t arg0, uint32_t arg1,
                                        uint32_t arg2);

ScResult
sc_compiler_get_execution_mode_argument(const ScCompiler *compiler,
                                        spv::ExecutionMode execution_mode,
                                        uint32_t index, uint32_t *result);

ScResult sc_compiler_get_execution_model(const ScCompiler *compiler,
                                         spv::ExecutionModel *result);

ScResult sc_compiler_get_work_group_size_specialization_constants(
    const ScCompiler *compiler, spirv_cross::SpecializationConstant *x,
    spirv_cross::SpecializationConstant *y,
    spirv_cross::SpecializationConstant *z, uint32_t *result);

ScResult
sc_compiler_build_dummy_sampler_for_combined_images(ScCompiler *compiler,
                                                    uint32_t *result);

ScResult sc_compiler_build_combined_image_samples(ScCompiler *compiler);

ScResult sc_compiler_get_combined_image_samplers(
    const ScCompiler *compiler,
    ScDArray<spirv_cross::CombinedImageSampler> *result);

// remap_callback

ScResult sc_compiler_get_specialization_constants(
    const ScCompiler *compiler,
    ScDArray<spirv_cross::SpecializationConstant> *result);

// get_constant

ScResult sc_compiler_get_current_id_bound(const ScCompiler *compiler,
                                          uint32_t *result);

ScResult sc_compiler_type_struct_member_offset(const ScCompiler *compiler,
                                               const SPIRType *type,
                                               uint32_t index,
                                               uint32_t *result);
ScResult sc_compiler_type_struct_member_array_stride(const ScCompiler *compiler,
                                                     const SPIRType *type,
                                                     uint32_t index,
                                                     uint32_t *result);
ScResult
sc_compiler_type_struct_member_matrix_stride(const ScCompiler *compiler,
                                             const SPIRType *type,
                                             uint32_t index, uint32_t *result);

ScResult sc_compiler_get_binary_offset_for_decoration(
    const ScCompiler *compiler, uint32_t id, spv::Decoration decoration,
    uint32_t *word_offset, bool *result);

ScResult sc_compiler_buffer_is_hlsl_counter_buffer(const ScCompiler *compiler,
                                                   uint32_t id, bool *result);

ScResult sc_compiler_buffer_get_hlsl_counter_buffer(const ScCompiler *compiler,
                                                    uint32_t id,
                                                    uint32_t *counter_id,
                                                    bool *result);

ScResult
sc_compiler_get_declared_capabilities(const ScCompiler *compiler,
                                      ScDArray<spv::Capability> *result);

ScResult sc_compiler_get_declared_extensions(const ScCompiler *compiler,
                                             ScDArray<ScDString> *result);

ScResult
sc_compiler_get_remapped_declared_block_name(const ScCompiler *compiler,
                                             uint32_t id, ScDString *result);

// buffer_block_flags

// GLSL compiler types

struct ScOptionsGlsl
{
    uint32_t version = 450;
    bool es = false;
    bool force_temporary = false;
    bool vulkan_semantics = false;
    bool separate_shader_objects = false;
    bool flatten_multidimensional_arrays = false;
    enum Precision
    {
        DontCare,
        Lowp,
        Mediump,
        Highp
    };

    struct
    {
        bool fixup_clipspace = false;
        bool flip_vert_y = false;
        bool support_nonzero_base_instance = true;
    } vertex;

    struct
    {
        Precision default_float_precision = Mediump;
        Precision default_int_precision = Highp;
    } fragment;
};

// GLSL compiler funcs

ScResult sc_compiler_glsl_new(ScDArray<const uint32_t> ir, ScGcCallbacks gc_callbacks,
                              ScCompilerGlsl **result, ScDString *error);

ScResult sc_compiler_glsl_get_options(const ScCompilerGlsl *compiler,
                                      ScOptionsGlsl *result);

ScResult sc_compiler_glsl_set_options(ScCompilerGlsl *compiler,
                                      const ScOptionsGlsl *options);

ScResult sc_compiler_glsl_get_partial_source(ScCompilerGlsl *compiler,
                                             ScDString *result);

ScResult sc_compiler_glsl_add_header_line(ScCompilerGlsl *compiler,
                                          ScDString str);

ScResult sc_compiler_glsl_require_extension(ScCompilerGlsl *compiler,
                                            ScDString ext);

ScResult sc_compiler_glsl_flatten_buffer_block(ScCompilerGlsl *compiler,
                                               uint32_t id);
} // extern "C"
