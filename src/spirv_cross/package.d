module spirv_cross;

import n = spirv_cross.native;
static import spv;

class ScCompilationError : Exception
{
    this(string msg)
    {
        super(msg);
    }
}

class ScError : Exception
{
    this(string msg)
    {
        super(msg);
    }
}

struct SPIRType;

struct Resource
{
    uint id;
    uint typeId;
    uint baseTypeId;
    string name;
}

struct ShaderResources
{
    Resource[] uniformBuffers;
    Resource[] storageBuffers;
    Resource[] stageInputs;
    Resource[] stageOutputs;
    Resource[] subpassInputs;
    Resource[] storageImages;
    Resource[] sampledImages;
    Resource[] atomicCounters;
    Resource[] pushConstantBuffers;
    Resource[] separateImages;
    Resource[] separateSamplers;
}

struct EntryPoint
{
    string name;
    spv.ExecutionModel executionModel;
}

struct CombinedImageSampler
{
    /// The ID of the sampler2D variable.
    uint combinedId;
    /// The ID of the texture2D variable.
    uint imageId;
    /// The ID of the sampler variable.
    uint samplerId;
}

struct SpecializationConstant
{
    /// The ID of the specialization constant.
    uint id;
    /// The constant ID of the constant, used in Vulkan during pipeline creation.
    uint constant_id;
}

struct BufferRange
{
    uint index;
    size_t offset;
    size_t range;
}

/// GLSL precision
enum GlslPrecision
{
    dontCare,
    low,
    medium,
    high,
}

/// Options for the GLSL compiler
struct ScOptionsGlsl
{
    /// The shading language version. Corresponds to #version $VALUE.
    uint ver = 450;

    /// Emit the OpenGL ES shading language instead of desktop OpenGL.
    bool es = false;

    /// Debug option to always emit temporary variables for all expressions.
    bool forceTemporary = false;

    /// If true, Vulkan GLSL features are used instead of GL-compatible features.
    /// Mostly useful for debugging SPIR-V files.
    bool vulkanSemantics = false;

    /// If true, gl_PerVertex is explicitly redeclared in vertex, geometry and tessellation shaders.
    /// The members of gl_PerVertex is determined by which built-ins are declared by the shader.
    /// This option is ignored in ES versions, as redeclaration in ES is not required, and it depends on a different extension
    /// (EXT_shader_io_blocks) which makes things a bit more fuzzy.
    bool separateShaderObjects = false;

    /// Flattens multidimensional arrays, e.g. float foo[a][b][c] into single-dimensional arrays,
    /// e.g. float foo[a * b * c].
    /// This function does not change the actual SPIRType of any object.
    /// Only the generated code, including declarations of interface variables are changed to be single array dimension.
    bool flattenMultidimensionalArrays = false;

    /// For older desktop GLSL targets than version 420, the
    /// GL_ARB_shading_language_420pack extensions is used to be able to support
    /// layout(binding) on UBOs and samplers.
    /// If disabled on older targets, binding decorations will be stripped.
    bool enable420PackExtension = true;

    /// GLSL: In vertex shaders, rewrite [0, w] depth (Vulkan/D3D style) to [-w, w] depth (GL style).
    // MSL: In vertex shaders, rewrite [-w, w] depth (GL style) to [0, w] depth.
    // HLSL: In vertex shaders, rewrite [-w, w] depth (GL style) to [0, w] depth.
    bool vertFixupClipspace = false;

    /// Inverts gl_Position.y or equivalent.
    bool vertFlipY = false;

    /// If true, the backend will assume that InstanceIndex will need to apply
    /// a base instance offset. Set to false if you know you will never use base instance
    /// functionality as it might remove some internal uniforms.
    bool vertSupportNonzeroBaseInstance = true;

    /// Add precision mediump float in ES targets when emitting GLES source.
    GlslPrecision fragDefaultFloatPrecision = GlslPrecision.medium;
    /// Add precision highp int in ES targets when emitting GLES source.
    GlslPrecision fragDefaultIntPrecision = GlslPrecision.medium;
}

private void scEnforce(n.ScResult res, string msg)
{
    final switch (res)
    {
    case n.ScResult.success:
        return;
    case n.ScResult.compilationError:
        throw new ScCompilationError(msg);
    case n.ScResult.error:
        throw new ScError(msg);
    case n.ScResult.unhandled:
        throw new Exception(msg);
    }
}

private void scEnforce(const(n.ScCompiler)* cl, n.ScResult res)
{
    final switch (res)
    {
    case n.ScResult.success:
        return;
    case n.ScResult.compilationError:
        throw new ScCompilationError(n.sc_compiler_get_error_string(cl));
    case n.ScResult.error:
        throw new ScError(n.sc_compiler_get_error_string(cl));
    case n.ScResult.unhandled:
        throw new Exception(n.sc_compiler_get_error_string(cl));
    }
}

/// Abstract SPIR-V cross compiler
/// Analyses and provides introspection into SPIR-V byte code
abstract class ScCompiler
{
    private n.ScCompiler* _cl;

    private this(n.ScCompiler* cl)
    {
        _cl = cl;
    }

    ~this()
    {
        dispose();
    }

    /// Dispose native resources held by the compiler.
    /// It is called during GC collection, but can be also called manually.
    void dispose()
    {
        if (_cl)
        {
            n.sc_compiler_delete(_cl);
            _cl = null;
        }
    }

    /// After parsing, API users can modify the SPIR-V via reflection and call this
    /// to disassemble the SPIR-V into the desired langauage.
    /// Sub-classes actually implement this.
    string compile()
    {
        string result;
        scEnforce(_cl, n.sc_compiler_compile(_cl, result));
        return result;
    }

    /// Gets the identifier (OpName) of an ID. If not defined, an empty string will be returned.
    string getName(uint id) const
    {
        string result;
        scEnforce(_cl, n.sc_compiler_get_name(_cl, id, result));
        return result;
    }

    /// Applies a decoration to an ID. Effectively injects OpDecorate.
    void setDecoration(uint id, spv.Decoration decoration, uint argument = 0)
    {
        scEnforce(_cl, n.sc_compiler_set_decoration(_cl, id, decoration, argument));
    }

    /// ditto
    void setDecorationString(uint id, spv.Decoration decoration, string argument)
    {
        scEnforce(_cl, n.sc_compiler_set_decoration_string(_cl, id, decoration, argument));
    }

    /// Overrides the identifier OpName of an ID.
    /// Identifiers beginning with underscores or identifiers which contain double underscores
    /// are reserved by the implementation.
    void setName(uint id, string name)
    {
        scEnforce(_cl, n.sc_compiler_set_name(_cl, id, name));
    }

    // const Bitset &get_decoration_bitset(uint id) const;

    /// Returns whether the decoration has been applied to the ID.
    bool hasDecoration(uint id, spv.Decoration decoration) const
    {
        bool result = void;
        scEnforce(_cl, n.sc_compiler_has_decoration(_cl, id, decoration, result));
        return result;
    }

    /// Gets the value for decorations which take arguments.
    /// If the decoration is a boolean (i.e. spv.DecorationNonWritable),
    /// 1 will be returned.
    /// If decoration doesn't exist or decoration is not recognized,
    /// 0 will be returned.
    uint getDecoration(uint id, spv.Decoration decoration) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_get_decoration(_cl, id, decoration, result));
        return result;
    }
    /// ditto
    string getDecorationString(uint id, spv.Decoration decoration) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_decoration_string(_cl, id, decoration, result));
        return result;
    }

    /// Removes the decoration for an ID.
    void unsetDecoration(uint id, spv.Decoration decoration)
    {
        scEnforce(_cl, n.sc_compiler_unset_decoration(_cl, id, decoration));
    }

    /// Gets the SPIR-V type associated with ID.
    /// Mostly used with Resource::typeId and Resource::baseTypeId to parse the underlying type of a resource.
    const(SPIRType)* getType(uint id) const
    {
        const(SPIRType)* result = void;
        scEnforce(_cl, n.sc_compiler_get_type(_cl, id, result));
        return result;
    }

    /// Gets the SPIR-V type of a variable.
    const(SPIRType)* getTypeFromVariable(uint id) const
    {
        const(SPIRType)* result = void;
        scEnforce(_cl, n.sc_compiler_get_type_from_variable(_cl, id, result));
        return result;
    }

    /// Gets the id of SPIR-V type underlying the given typeId, which might be a pointer.
    uint getNonPointerTypeId(uint typeId) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_get_non_pointer_type_id(_cl, typeId, result));
        return result;
    }

    /// Gets the SPIR-V type underlying the given typeId, which might be a pointer.
    const(SPIRType)* getNonPointerType(uint typeId) const
    {
        const(SPIRType)* result = void;
        scEnforce(_cl, n.sc_compiler_get_non_pointer_type(_cl, typeId, result));
        return result;
    }

    // is_sampled_image

    /// Gets the underlying storage class for an OpVariable.
    spv.StorageClass getStorageClass(uint id) const
    {
        spv.StorageClass result = void;
        scEnforce(_cl, n.sc_compiler_get_storage_class(_cl, id, result));
        return result;
    }

    /// If get_name() is an empty string, get the fallback name which will be used
    /// instead in the disassembled source.
    string getFallbackName(uint id) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_fallback_name(_cl, id, result));
        return result;
    }

    /// If get_name() of a Block struct is an empty string, get the fallback name.
    /// This needs to be per-variable as multiple variables can use the same block type.
    string getBlockFallbackName(uint id) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_block_fallback_name(_cl, id, result));
        return result;
    }

    /// Given an OpTypeStruct in ID, obtain the identifier for member number "index".
    /// This may be an empty string.
    string getMemberName(uint id, uint index) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_member_name(_cl, id, index, result));
        return result;
    }

    /// Given an OpTypeStruct in ID, obtain the OpMemberDecoration for member number "index".
    uint getMemberDecoration(uint id, uint index, spv.Decoration decoration) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_get_member_decoration(_cl, id, index, decoration, result));
        return result;
    }
    /// ditto
    string getMemberDecorationString(uint id, uint index, spv.Decoration decoration) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_member_decoration_string(_cl, id,
                index, decoration, result));
        return result;
    }

    /// Sets the member identifier for OpTypeStruct ID, member number "index".
    void setMemberName(uint id, uint index, string name)
    {
        scEnforce(_cl, n.sc_compiler_set_member_name(_cl, id, index, name));
    }

    /// Returns the qualified member identifier for OpTypeStruct ID, member number "index",
    /// or an empty string if no qualified alias exists
    string getMemberQualifiedName(uint type_id, uint index) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_member_qualified_name(_cl, type_id, index, result));
        return result;
    }

    /// Sets the qualified member identifier for OpTypeStruct ID, member number "index".
    void setMemberQualifiedName(uint type_id, uint index, string name)
    {
        scEnforce(_cl, n.sc_compiler_set_member_qualified_name(_cl, type_id, index, name));
    }

    // const Bitset &get_member_decoration_bitset(uint id, uint index) const;

    /// Returns whether the decoration has been applied to a member of a struct.
    bool hasMemberDecoration(uint id, uint index, spv.Decoration decoration) const
    {
        bool result = void;
        scEnforce(_cl, n.sc_compiler_has_member_decoration(_cl, id, index, decoration, result));
        return result;
    }

    /// Similar to setDecoration, but for struct members.
    void setMemberDecoration(uint id, uint index, spv.Decoration decoration, uint argument = 0)
    {
        scEnforce(_cl, n.sc_compiler_set_member_decoration(_cl, id, index, decoration, argument));
    }

    void setMemberDecorationString(uint id, uint index,
            spv.Decoration decoration, string argument)
    {
        scEnforce(_cl, n.sc_compiler_set_member_decoration_string(_cl, id,
                index, decoration, argument));
    }

    /// Unsets a member decoration, similar to unsetDecoration.
    void unsetMemberDecoration(uint id, uint index, spv.Decoration decoration)
    {
        scEnforce(_cl, n.sc_compiler_unset_member_decoration(_cl, id, index, decoration));
    }

    /// Gets the fallback name for a member, similar to getFallbackName.
    string getFallbackMemberName(uint index) const
    {
        import std.array : array;
        import std.range : repeat;

        return repeat('_', index).array;
    }

    /// Returns a vector of which members of a struct are potentially in use by a
    /// SPIR-V shader. The granularity of this analysis is per-member of a struct.
    /// This can be used for Buffer (UBO), BufferBlock/StorageBuffer (SSBO) and PushConstant blocks.
    /// ID is the Resource::id obtained from get_shader_resources().
    BufferRange[] getActiveBufferRanges(uint id) const
    {
        BufferRange[] result = void;
        scEnforce(_cl, n.sc_compiler_get_active_buffer_ranges(_cl, id, result));
        return result;
    }

    /// Returns the effective size of a buffer block.
    size_t getDeclaredStructSize(const(SPIRType)* struct_type) const
    {
        size_t result = void;
        scEnforce(_cl, n.sc_compiler_get_declared_struct_size(_cl, struct_type, result));
        return result;
    };

    /// Returns the effective size of a buffer block, with a given array size
    /// for a runtime array.
    /// SSBOs are typically declared as runtime arrays. getDeclaredStructSize() will return 0 for the size.
    /// This is not very helpful for applications which might need to know the array stride of its last member.
    /// This can be done through the API, but it is not very intuitive how to accomplish this, so here we provide a helper function
    /// to query the size of the buffer, assuming that the last member has a certain size.
    /// If the buffer does not contain a runtime array, arraySize is ignored, and the function will behave as
    /// getDeclaredStructSize().
    /// To get the array stride of the last member, something like:
    /// getDeclaredStructSizeRuntimeArray(type, 1) - getDeclaredStructSizeRuntimeArray(type, 0) will work.
    size_t getDeclaredStructSizeRuntimeArray(const(SPIRType)* structType, size_t arraySize) const
    {
        size_t result = void;
        scEnforce(_cl, n.sc_compiler_get_declared_struct_size_runtime_array(_cl,
                structType, arraySize, result));
        return result;
    }

    /// Returns the effective size of a buffer block struct member.
    size_t getDeclaredStructMemberSize(const(SPIRType)* structType, uint index) const
    {
        size_t result = void;
        scEnforce(_cl, n.sc_compiler_get_declared_struct_member_size(_cl,
                structType, index, result));
        return result;
    }

    /// Returns a set of all global variables which are statically accessed
    /// by the control flow graph from the current entry point.
    /// Only variables which change the interface for a shader are returned, that is,
    /// variables with storage class of Input, Output, Uniform, UniformConstant, PushConstant and AtomicCounter
    /// storage classes are returned.
    ///
    /// To use the returned set as the filter for which variables are used during compilation,
    /// this set can be moved to setEnabledInterfaceVariables().
    uint[] getActiveInterfaceVariables() const
    {
        uint[] result = void;
        scEnforce(_cl, n.sc_compiler_get_active_interface_variables(_cl, result));
        return result;
    }

    /// Sets the interface variables which are used during compilation.
    /// By default, all variables are used.
    /// Once set, compile() will only consider the set in active_variables.
    void setEnabledInterfaceVariables(const(uint)[] activeVariables)
    {
        scEnforce(_cl, n.sc_compiler_set_enabled_interface_variables(_cl, activeVariables));
    }

    /// Query shader resources, use ids with reflection interface to modify or query binding points, etc.
    ShaderResources getShaderResources() const
    {
        ShaderResources result = void;
        scEnforce(_cl, n.sc_compiler_get_shader_resources(_cl, result));
        return result;
    }

    /// Query shader resources, but only return the variables which are part of active_variables.
    /// E.g.: get_shader_resources(get_active_variables()) to only return the variables which are statically
    /// accessed.
    ShaderResources getShaderResources(const(uint)[] activeVariables) const
    {
        ShaderResources result = void;
        scEnforce(_cl, n.sc_compiler_get_shader_resources_for_vars(_cl, activeVariables, result));
        return result;
    }

    /// Remapped variables are considered built-in variables and a backend will
    /// not emit a declaration for this variable.
    /// This is mostly useful for making use of builtins which are dependent on extensions.
    void setRemappedVariableState(uint id, bool remapEnable)
    {
        scEnforce(_cl, n.sc_compiler_set_remapped_variable_state(_cl, id, remapEnable));
    }
    /// ditto
    bool getRemappedVariableState(uint id) const
    {
        bool result = void;
        scEnforce(_cl, n.sc_compiler_get_remapped_variable_state(_cl, id, result));
        return result;
    }

    /// For subpassInput variables which are remapped to plain variables,
    /// the number of components in the remapped
    /// variable must be specified as the backing type of subpass inputs are opaque.
    void setSubpassInputRemappedComponents(uint id, uint components)
    {
        scEnforce(_cl, n.sc_compiler_set_subpass_input_remapped_components(_cl, id, components));
    }
    /// ditto
    uint getSubpassInputRemappedComponents(uint id) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_get_subpass_input_remapped_components(_cl, id, result));
        return result;
    }

    /// New variants of entry point query and reflection.
    /// Names for entry points in the SPIR-V module may alias if they belong to different execution models.
    /// To disambiguate, we must pass along with the entry point names the execution model.
    EntryPoint[] getEntryPointsAndStages() const
    {
        EntryPoint[] result = void;
        scEnforce(_cl, n.sc_compiler_get_entry_points_and_stages(_cl, result));
        return result;
    }

    /// ditto
    void setEntryPoint(string entry, spv.ExecutionModel executionModel)
    {
        scEnforce(_cl, n.sc_compiler_set_entry_point(_cl, entry, executionModel));
    }

    /// ditto
    void renameEntryPoint(string old_name, string new_name, spv.ExecutionModel executionModel)
    {
        scEnforce(_cl, n.sc_compiler_rename_entry_point(_cl, old_name, new_name, executionModel));
    }

    /// ditto
    string getCleansedEntryPointName(string name, spv.ExecutionModel executionModel) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_cleansed_entry_point_name(_cl, name,
                executionModel, result));
        return result;
    }

    // const Bitset &get_execution_mode_bitset() const;

    void unsetExecutionMode(spv.ExecutionMode mode)
    {
        scEnforce(_cl, n.sc_compiler_unset_execution_mode(_cl, mode));
    }

    void setExecutionMode(spv.ExecutionMode mode, uint arg0 = 0, uint arg1 = 0, uint arg2 = 0)
    {
        scEnforce(_cl, n.sc_compiler_set_execution_mode(_cl, mode, arg0, arg1, arg2));
    }

    /// Gets argument for an execution mode (LocalSize, Invocations, OutputVertices).
    /// For LocalSize, the index argument is used to select the dimension (X = 0, Y = 1, Z = 2).
    /// For execution modes which do not have arguments, 0 is returned.
    uint getExecutionModeArgument(spv.ExecutionMode mode, uint index = 0) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_get_execution_mode_argument(_cl, mode, index, result));
        return result;
    }
    /// ditto
    spv.ExecutionModel getExecutionModel() const
    {
        spv.ExecutionModel result = void;
        scEnforce(_cl, n.sc_compiler_get_execution_model(_cl, result));
        return result;
    }

    /// In SPIR-V, the compute work group size can be represented by a constant vector, in which case
    /// the LocalSize execution mode is ignored.
    ///
    /// This constant vector can be a constant vector, specialization constant vector, or partly specialized constant vector.
    /// To modify and query work group dimensions which are specialization constants, SPIRConstant values must be modified
    /// directly via get_constant() rather than using LocalSize directly. This function will return which constants should be modified.
    ///
    /// To modify dimensions which are *not* specialization constants, set_execution_mode should be used directly.
    /// Arguments to set_execution_mode which are specialization constants are effectively ignored during compilation.
    /// NOTE: This is somewhat different from how SPIR-V works. In SPIR-V, the constant vector will completely replace LocalSize,
    /// while in this interface, LocalSize is only ignored for specialization constants.
    ///
    /// The specialization constant will be written to x, y and z arguments.
    /// If the component is not a specialization constant, a zeroed out struct will be written.
    /// The return value is the constant ID of the builtin WorkGroupSize, but this is not expected to be useful
    /// for most use cases.
    uint getWorkGroupSizeSpecializationConstants(out SpecializationConstant x,
            out SpecializationConstant y, out SpecializationConstant z) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_get_work_group_size_specialization_constants(_cl,
                x, y, z, result));
        return result;
    }

    /// Analyzes all OpImageFetch (texelFetch) opcodes and checks if there are instances where
    /// said instruction is used without a combined image sampler.
    /// GLSL targets do not support the use of texelFetch without a sampler.
    /// To workaround this, we must inject a dummy sampler which can be used to form a sampler2D at the call-site of
    /// texelFetch as necessary.
    ///
    /// This must be called before buildCombinedImageSamplers().
    /// buildCombinedImageSamplers() may refer to the ID returned by this method if the returned ID is non-zero.
    /// The return value will be the ID of a sampler object if a dummy sampler is necessary, or 0 if no sampler object
    /// is required.
    ///
    /// If the returned ID is non-zero, it can be decorated with set/bindings as desired before calling compile().
    /// Calling this function also invalidates getActiveInterfaceVariables(), so this should be called
    /// before that function.
    uint buildDummySamplerForCombinedImages()
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_build_dummy_sampler_for_combined_images(_cl, result));
        return result;
    }

    /// Analyzes all separate image and samplers used from the currently selected entry point,
    /// and re-routes them all to a combined image sampler instead.
    /// This is required to "support" separate image samplers in targets which do not natively support
    /// this feature, like GLSL/ESSL.
    ///
    /// This must be called before compile() if such remapping is desired.
    /// This call will add new sampled images to the SPIR-V,
    /// so it will appear in reflection if getShaderResources() is called after buildCombinedImageSamplers.
    ///
    /// If any image/sampler remapping was found, no separate image/samplers will appear in the decompiled output,
    /// but will still appear in reflection.
    ///
    /// The resulting samplers will be void of any decorations like name, descriptor sets and binding points,
    /// so this can be added before compile() if desired.
    ///
    /// Combined image samplers originating from this set are always considered active variables.
    /// Arrays of separate samplers are not supported, but arrays of separate images are supported.
    /// Array of images + sampler -> Array of combined image samplers.
    void buildCombinedImageSamplers()
    {
        scEnforce(_cl, n.sc_compiler_build_combined_image_samples(_cl));
    }

    /// Gets a remapping for the combined image samplers.
    CombinedImageSampler[] getCombinedImageSamplers() const
    {
        CombinedImageSampler[] result = void;
        scEnforce(_cl, n.sc_compiler_get_combined_image_samplers(_cl, result));
        return result;
    }

    // void set_variable_type_remap_callback(VariableTypeRemapCallback cb)

    /// API for querying which specialization constants exist.
    /// To modify a specialization constant before compile(), use get_constant(constant.id),
    /// then update constants directly in the SPIRConstant data structure.
    /// For composite types, the subconstants can be iterated over and modified.
    /// constant_type is the SPIRType for the specialization constant,
    /// which can be queried to determine which fields in the unions should be poked at.
    SpecializationConstant[] getSpecializationConstants() const
    {
        SpecializationConstant[] result = void;
        scEnforce(_cl, n.sc_compiler_get_specialization_constants(_cl, result));
        return result;
    }

    // SPIRConstant &get_constant(uint id);
    // const SPIRConstant &get_constant(uint id) const;

    uint getCurrentIdBound() const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_get_current_id_bound(_cl, result));
        return result;
    }

    /// API for querying buffer objects.
    /// The type passed in here should be the base type of a resource, i.e.
    /// getType(resource.baseTypeId)
    /// as decorations are set in the basic Block type.
    /// The type passed in here must have these decorations set, or an exception is raised.
    /// Only UBOs and SSBOs or sub-structs which are part of these buffer types will have these decorations set.
    uint typeStructMemberOffset(const(SPIRType)* type, uint index) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_type_struct_member_offset(_cl, type, index, result));
        return result;
    }

    /// ditto
    uint typeStructMemberArrayStride(const(SPIRType)* type, uint index) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_type_struct_member_array_stride(_cl, type, index, result));
        return result;
    }

    /// ditto
    uint typeStructMemberMatrixStride(const(SPIRType)* type, uint index) const
    {
        uint result = void;
        scEnforce(_cl, n.sc_compiler_type_struct_member_matrix_stride(_cl, type, index, result));
        return result;
    }

    /// Gets the offset in SPIR-V words (uint) for a decoration which was originally declared in the SPIR-V binary.
    /// The offset will point to one or more uint literals which can be modified in-place before using the SPIR-V binary.
    /// Note that adding or removing decorations using the reflection API will not change the behavior of this function.
    /// If the decoration was declared, sets the word_offset to an offset into the provided SPIR-V binary buffer and returns true,
    /// otherwise, returns false.
    /// If the decoration does not have any value attached to it (e.g. DecorationRelaxedPrecision), this function will also return false.
    bool getBinaryOffsetForDecoration(uint id, spv.Decoration decoration, out uint word_offset) const
    {
        bool result = void;
        scEnforce(_cl, n.sc_compiler_get_binary_offset_for_decoration(_cl, id,
                decoration, word_offset, result));
        return result;
    }

    /// HLSL counter buffer reflection interface.
    /// Append/Consume/Increment/Decrement in HLSL is implemented as two "neighbor" buffer objects where
    /// one buffer implements the storage, and a single buffer containing just a lone "int" implements the counter.
    /// To SPIR-V these will be exposed as two separate buffers, but glslang HLSL frontend emits a special indentifier
    /// which lets us link the two buffers together.
    ///
    /// Queries if a variable ID is a counter buffer which "belongs" to a regular buffer object.
    ///
    /// If SPV_GOOGLE_hlsl_functionality1 is used, this can be used even with a stripped SPIR-V module.
    /// Otherwise, this query is purely based on OpName identifiers as found in the SPIR-V module, and will
    /// only return true if OpSource was reported HLSL.
    /// To rely on this functionality, ensure that the SPIR-V module is not stripped.
    bool bufferIsHlslCounterBuffer(uint id) const
    {
        bool result = void;
        scEnforce(_cl, n.sc_compiler_buffer_is_hlsl_counter_buffer(_cl, id, result));
        return result;
    }

    /// Queries if a buffer object has a neighbor "counter" buffer.
    /// If so, the ID of that counter buffer will be returned in counter_id.
    /// If SPV_GOOGLE_hlsl_functionality1 is used, this can be used even with a stripped SPIR-V module.
    /// Otherwise, this query is purely based on OpName identifiers as found in the SPIR-V module, and will
    /// only return true if OpSource was reported HLSL.
    /// To rely on this functionality, ensure that the SPIR-V module is not stripped.
    bool bufferGetHlslCounterBuffer(uint id, out uint counterId)
    {
        bool result = void;
        scEnforce(_cl, n.sc_compiler_buffer_get_hlsl_counter_buffer(_cl, id, counterId, result));
        return result;
    }

    /// Gets the list of all SPIR-V Capabilities which were declared in the SPIR-V module.
    spv.Capability[] getDeclaredCapabilities() const
    {
        spv.Capability[] result = void;
        scEnforce(_cl, n.sc_compiler_get_declared_capabilities(_cl, result));
        return result;
    }

    /// Gets the list of all SPIR-V extensions which were declared in the SPIR-V module.
    string[] getDeclaredExtensions() const
    {
        string[] result = void;
        scEnforce(_cl, n.sc_compiler_get_declared_extensions(_cl, result));
        return result;
    }

    /// When declaring buffer blocks in GLSL, the name declared in the GLSL source
    /// might not be the same as the name declared in the SPIR-V module due to naming conflicts.
    /// In this case, SPIRV-Cross needs to find a fallback-name, and it might only
    /// be possible to know this name after compiling to GLSL.
    /// This is particularly important for HLSL input and UAVs which tends to reuse the same block type
    /// for multiple distinct blocks. For these cases it is not possible to modify the name of the type itself
    /// because it might be unique. Instead, you can use this interface to check after compilation which
    /// name was actually used if your input SPIR-V tends to have this problem.
    /// For other names like remapped names for variables, etc, it's generally enough to query the name of the variables
    /// after compiling, block names are an exception to this rule.
    /// ID is the name of a variable as returned by Resource::id, and must be a variable with a Block-like type.
    ///
    /// This also applies to HLSL cbuffers.
    string getRemappedDeclaredBlockName(uint id) const
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_get_remapped_declared_block_name(_cl, id, result));
        return result;
    }

    //Bitset get_buffer_block_flags(uint id) const;
}

/// Compiler that produces Glsl code
class ScCompilerGlsl : ScCompiler
{

    private @property inout(n.ScCompilerGlsl)* glsl() inout
    {
        return cast(inout(n.ScCompilerGlsl)*) _cl;
    }

    this(in uint[] ir)
    {
        n.ScCompilerGlsl* cl;
        string msg;
        const res = n.sc_compiler_glsl_new(ir, n.gcCallbacks, cl, msg);
        scEnforce(res, msg);
        super(cast(n.ScCompiler*) cl);
    }

    @property ScOptionsGlsl options() const
    {
        ScOptionsGlsl opts;
        n.sc_compiler_glsl_get_options(glsl, opts);
        return opts;
    }

    @property void options(ScOptionsGlsl opts)
    {
        n.sc_compiler_glsl_set_options(glsl, &opts);
    }

    /// Returns the current string held in the conversion buffer. Useful for
    /// capturing what has been converted so far when compile() throws an error.
    string getPartialSource()
    {
        string result = void;
        scEnforce(_cl, n.sc_compiler_glsl_get_partial_source(glsl, result));
        return result;
    }

    /// Adds a line to be added right after #version in GLSL backend.
    /// This is useful for enabling custom extensions which are outside the scope of SPIRV-Cross.
    /// This can be combined with variable remapping.
    /// A new-line will be added.
    ///
    /// While addHeaderLine() is a more generic way of adding arbitrary text to the header
    /// of a GLSL file, requireExtension() should be used when adding extensions since it will
    /// avoid creating collisions with SPIRV-Cross generated extensions.
    ///
    /// Code added via add_header_line() is typically backend-specific.
    void addHeaderLine(string str)
    {
        scEnforce(_cl, n.sc_compiler_glsl_add_header_line(glsl, str));
    }

    /// Adds an extension which is required to run this shader, e.g.
    /// require_extension("GL_KHR_my_extension");
    void requireExtension(string ext)
    {
        scEnforce(_cl, n.sc_compiler_glsl_require_extension(glsl, ext));
    }

    /// Legacy GLSL compatibility method.
    /// Takes a uniform or push constant variable and flattens it into a (i|u)vec4 array[N]; array instead.
    /// For this to work, all types in the block must be the same basic type, e.g. mixing vec2 and vec4 is fine, but
    /// mixing int and float is not.
    /// The name of the uniform array will be the same as the interface block name.
    void flattenBufferBlock(uint id)
    {
        scEnforce(_cl, n.sc_compiler_glsl_flatten_buffer_block(glsl, id));
    }

}
