#pragma warning(disable : 4996 4101)
#include "spirv_cross_util.hpp"
#include "spirv_hlsl.hpp"
#include "spirv_msl.hpp"
#include "spirv_glsl.hpp"
#include "wrapper.hpp"

#include <memory>
#include <string>
#include <cstring>


struct SpvCompiler
{
    const spirv_cross::Compiler *cl() const {
        return &this->_cl;
    }
    spirv_cross::Compiler *cl() {
        return &this->_cl;
    }
private:
    spirv_cross::Compiler _cl;
};

struct SpvCompilerGlsl
{
    SpvCompilerGlsl(SpvDArray<const uint32_t> ir) :
        _cl {ir.ptr, ir.length}
    {}

    const spirv_cross::CompilerGLSL *cl() const {
        return &this->_cl;
    }
    spirv_cross::CompilerGLSL *cl() {
        return &this->_cl;
    }

private:
    spirv_cross::CompilerGLSL _cl;
};

struct SpvCompilerHlsl
{
    SpvCompilerHlsl(SpvDArray<const uint32_t> ir) :
        _cl {ir.ptr, ir.length}
    {}

    const spirv_cross::CompilerHLSL *cl() const {
        return &this->_cl;
    }
    spirv_cross::CompilerHLSL *cl() {
        return &this->_cl;
    }

private:
    spirv_cross::CompilerHLSL _cl;
};

struct SpvCompilerMsl
{
    SpvCompilerMsl(SpvDArray<const uint32_t> ir) :
        _cl {ir.ptr, ir.length}
    {}

    const spirv_cross::CompilerMSL *cl() const {
        return &this->_cl;
    }
    spirv_cross::CompilerMSL *cl() {
        return &this->_cl;
    }

private:
    spirv_cross::CompilerMSL _cl;
};

inline SpvDString to_d_string(const std::string &s) {
    const auto size = s.size();
    auto *mem = static_cast<char *>(spv_d_gc_alloc(size));
    std::memcpy(mem, s.c_str(), size);
    return SpvDString {
        size, mem
    };
}

inline SpvDString to_d_string(const char *s) {
    const auto size = std::strlen(s);
    auto *mem = static_cast<char *>(spv_d_gc_alloc(size));
    std::memcpy(mem, s, size);
    return SpvDString {
        size, mem
    };
}


template<typename F>
inline SpvResult spv_handle(SpvDString *error_msg, F lambda)
{
    try {
        lambda();
    }
    catch(const spirv_cross::CompilerError &ex) {
        *error_msg = to_d_string(ex.what());
        return SpvResult::CompilationError;
    }
    catch(const std::exception& ex) {
        *error_msg = to_d_string(ex.what());
        return SpvResult::Error;
    }
    catch(...) {
        *error_msg = { 0, nullptr };
        return SpvResult::Unhandled;
    }
    *error_msg = { 0, nullptr };
    return SpvResult::Success;
}


extern "C" {

SpvResult spv_compiler_glsl_new(SpvDArray<const uint32_t> ir,
                                SpvCompilerGlsl **compiler,
                                SpvDString *error_msg)
{
    return spv_handle(error_msg, [=] {
        *compiler = new SpvCompilerGlsl(ir);
    });
}

void spv_compiler_glsl_get_options(const SpvCompilerGlsl *compiler,
                                   SpvGlslCompilerOptions *options)
{
    auto glslOptions = compiler->cl()->get_common_options();
    options->version = glslOptions.version;
    options->es = glslOptions.es;
    options->force_temp = glslOptions.force_temporary;
    options->vulk_semantics = glslOptions.vulkan_semantics;
    options->separate_shader_objs = glslOptions.separate_shader_objects;
    options->flatten_multidim_arrays = glslOptions.flatten_multidimensional_arrays;
    options->enable_420pack = glslOptions.enable_420pack_extension;
    options->vertex_transform_clip_space = glslOptions.vertex.fixup_clipspace;
    options->vertex_invert_y = glslOptions.vertex.flip_vert_y;
    options->frag_def_float_prec =
            static_cast<SpvGlslPrecision>(glslOptions.fragment.default_float_precision);
    options->frag_def_int_prec =
            static_cast<SpvGlslPrecision>(glslOptions.fragment.default_int_precision);
}

void spv_compiler_glsl_set_options(SpvCompilerGlsl *compiler,
                                   const SpvGlslCompilerOptions *options)
{
    auto glslOptions = compiler->cl()->get_common_options();
    glslOptions.version = options->version;
    glslOptions.es = options->es;
    glslOptions.force_temporary = options->force_temp;
    glslOptions.vulkan_semantics = options->vulk_semantics;
    glslOptions.separate_shader_objects = options->separate_shader_objs;
    glslOptions.flatten_multidimensional_arrays = options->flatten_multidim_arrays;
    glslOptions.enable_420pack_extension = options->enable_420pack;
    glslOptions.vertex.fixup_clipspace = options->vertex_transform_clip_space;
    glslOptions.vertex.flip_vert_y = options->vertex_invert_y;
    glslOptions.fragment.default_float_precision =
            static_cast<spirv_cross::CompilerGLSL::Options::Precision>(options->frag_def_float_prec);
    glslOptions.fragment.default_int_precision =
            static_cast<spirv_cross::CompilerGLSL::Options::Precision>(options->frag_def_int_prec);
    compiler->cl()->set_common_options(glslOptions);
}

SpvResult spv_compiler_glsl_build_combined_image_samplers(SpvCompilerGlsl *compiler,
                                                          SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        compiler->cl()->build_combined_image_samplers();
    });
}

SpvResult spv_compiler_hlsl_new(SpvDArray<const uint32_t> ir,
                               SpvCompilerHlsl **compiler,
                               SpvDString *error_msg)
{
    return spv_handle(error_msg, [=] {
        *compiler = new SpvCompilerHlsl{ir};
    });
}

void spv_compiler_hlsl_get_options(const SpvCompilerHlsl *compiler,
                                   SpvHlslCompilerOptions *options)
{
    auto common_options = compiler->cl()->get_common_options();
    auto hlsl_options = compiler->cl()->get_hlsl_options();

    options->shader_model = hlsl_options.shader_model;
    options->vertex_transform_clip_space = common_options.vertex.fixup_clipspace;
    options->vertex_invert_y = common_options.vertex.flip_vert_y;
}

void spv_compiler_hlsl_set_options(SpvCompilerHlsl *compiler,
                                   const SpvHlslCompilerOptions *options)
{
    auto common_options = compiler->cl()->get_common_options();
    auto hlsl_options = compiler->cl()->get_hlsl_options();

    common_options.vertex.fixup_clipspace = options->vertex_transform_clip_space;
    common_options.vertex.flip_vert_y = options->vertex_invert_y;
    hlsl_options.shader_model = options->shader_model;

    compiler->cl()->set_common_options(common_options);
    compiler->cl()->set_hlsl_options(hlsl_options);
}

void spv_compiler_hlsl_set_root_constant_layout(SpvCompilerHlsl *compiler,
                                                SpvDArray<const SpvHlslRootConstant> constants)
{
    std::vector<spirv_cross::RootConstants> root_constants;
    for (size_t i = 0; i < constants.length; i++)
    {
        root_constants.push_back(
            spirv_cross::RootConstants{
                constants.ptr[i].start,
                constants.ptr[i].end,
                constants.ptr[i].binding,
                constants.ptr[i].space
            }
        );
    }

    compiler->cl()->set_root_constant_layouts(root_constants);
}

SpvResult spv_compiler_msl_new(SpvDArray<const uint32_t> ir,
                               SpvCompilerMsl **compiler,
                               SpvDString *error_msg)
{
    return spv_handle(error_msg, [=] {
        *compiler = new SpvCompilerMsl{ir};
    });
}

void spv_compiler_msl_get_options(const SpvCompilerMsl *compiler,
                                  SpvMslCompilerOptions *options)
{
    auto common_options = compiler->cl()->get_common_options();

    options->vertex_transform_clip_space = common_options.vertex.fixup_clipspace;
    options->vertex_invert_y = common_options.vertex.flip_vert_y;
}

void spv_compiler_msl_set_options(SpvCompilerMsl *compiler,
                                  const SpvMslCompilerOptions *options)
{
    auto common_options = compiler->cl()->get_common_options();
    common_options.vertex.fixup_clipspace = options->vertex_transform_clip_space;
    common_options.vertex.flip_vert_y = options->vertex_invert_y;

    compiler->cl()->set_common_options(common_options);
}

SpvResult spv_compiler_msl_compile(SpvCompilerMsl *compiler,
                                   SpvDArray<const spirv_cross::MSLVertexAttr> vat_overrides,
                                   SpvDArray<const spirv_cross::MSLResourceBinding> res_overrides,
                                   SpvDString *shader,
                                   SpvDString *error_msg)
{
    return spv_handle(error_msg, [=] {
        std::vector<spirv_cross::MSLVertexAttr> vat;
        if (vat_overrides.length) {
            vat.insert(vat.end(), vat_overrides.ptr, vat_overrides.ptr+vat_overrides.length);
        }

        std::vector<spirv_cross::MSLResourceBinding> res;
        if (res_overrides.length) {
            res.insert(res.end(), res_overrides.ptr, res_overrides.ptr+res_overrides.length);
        }

        *shader = to_d_string(compiler->cl()->compile(&vat, &res));
    });
}


void spv_compiler_delete(SpvCompiler *compiler)
{
    delete compiler;
}

SpvResult spv_compiler_get_decoration(const SpvCompiler *compiler,
                                      const uint32_t id,
                                      const spv::Decoration decoration,
                                      uint32_t *result,
                                      SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        *result = compiler->cl()->get_decoration(id, decoration);
    });
}

SpvResult spv_compiler_set_decoration(SpvCompiler *compiler,
                                      const uint32_t id,
                                      const spv::Decoration decoration,
                                      const uint32_t argument,
                                      SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        compiler->cl()->set_decoration(id, decoration, argument);
    });
}

SpvResult spv_compiler_get_entry_points(const SpvCompiler *compiler,
                                        SpvDArray<SpvEntryPoint> *entry_points,
                                        SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        auto const &spv_entry_point_names_and_stages = compiler->cl()->get_entry_points_and_stages();
        auto const spv_size = spv_entry_point_names_and_stages.size();
        auto const &spv_entry_points = std::make_unique<spirv_cross::SPIREntryPoint[]>(spv_size);
        for (uint32_t i = 0; i < spv_size; i++)
        {
            auto const &spv_entry_point = spv_entry_point_names_and_stages[i];
            spv_entry_points[i] = compiler->cl()->get_entry_point(spv_entry_point.name, spv_entry_point.execution_model);
        }

        entry_points->ptr = static_cast<SpvEntryPoint*>(spv_d_gc_alloc(spv_size * sizeof(SpvEntryPoint)));
        entry_points->length = spv_size;
        for (uint32_t i = 0; i < spv_size; i++)
        {
            auto const &spv_entry_point = spv_entry_points[i];
            entry_points->ptr[i].name = to_d_string(spv_entry_point.name);
            entry_points->ptr[i].execution_model = spv_entry_point.model;
            entry_points->ptr[i].work_group_size_x = spv_entry_point.workgroup_size.x;
            entry_points->ptr[i].work_group_size_y = spv_entry_point.workgroup_size.y;
            entry_points->ptr[i].work_group_size_z = spv_entry_point.workgroup_size.z;
        }
    });
}

SpvResult spv_compiler_get_cleansed_entry_point_name(const SpvCompiler *compiler,
                                                     const SpvDString original_entry_point_name,
                                                     const spv::ExecutionModel execution_model,
                                                     SpvDString *compiled_entry_point_name,
                                                     SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        *compiled_entry_point_name = to_d_string(
            compiler->cl()->get_cleansed_entry_point_name(
                std::string{original_entry_point_name.ptr, original_entry_point_name.length},
                execution_model
            )
        );
    });
}

static void fill_resource_array(SpvResourceDArray *resources,
                                const std::vector<spirv_cross::Resource> &spv_resources)
{
    auto const spv_size = spv_resources.size();

    if (spv_size == 0)
    {
        resources->length = 0;
        resources->ptr = nullptr;
        return;
    }

    resources->length = spv_size;
    resources->ptr = static_cast<SpvResource *>(spv_d_gc_alloc(spv_size * sizeof(SpvResource)));
    for (uint32_t i = 0; i < spv_size; i++)
    {
        auto const &resource = spv_resources[i];
        resources->ptr[i].id = resource.id;
        resources->ptr[i].type_id = resource.type_id;
        resources->ptr[i].base_type_id = resource.base_type_id;
        resources->ptr[i].name = to_d_string(resource.name);
    }
}

SpvResult spv_compiler_get_shader_resources(const SpvCompiler *compiler,
                                            SpvShaderResources *shader_resources,
                                            SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        auto const spv_resources = compiler->cl()->get_shader_resources();

        fill_resource_array(&shader_resources->uniform_buffers, spv_resources.uniform_buffers);
        fill_resource_array(&shader_resources->storage_buffers, spv_resources.storage_buffers);
        fill_resource_array(&shader_resources->stage_inputs, spv_resources.stage_inputs);
        fill_resource_array(&shader_resources->stage_outputs, spv_resources.stage_outputs);
        fill_resource_array(&shader_resources->subpass_inputs, spv_resources.subpass_inputs);
        fill_resource_array(&shader_resources->storage_images, spv_resources.storage_images);
        fill_resource_array(&shader_resources->sampled_images, spv_resources.sampled_images);
        fill_resource_array(&shader_resources->atomic_counters, spv_resources.atomic_counters);
        fill_resource_array(&shader_resources->push_constant_buffers, spv_resources.push_constant_buffers);
        fill_resource_array(&shader_resources->separate_images, spv_resources.separate_images);
        fill_resource_array(&shader_resources->separate_samplers, spv_resources.separate_samplers);
    });
}

SpvResult spv_compiler_get_specialization_constants(const SpvCompiler *compiler,
                                                    SpvDArray<SpvSpecializationConstant> *constants,
                                                    SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        auto const spv_constants = compiler->cl()->get_specialization_constants();
        auto const spv_size = spv_constants.size();

        constants->length = spv_size;
        constants->ptr = static_cast<SpvSpecializationConstant*>(spv_d_gc_alloc(spv_size * sizeof(SpvSpecializationConstant)));
        for (uint32_t i = 0; i < spv_size; i++)
        {
            auto const &spv_constant = spv_constants[i];
            constants->ptr[i].id = spv_constant.id;
            constants->ptr[i].constant_id = spv_constant.constant_id;
        }
    });
}

SpvResult spv_compiler_set_scalar_constant(SpvCompiler *compiler,
                                           const uint32_t id,
                                           const uint64_t constant,
                                           SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        auto &spv_constant = compiler->cl()->get_constant(id);
        spv_constant.m.c[0].r[0].u64 = constant;
    });
}

SpvResult spv_compiler_get_type(const SpvCompiler *compiler,
                                const uint32_t id,
                                SpvType *spirv_type,
                                SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        auto const &type = ((spirv_cross::Compiler *)compiler)->get_type(id);
        auto const member_types_size = type.member_types.size();
        auto const array_size = type.array.size();

        spirv_type->type = type.basetype;

        spirv_type->members.length = member_types_size;
        spirv_type->array.length = array_size;

        if (member_types_size > 0) {
            auto const &member_types = static_cast<uint32_t*>(spv_d_gc_alloc(member_types_size * sizeof(uint32_t)));

            for (size_t i = 0; i < member_types_size; i++) {
                member_types[i] = type.member_types[i];
            }

            spirv_type->members.ptr = member_types;
        }

        if (array_size > 0) {
            auto const &array = static_cast<uint32_t*>(spv_d_gc_alloc(array_size * sizeof(uint32_t)));

            for (size_t i = 0; i < array_size; i++)
            {
                array[i] = type.array[i];
            }

            spirv_type->array.ptr = array;
        }
    });
}

SpvResult spv_compiler_get_member_name(const SpvCompiler *compiler,
                                       const uint32_t id,
                                       const uint32_t index,
                                       SpvDString *name,
                                       SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        *name = to_d_string(compiler->cl()->get_member_name(id, index));
    });
}

SpvResult spv_compiler_get_member_decoration(const SpvCompiler *compiler,
                                             const uint32_t id,
                                             const uint32_t index,
                                             const spv::Decoration decoration,
                                             uint32_t *result,
                                             SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        *result = compiler->cl()->get_member_decoration(id, index, decoration);
    });
}

SpvResult spv_compiler_set_member_decoration(SpvCompiler *compiler,
                                             const uint32_t id,
                                             const uint32_t index,
                                             const spv::Decoration decoration,
                                             const uint32_t argument,
                                             SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        compiler->cl()->set_member_decoration(id, index, decoration, argument);
    });
}

SpvResult spv_compiler_get_declared_struct_size(const SpvCompiler *compiler,
                                                const uint32_t id,
                                                size_t *result,
                                                SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        *result = compiler->cl()->get_declared_struct_size(compiler->cl()->get_type(id));
    });
}

SpvResult spv_compiler_get_declared_struct_member_size(const SpvCompiler *compiler,
                                                       const uint32_t id,
                                                       const uint32_t index,
                                                       size_t *result,
                                                       SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        *result = compiler->cl()->get_declared_struct_member_size(compiler->cl()->get_type(id), index);
    });
}

SpvResult spv_compiler_rename_interface_variable(SpvCompiler *compiler,
                                                 const SpvDArray<const SpvResource> resources,
                                                 const uint32_t location,
                                                 const SpvDString name,
                                                 SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        std::vector<spirv_cross::Resource> spv_resources;
        for (size_t i = 0; i < resources.length; i++)
        {
            auto const &resource = resources.ptr[i];
            spirv_cross::Resource spv_resource;
            std::string spv_name(resource.name.ptr, resource.name.length);
            spv_resource.id = resource.id;
            spv_resource.type_id = resource.type_id;
            spv_resource.base_type_id = resource.base_type_id;
            spv_resource.name = spv_name;
            spv_resources.push_back(spv_resource);
        }
        spirv_cross_util::rename_interface_variable(
            *compiler->cl(), spv_resources, location, std::string{name.ptr, name.length}
        );
    });
}

SpvResult spv_compiler_compile(SpvCompiler *compiler,
                               SpvDString *shader,
                               SpvDString *error_msg)
{
    spv_handle(error_msg, [=] {
        *shader = to_d_string(compiler->cl()->compile());
    });
}


}
