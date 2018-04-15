

#include "spirv.hpp"
#include <cstdint>
#include <cstddef>

template<typename T>
struct SpvDArray {
    size_t length;
    T *ptr;
};

extern "C" {

struct SpvCompiler;
struct SpvCompilerGlsl;
struct SpvCompilerMsl;
struct SpvCompilerHlsl;

using SpvDString = SpvDArray<const char>;

struct SpvGcCallbacks {
    void *(*alloc)(const size_t sz);
    void (*add_root)(void *ptr);
    void (*remove_root)(void *ptr);
};

enum class SpvResult
{
    Success,
    CompilationError,
    Error,
    Unhandled,
};

struct SpvEntryPoint
{
    SpvDString name;
    spv::ExecutionModel execution_model;
    uint32_t work_group_size_x;
    uint32_t work_group_size_y;
    uint32_t work_group_size_z;
};

using SpvEntryPointDArray = SpvDArray<SpvEntryPoint>;

struct SpvResource
{
    uint32_t id;
    uint32_t type_id;
    uint32_t base_type_id;
    SpvDString name;
};

using SpvResourceDArray = SpvDArray<SpvResource>;

struct SpvShaderResources
{
    SpvResourceDArray uniform_buffers;
    SpvResourceDArray storage_buffers;
    SpvResourceDArray stage_inputs;
    SpvResourceDArray stage_outputs;
    SpvResourceDArray subpass_inputs;
    SpvResourceDArray storage_images;
    SpvResourceDArray sampled_images;
    SpvResourceDArray atomic_counters;
    SpvResourceDArray push_constant_buffers;
    SpvResourceDArray separate_images;
    SpvResourceDArray separate_samplers;
};

struct SpvSpecializationConstant
{
    uint32_t id;
    uint32_t constant_id;
};

struct SpvType
{
    spirv_cross::SPIRType::BaseType type;
    SpvDArray<uint32_t> members;
    SpvDArray<uint32_t> array;
};

enum class SpvGlslPrecision
{
    DontCare,
    LowP,
    MediumP,
    HighP,
};

struct SpvGlslCompilerOptions
{
    uint32_t version;
    bool es;
    bool force_temp;
    bool vulk_semantics;
    bool separate_shader_objs;
    bool flatten_multidim_arrays;
    bool enable_420pack;

    bool vertex_transform_clip_space;
    bool vertex_invert_y;

    SpvGlslPrecision frag_def_float_prec;
    SpvGlslPrecision frag_def_int_prec;
};

struct SpvHlslRootConstant
{
    uint32_t start;
    uint32_t end;
    uint32_t binding;
    uint32_t space;
};

struct SpvHlslCompilerOptions
{
    int32_t shader_model;
    bool vertex_transform_clip_space;
    bool vertex_invert_y;
};

struct SpvMslCompilerOptions
{
    bool vertex_transform_clip_space;
    bool vertex_invert_y;
};


SpvResult spv_compiler_glsl_new(SpvDArray<const uint32_t> ir,
                                SpvGcCallbacks gc_callbacks,
                                SpvCompilerGlsl **compiler,
                                SpvDString *error_msg);

inline SpvCompiler *spv_compiler_glsl_as_base(SpvCompilerGlsl *compiler) {
    return reinterpret_cast<SpvCompiler*>(compiler);
}


void spv_compiler_glsl_get_options(const SpvCompilerGlsl *compiler,
                                   SpvGlslCompilerOptions *options);

void spv_compiler_glsl_set_options(SpvCompilerGlsl *compiler,
                                   const SpvGlslCompilerOptions *options);

SpvResult spv_compiler_glsl_build_combined_image_samplers(SpvCompilerGlsl *compiler,
                                                          SpvDString *error_msg);


SpvResult spv_compiler_hlsl_new(SpvDArray<const uint32_t> ir,
                                SpvGcCallbacks gc_callbacks,
                                SpvCompilerHlsl **compiler,
                                SpvDString *error_msg);

inline SpvCompiler *spv_compiler_hlsl_as_base(SpvCompilerHlsl *compiler) {
    return reinterpret_cast<SpvCompiler*>(compiler);
}


void spv_compiler_hlsl_get_options(const SpvCompilerHlsl *compiler,
                                    SpvHlslCompilerOptions *options);
void spv_compiler_hlsl_set_options(SpvCompilerHlsl *compiler,
                                   const SpvHlslCompilerOptions *options);

void spv_compiler_hlsl_set_root_constant_layout(SpvCompilerHlsl *compiler,
                                                SpvDArray<const SpvHlslRootConstant> constants);

SpvResult spv_compiler_msl_new(SpvDArray<const uint32_t> ir,
                               SpvGcCallbacks gc_callbacks,
                               SpvCompilerMsl **compiler,
                               SpvDString *error_msg);

inline SpvCompiler *spv_compiler_msl_as_base(SpvCompilerMsl *compiler) {
    return reinterpret_cast<SpvCompiler*>(compiler);
}

void spv_compiler_msl_get_options(const SpvCompilerMsl *compiler,
                                  SpvMslCompilerOptions *options);

void spv_compiler_msl_set_options(SpvCompilerMsl *compiler,
                                  const SpvMslCompilerOptions *options);

SpvResult spv_compiler_msl_compile(SpvCompilerMsl *compiler,
                                   SpvDArray<const spirv_cross::MSLVertexAttr> vat_overrides,
                                   SpvDArray<const spirv_cross::MSLResourceBinding> res_overrides,
                                   SpvDString *shader,
                                   SpvDString *error_msg);


inline SpvCompilerGlsl *spv_compiler_as_glsl(SpvCompiler *compiler) {
    return reinterpret_cast<SpvCompilerGlsl*>(compiler);
}
inline SpvCompilerHlsl *spv_compiler_as_hlsl(SpvCompiler *compiler) {
    return reinterpret_cast<SpvCompilerHlsl*>(compiler);
}
inline SpvCompilerMsl *spv_compiler_as_msl(SpvCompiler *compiler) {
    return reinterpret_cast<SpvCompilerMsl*>(compiler);
}

void spv_compiler_delete(SpvCompiler *compiler);

SpvResult spv_compiler_get_decoration(const SpvCompiler *compiler,
                                      const uint32_t id,
                                      const spv::Decoration decoration,
                                      uint32_t *result,
                                      SpvDString *error_msg);

SpvResult spv_compiler_set_decoration(SpvCompiler *compiler,
                                      const uint32_t id,
                                      const spv::Decoration decoration,
                                      const uint32_t argument,
                                      SpvDString *error_msg);

SpvResult spv_compiler_get_entry_points(const SpvCompiler *compiler,
                                        SpvEntryPointDArray *entry_points,
                                        SpvDString *error_msg);

SpvResult spv_compiler_get_cleansed_entry_point_name(const SpvCompiler *compiler,
                                                     const SpvDString original_entry_point_name,
                                                     const spv::ExecutionModel execution_model,
                                                     SpvDString *compiled_entry_point_name,
                                                     SpvDString *error_msg);

SpvResult spv_compiler_get_shader_resources(const SpvCompiler *compiler,
                                            SpvShaderResources *shader_resources,
                                            SpvDString *error_msg);

SpvResult spv_compiler_get_specialization_constants(const SpvCompiler *compiler,
                                                    SpvDArray<SpvSpecializationConstant> *constants,
                                                    SpvDString *error_msg);

SpvResult spv_compiler_set_scalar_constant(SpvCompiler *compiler,
                                           const uint32_t id,
                                           const uint64_t constant,
                                           SpvDString *error_msg);

SpvResult spv_compiler_get_type(const SpvCompiler *compiler,
                                const uint32_t id,
                                SpvType *spirv_type,
                                SpvDString *error_msg);

SpvResult spv_compiler_get_member_name(const SpvCompiler *compiler,
                                       const uint32_t id,
                                       const uint32_t index,
                                       SpvDString *name,
                                       SpvDString *error_msg);

SpvResult spv_compiler_get_member_decoration(const SpvCompiler *compiler,
                                             const uint32_t id,
                                             const uint32_t index,
                                             const spv::Decoration decoration,
                                             uint32_t *result,
                                             SpvDString *error_msg);

SpvResult spv_compiler_set_member_decoration(SpvCompiler *compiler,
                                             const uint32_t id,
                                             const uint32_t index,
                                             const spv::Decoration decoration,
                                             const uint32_t argument,
                                             SpvDString *error_msg);

SpvResult spv_compiler_get_declared_struct_size(const SpvCompiler *compiler,
                                                const uint32_t id,
                                                size_t *result,
                                                SpvDString *error_msg);

SpvResult spv_compiler_get_declared_struct_member_size(const SpvCompiler *compiler,
                                                       const uint32_t id,
                                                       const uint32_t index,
                                                       size_t *result,
                                                       SpvDString *error_msg);

SpvResult spv_compiler_rename_interface_variable(SpvCompiler *compiler,
                                                 const SpvDArray<const SpvResource> resources,
                                                 const uint32_t location,
                                                 const SpvDString name,
                                                 SpvDString *error_msg);

SpvResult spv_compiler_compile(SpvCompiler *compiler,
                               SpvDString *shader,
                               SpvDString *error_msg);

}
