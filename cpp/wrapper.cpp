#pragma warning(disable : 4996 4101)
#include "wrapper.hpp"
#include "spirv_glsl.hpp"

#include <cstring>
#include <memory>
#include <string>

static_assert(sizeof(bool) == 1,
              "Config script needed to determine size of bool");

struct ScCommon
{
    ScGcCallbacks gc_callbacks;
    mutable std::string error_string;

    void *gc_alloc(const size_t sz) const
    {
        return (*gc_callbacks.alloc)(sz);
    }
};

struct ScCompiler
{
    const spirv_cross::Compiler *cl() const
    {
        return &this->_cl;
    }
    spirv_cross::Compiler *cl()
    {
        return &this->_cl;
    }

    const ScCommon &common() const
    {
        return _common;
    }
    ScCommon &common()
    {
        return _common;
    }

  private:
    ScCommon _common;
    spirv_cross::Compiler _cl;
};

struct ScCompilerGlsl
{
    ScCompilerGlsl(ScCommon common, ScDArray<const uint32_t> ir)
        : _common{common}, _cl{ir.ptr, ir.length}
    {}

    const spirv_cross::CompilerGLSL *cl() const
    {
        return &this->_cl;
    }
    spirv_cross::CompilerGLSL *cl()
    {
        return &this->_cl;
    }

    const ScCommon &common() const
    {
        return _common;
    }
    ScCommon &common()
    {
        return _common;
    }

  private:
    ScCommon _common;
    spirv_cross::CompilerGLSL _cl;
};

inline ScDString to_d_string(const ScCommon &common, const std::string &s)
{
    const auto size = s.size();
    auto *mem = static_cast<char *>(common.gc_alloc(size));
    s.copy(mem, size, 0);
    return ScDString{size, mem};
}

inline ScDString to_d_string(const ScCommon &common, const char *s)
{
    const auto size = std::strlen(s);
    auto *mem = static_cast<char *>(common.gc_alloc(size));
    std::memcpy(mem, s, size);
    return ScDString{size, mem};
}

inline ScDString to_d_string(const ScCompiler *cl, const std::string &s)
{
    return to_d_string(cl->common(), s);
}

inline ScDString to_d_string(const ScCompiler *cl, const char *s)
{
    return to_d_string(cl->common(), s);
}

inline std::string to_cpp_string(ScDString ds)
{
    return std::string{ds.ptr, ds.length};
}

template <typename T>
inline ScDArray<T> to_d_array(const ScCommon &common, const std::vector<T> &vec)
{
    const auto sz = vec.size();
    auto *mem = static_cast<T *>(common.gc_alloc(sz * sizeof(T)));
    std::memcpy(mem, vec.data(), sz * sizeof(T));
    return ScDArray<T>{sz, mem};
}

template <typename T>
inline ScDArray<T> to_d_array(const ScCompiler *cl, const std::vector<T> &vec)
{
    return to_d_array(cl->common(), vec);
}

template <typename T> inline std::vector<T> to_vector(ScDArray<T> darr)
{
    std::vector<T> vec;
    vec.reserve(darr.length);
    for (size_t i = 0; i < darr.length; ++i)
        vec.push_back(darr.ptr[i]);
}

inline const SPIRType *type_conv(const spirv_cross::SPIRType &type)
{
    return reinterpret_cast<const SPIRType *>(&type);
}

inline const spirv_cross::SPIRType &type_conv(const SPIRType *type)
{
    return *reinterpret_cast<const spirv_cross::SPIRType *>(type);
}

template <typename F>
inline ScResult sc_handle(const ScCommon &common, F lambda)
{
    try {
        lambda();
    }
    catch (const spirv_cross::CompilerError &ex) {
        common.error_string = ex.what();
        return ScResult::CompilationError;
    }
    catch (const std::exception &ex) {
        common.error_string = ex.what();
        return ScResult::Error;
    }
    catch (...) {
        common.error_string = "Unhandled error";
        return ScResult::Unhandled;
    }
    return ScResult::Success;
}

template <typename F>
inline ScResult sc_handle(const ScCompiler *compiler, F lambda)
{
    return sc_handle(compiler->common(), lambda);
}

template <typename F>
inline ScResult sc_handle(const ScCompilerGlsl *compiler, F lambda)
{
    return sc_handle(compiler->common(), lambda);
}

extern "C" {

void sc_compiler_delete(ScCompiler *compiler)
{
    delete compiler;
}

ScDString sc_compiler_get_error_string(const ScCompiler *compiler)
{
    return to_d_string(compiler->common(), compiler->common().error_string);
}

ScResult sc_compiler_compile(ScCompiler *compiler, ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_string(compiler->common(), compiler->cl()->compile());
    });
}

ScResult sc_compiler_get_name(const ScCompiler *compiler, uint32_t id,
                              ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_string(compiler->common(), compiler->cl()->get_name(id));
    });
}

ScResult sc_compiler_set_decoration(ScCompiler *compiler, uint32_t id,
                                    spv::Decoration decoration,
                                    uint32_t argument)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_decoration(id, decoration, argument);
    });
}

ScResult sc_compiler_set_decoration_string(ScCompiler *compiler, uint32_t id,
                                           spv::Decoration dec,
                                           ScDString string)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_decoration_string(id, dec, to_cpp_string(string));
    });
}

ScResult sc_compiler_set_name(ScCompiler *compiler, uint32_t id,
                              ScDString string)
{
    return sc_handle(
        compiler, [&] { compiler->cl()->set_name(id, to_cpp_string(string)); });
}

// get_decoration_bitset

ScResult sc_compiler_has_decoration(const ScCompiler *compiler, uint32_t id,
                                    spv::Decoration decoration, bool *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->has_decoration(id, decoration);
    });
}

ScResult sc_compiler_get_decoration(const ScCompiler *compiler, uint32_t id,
                                    spv::Decoration decoration,
                                    uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_decoration(id, decoration);
    });
}

ScResult sc_compiler_get_decoration_string(const ScCompiler *compiler,
                                           uint32_t id,
                                           spv::Decoration decoration,
                                           ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_string(
            compiler, compiler->cl()->get_decoration_string(id, decoration));
    });
}

ScResult sc_compiler_unset_decoration(ScCompiler *compiler, uint32_t id,
                                      spv::Decoration decoration)
{
    return sc_handle(compiler,
                     [&] { compiler->cl()->unset_decoration(id, decoration); });
}

ScResult sc_compiler_get_type(const ScCompiler *compiler, uint32_t id,
                              const SPIRType **result)
{
    return sc_handle(
        compiler, [&] { *result = type_conv(compiler->cl()->get_type(id)); });
}

ScResult sc_compiler_get_type_from_variable(const ScCompiler *compiler,
                                            uint32_t id,
                                            const SPIRType **result)
{
    return sc_handle(compiler, [&] {
        *result = type_conv(compiler->cl()->get_type_from_variable(id));
    });
}

ScResult sc_compiler_get_non_pointer_type_id(const ScCompiler *compiler,
                                             uint32_t type_id, uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_non_pointer_type_id(type_id);
    });
}

ScResult sc_compiler_get_non_pointer_type(const ScCompiler *compiler,
                                          uint32_t id, const SPIRType **result)
{
    return sc_handle(compiler, [&] {
        *result = type_conv(compiler->cl()->get_non_pointer_type(id));
    });
}

// is_sampled_image type to be implemented in D

ScResult sc_compiler_get_storage_class(const ScCompiler *compiler, uint32_t id,
                                       spv::StorageClass *result)
{
    return sc_handle(compiler,
                     [&] { *result = compiler->cl()->get_storage_class(id); });
}

ScResult sc_compiler_get_fallback_name(const ScCompiler *compiler, uint32_t id,
                                       ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_string(compiler, compiler->cl()->get_fallback_name(id));
    });
}

ScResult sc_compiler_get_block_fallback_name(const ScCompiler *compiler,
                                             uint32_t id, ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result =
            to_d_string(compiler, compiler->cl()->get_block_fallback_name(id));
    });
}

ScResult sc_compiler_get_member_name(const ScCompiler *compiler, uint32_t id,
                                     uint32_t index, ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result =
            to_d_string(compiler, compiler->cl()->get_member_name(id, index));
    });
}

ScResult sc_compiler_get_member_decoration(const ScCompiler *compiler,
                                           uint32_t id, uint32_t index,
                                           spv::Decoration decoration,
                                           uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_member_decoration(id, index, decoration);
    });
}

ScResult sc_compiler_get_member_decoration_string(const ScCompiler *compiler,
                                                  uint32_t id, uint32_t index,
                                                  spv::Decoration decoration,
                                                  ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result =
            to_d_string(compiler, compiler->cl()->get_member_decoration_string(
                                      id, index, decoration));
    });
}

ScResult sc_compiler_set_member_name(ScCompiler *compiler, uint32_t id,
                                     uint32_t index, ScDString name)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_member_name(id, index, to_cpp_string(name));
    });
}

ScResult sc_compiler_get_member_qualified_name(const ScCompiler *compiler,
                                               uint32_t id, uint32_t index,
                                               ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_string(
            compiler, compiler->cl()->get_member_qualified_name(id, index));
    });
}

ScResult sc_compiler_set_member_qualified_name(ScCompiler *compiler,
                                               uint32_t id, uint32_t index,
                                               ScDString name)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_member_qualified_name(id, index,
                                                  to_cpp_string(name));
    });
}

// get_member_decoration_bitset

ScResult sc_compiler_has_member_decoration(const ScCompiler *compiler,
                                           uint32_t id, uint32_t index,
                                           spv::Decoration decoration,
                                           bool *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->has_member_decoration(id, index, decoration);
    });
}

ScResult sc_compiler_set_member_decoration(ScCompiler *compiler, uint32_t id,
                                           uint32_t index,
                                           spv::Decoration decoration,
                                           uint32_t arg)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_member_decoration(id, index, decoration, arg);
    });
}

ScResult sc_compiler_set_member_decoration_string(ScCompiler *compiler,
                                                  uint32_t id, uint32_t index,
                                                  spv::Decoration decoration,
                                                  ScDString arg)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_member_decoration_string(id, index, decoration,
                                                     to_cpp_string(arg));
    });
}

ScResult sc_compiler_unset_member_decoration(ScCompiler *compiler, uint32_t id,
                                             uint32_t index,
                                             spv::Decoration decoration)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->unset_member_decoration(id, index, decoration);
    });
}

// get_fallback_member_name in D

ScResult
sc_compiler_get_active_buffer_ranges(const ScCompiler *compiler, uint32_t id,
                                     ScDArray<spirv_cross::BufferRange> *result)
{
    return sc_handle(compiler, [&] {
        *result =
            to_d_array(compiler, compiler->cl()->get_active_buffer_ranges(id));
    });
}

ScResult sc_compiler_get_declared_struct_size(const ScCompiler *compiler,
                                              const SPIRType *type,
                                              size_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_declared_struct_size(type_conv(type));
    });
}

ScResult sc_compiler_get_declared_struct_size_runtime_array(
    const ScCompiler *compiler, const SPIRType *type, size_t array_size,
    size_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_declared_struct_size_runtime_array(
            type_conv(type), array_size);
    });
}

ScResult sc_compiler_get_declared_struct_member_size(const ScCompiler *compiler,
                                                     const SPIRType *type,
                                                     uint32_t index,
                                                     size_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_declared_struct_member_size(
            type_conv(type), index);
    });
}

static std::unordered_set<uint32_t> array_to_set(ScDArray<uint32_t> darr)
{
    std::unordered_set<uint32_t> set;
    for (size_t i = 0; i < darr.length; ++i) {
        set.emplace(darr.ptr[i]);
    }
    return set;
}

ScResult sc_compiler_get_active_interface_variables(const ScCompiler *compiler,
                                                    ScDArray<uint32_t> *result)
{
    return sc_handle(compiler, [&] {
        const auto set = compiler->cl()->get_active_interface_variables();
        const auto sz = set.size();
        auto *mem = static_cast<uint32_t *>(
            compiler->common().gc_alloc(sz * sizeof(uint32_t)));
        size_t i = 0;
        for (auto r : set)
            mem[i++] = r;

        *result = ScDArray<uint32_t>{sz, mem};
    });
}

ScResult
sc_compiler_set_enabled_interface_variables(ScCompiler *compiler,
                                            ScDArray<uint32_t> active_variables)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_enabled_interface_variables(
            array_to_set(active_variables));
    });
}

static void
fill_resource_array(const ScCompiler *cl, ScDArray<Resource> *resources,
                    const std::vector<spirv_cross::Resource> &sc_res)
{
    auto const sc_size = sc_res.size();

    if (sc_size == 0) {
        resources->length = 0;
        resources->ptr = nullptr;
        return;
    }

    resources->length = sc_size;
    resources->ptr = static_cast<Resource *>(
        cl->common().gc_alloc(sc_size * sizeof(Resource)));

    for (uint32_t i = 0; i < sc_size; i++) {
        auto const &resource = sc_res[i];
        resources->ptr[i].id = resource.id;
        resources->ptr[i].type_id = resource.type_id;
        resources->ptr[i].base_type_id = resource.base_type_id;
        resources->ptr[i].name = to_d_string(cl->common(), resource.name);
    }
}

static void fill_shader_resources(const ScCompiler *cl, ShaderResources *d_res,
                                  const spirv_cross::ShaderResources &sc_res)
{
    fill_resource_array(cl, &d_res->uniform_buffers, sc_res.uniform_buffers);
    fill_resource_array(cl, &d_res->storage_buffers, sc_res.storage_buffers);
    fill_resource_array(cl, &d_res->stage_inputs, sc_res.stage_inputs);
    fill_resource_array(cl, &d_res->stage_outputs, sc_res.stage_outputs);
    fill_resource_array(cl, &d_res->subpass_inputs, sc_res.subpass_inputs);
    fill_resource_array(cl, &d_res->storage_images, sc_res.storage_images);
    fill_resource_array(cl, &d_res->sampled_images, sc_res.sampled_images);
    fill_resource_array(cl, &d_res->atomic_counters, sc_res.atomic_counters);
    fill_resource_array(cl, &d_res->push_constant_buffers,
                        sc_res.push_constant_buffers);
    fill_resource_array(cl, &d_res->separate_images, sc_res.separate_images);
    fill_resource_array(cl, &d_res->separate_samplers,
                        sc_res.separate_samplers);
}

ScResult sc_compiler_get_shader_resources(const ScCompiler *compiler,
                                          ShaderResources *result)
{
    return sc_handle(compiler, [&] {
        fill_shader_resources(compiler, result,
                              compiler->cl()->get_shader_resources());
    });
}

ScResult
sc_compiler_get_shader_resources_for_vars(const ScCompiler *compiler,
                                          ScDArray<uint32_t> active_variables,
                                          ShaderResources *result)
{
    return sc_handle(compiler, [&] {
        fill_shader_resources(compiler, result,
                              compiler->cl()->get_shader_resources(
                                  array_to_set(active_variables)));
    });
}

ScResult sc_compiler_set_remapped_variable_state(ScCompiler *compiler,
                                                 uint32_t id, bool remap_enable)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_remapped_variable_state(id, remap_enable);
    });
}

ScResult sc_compiler_get_remapped_variable_state(const ScCompiler *compiler,
                                                 uint32_t id, bool *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_remapped_variable_state(id);
    });
}

ScResult sc_compiler_set_subpass_input_remapped_components(ScCompiler *compiler,
                                                           uint32_t id,
                                                           uint32_t components)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_subpass_input_remapped_components(id, components);
    });
}

ScResult
sc_compiler_get_subpass_input_remapped_components(const ScCompiler *compiler,
                                                  uint32_t id, uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_subpass_input_remapped_components(id);
    });
}

ScResult sc_compiler_get_entry_points_and_stages(const ScCompiler *compiler,
                                                 ScDArray<EntryPoint> *result)
{
    return sc_handle(compiler, [&] {
        const auto eps = compiler->cl()->get_entry_points_and_stages();
        const auto sz = eps.size();
        auto *mem = static_cast<EntryPoint *>(
            compiler->common().gc_alloc(sz * sizeof(EntryPoint)));
        size_t i = 0;
        for (size_t i = 0; i < sz; ++i) {
            mem[i].name = to_d_string(compiler, eps[i].name);
            mem[i].execution_model = eps[i].execution_model;
        }
        *result = ScDArray<EntryPoint>{sz, mem};
    });
}

ScResult sc_compiler_set_entry_point(ScCompiler *compiler, ScDString entry,
                                     spv::ExecutionModel execution_model)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_entry_point(to_cpp_string(entry), execution_model);
    });
}

ScResult sc_compiler_rename_entry_point(ScCompiler *compiler,
                                        ScDString old_name, ScDString new_name,
                                        spv::ExecutionModel execution_model)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->rename_entry_point(
            to_cpp_string(old_name), to_cpp_string(new_name), execution_model);
    });
}

// get_entry_point?

ScResult sc_compiler_get_cleansed_entry_point_name(
    const ScCompiler *compiler, ScDString name,
    spv::ExecutionModel execution_model, ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result =
            to_d_string(compiler, compiler->cl()->get_cleansed_entry_point_name(
                                      to_cpp_string(name), execution_model));
    });
}

// execution_mod_bitset

ScResult sc_compiler_unset_execution_mode(ScCompiler *compiler,
                                          spv::ExecutionMode mode)
{
    return sc_handle(compiler,
                     [&] { compiler->cl()->unset_execution_mode(mode); });
}

ScResult sc_compiler_set_execution_mode(ScCompiler *compiler,
                                        spv::ExecutionMode execution_mode,
                                        uint32_t arg0, uint32_t arg1,
                                        uint32_t arg2)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_execution_mode(execution_mode, arg0, arg1, arg2);
    });
}

ScResult
sc_compiler_get_execution_mode_argument(const ScCompiler *compiler,
                                        spv::ExecutionMode execution_mode,
                                        uint32_t index, uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result =
            compiler->cl()->get_execution_mode_argument(execution_mode, index);
    });
}

ScResult sc_compiler_get_execution_model(const ScCompiler *compiler,
                                         spv::ExecutionModel *result)
{
    return sc_handle(compiler,
                     [&] { *result = compiler->cl()->get_execution_model(); });
}

ScResult sc_compiler_get_work_group_size_specialization_constants(
    const ScCompiler *compiler, spirv_cross::SpecializationConstant *x,
    spirv_cross::SpecializationConstant *y,
    spirv_cross::SpecializationConstant *z, uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_work_group_size_specialization_constants(
            *x, *y, *z);
    });
}

ScResult
sc_compiler_build_dummy_sampler_for_combined_images(ScCompiler *compiler,
                                                    uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->build_dummy_sampler_for_combined_images();
    });
}

ScResult sc_compiler_build_combined_image_samples(ScCompiler *compiler)
{
    return sc_handle(compiler,
                     [&] { compiler->cl()->build_combined_image_samplers(); });
}

ScResult sc_compiler_get_combined_image_samplers(
    const ScCompiler *compiler,
    ScDArray<spirv_cross::CombinedImageSampler> *result)
{
    return sc_handle(compiler, [&] {
        *result =
            to_d_array(compiler, compiler->cl()->get_combined_image_samplers());
    });
}

// remap_callback

ScResult sc_compiler_get_specialization_constants(
    const ScCompiler *compiler,
    ScDArray<spirv_cross::SpecializationConstant> *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_array(compiler,
                             compiler->cl()->get_specialization_constants());
    });
}

// get_constant

ScResult sc_compiler_get_current_id_bound(const ScCompiler *compiler,
                                          uint32_t *result)
{
    return sc_handle(compiler,
                     [&] { *result = compiler->cl()->get_current_id_bound(); });
}

ScResult sc_compiler_type_struct_member_offset(const ScCompiler *compiler,
                                               const SPIRType *type,
                                               uint32_t index, uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result =
            compiler->cl()->type_struct_member_offset(type_conv(type), index);
    });
}

ScResult sc_compiler_type_struct_member_array_stride(const ScCompiler *compiler,
                                                     const SPIRType *type,
                                                     uint32_t index,
                                                     uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->type_struct_member_array_stride(
            type_conv(type), index);
    });
}

ScResult
sc_compiler_type_struct_member_matrix_stride(const ScCompiler *compiler,
                                             const SPIRType *type,
                                             uint32_t index, uint32_t *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->type_struct_member_matrix_stride(
            type_conv(type), index);
    });
}

ScResult sc_compiler_get_binary_offset_for_decoration(
    const ScCompiler *compiler, uint32_t id, spv::Decoration decoration,
    uint32_t *word_offset, bool *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->get_binary_offset_for_decoration(
            id, decoration, *word_offset);
    });
}

ScResult sc_compiler_buffer_is_hlsl_counter_buffer(const ScCompiler *compiler,
                                                   uint32_t id, bool *result)
{
    return sc_handle(compiler, [&] {
        *result = compiler->cl()->buffer_is_hlsl_counter_buffer(id);
    });
}

ScResult sc_compiler_buffer_get_hlsl_counter_buffer(const ScCompiler *compiler,
                                                    uint32_t id,
                                                    uint32_t *counter_id,
                                                    bool *result)
{
    return sc_handle(compiler, [&] {
        *result =
            compiler->cl()->buffer_get_hlsl_counter_buffer(id, *counter_id);
    });
}

ScResult
sc_compiler_get_declared_capabilities(const ScCompiler *compiler,
                                      ScDArray<spv::Capability> *result)
{
    return sc_handle(compiler, [&] {
        *result =
            to_d_array(compiler, compiler->cl()->get_declared_capabilities());
    });
}

ScResult sc_compiler_get_declared_extensions(const ScCompiler *compiler,
                                             ScDArray<ScDString> *result)
{
    return sc_handle(compiler, [&] {
        const auto exts = compiler->cl()->get_declared_extensions();
        const auto sz = exts.size();
        auto *mem = static_cast<ScDString *>(
            compiler->common().gc_alloc(sz * sizeof(ScDString)));
        size_t i = 0;
        for (const auto &ext : exts) {
            mem[i++] = to_d_string(compiler, ext);
        }
        *result = ScDArray<ScDString>{sz, mem};
    });
}

ScResult
sc_compiler_get_remapped_declared_block_name(const ScCompiler *compiler,
                                             uint32_t id, ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_string(
            compiler, compiler->cl()->get_remapped_declared_block_name(id));
    });
}

// buffer_block_flags

// GLSL compiler funcs

ScResult sc_compiler_glsl_new(ScDArray<const uint32_t> ir,
                              ScGcCallbacks gc_callbacks,
                              ScCompilerGlsl **result, ScDString *error)
{
    auto common = ScCommon{gc_callbacks};

    try {
        *result = new ScCompilerGlsl{common, ir};
    }
    catch (const spirv_cross::CompilerError &ex) {
        *error = to_d_string(common, ex.what());
        return ScResult::CompilationError;
    }
    catch (const std::exception &ex) {
        *error = to_d_string(common, ex.what());
        return ScResult::Error;
    }
    catch (...) {
        const auto msg = "Unhandled error";
        *error = ScDString{std::strlen(msg), &msg[0]};
        return ScResult::Unhandled;
    }
    return ScResult::Success;
}

ScResult sc_compiler_glsl_get_options(const ScCompilerGlsl *compiler,
                                      ScOptionsGlsl *result)
{
    return sc_handle(compiler, [&] {
        *result = *reinterpret_cast<const ScOptionsGlsl *>(
            &compiler->cl()->get_common_options());
    });
}

ScResult sc_compiler_glsl_set_options(ScCompilerGlsl *compiler,
                                      const ScOptionsGlsl *options)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->set_common_options(
            *reinterpret_cast<const spirv_cross::CompilerGLSL::Options *>(
                options));
    });
}

ScResult sc_compiler_glsl_get_partial_source(ScCompilerGlsl *compiler,
                                             ScDString *result)
{
    return sc_handle(compiler, [&] {
        *result = to_d_string(compiler->common(),
                              compiler->cl()->get_partial_source());
    });
}

ScResult sc_compiler_glsl_add_header_line(ScCompilerGlsl *compiler,
                                          ScDString str)
{
    return sc_handle(
        compiler, [&] { compiler->cl()->add_header_line(to_cpp_string(str)); });
}

ScResult sc_compiler_glsl_require_extension(ScCompilerGlsl *compiler,
                                            ScDString ext)
{
    return sc_handle(compiler, [&] {
        compiler->cl()->require_extension(to_cpp_string(ext));
    });
}

ScResult sc_compiler_glsl_flatten_buffer_block(ScCompilerGlsl *compiler,
                                               uint32_t id)
{
    return sc_handle(compiler,
                     [&] { compiler->cl()->flatten_buffer_block(id); });
}

} // extern "C"
