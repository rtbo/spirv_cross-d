module spirv_cross;

import spirv_cross.native : SpvResult;

enum SpvExecutionModel {
    Vertex = 0,
    TessellationControl = 1,
    TessellationEvaluation = 2,
    Geometry = 3,
    Fragment = 4,
    GLCompute = 5,
    Kernel = 6,
    Max = 0x7fffffff,
}

enum SpvDecoration {
    RelaxedPrecision = 0,
    SpecId = 1,
    Block = 2,
    BufferBlock = 3,
    RowMajor = 4,
    ColMajor = 5,
    ArrayStride = 6,
    MatrixStride = 7,
    GLSLShared = 8,
    GLSLPacked = 9,
    CPacked = 10,
    BuiltIn = 11,
    NoPerspective = 13,
    Flat = 14,
    Patch = 15,
    Centroid = 16,
    Sample = 17,
    Invariant = 18,
    Restrict = 19,
    Aliased = 20,
    Volatile = 21,
    Constant = 22,
    Coherent = 23,
    NonWritable = 24,
    NonReadable = 25,
    Uniform = 26,
    SaturatedConversion = 28,
    Stream = 29,
    Location = 30,
    Component = 31,
    Index = 32,
    Binding = 33,
    DescriptorSet = 34,
    Offset = 35,
    XfbBuffer = 36,
    XfbStride = 37,
    FuncParamAttr = 38,
    FPRoundingMode = 39,
    FPFastMathMode = 40,
    LinkageAttributes = 41,
    NoContraction = 42,
    InputAttachmentIndex = 43,
    Alignment = 44,
    MaxByteOffset = 45,
    AlignmentId = 46,
    MaxByteOffsetId = 47,
    ExplicitInterpAMD = 4999,
    OverrideCoverageNV = 5248,
    PassthroughNV = 5250,
    ViewportRelativeNV = 5252,
    SecondaryViewportRelativeNV = 5256,
    HlslCounterBufferGOOGLE = 5634,
    HlslSemanticGOOGLE = 5635,
    Max = 0x7fffffff,
}

struct SpvEntryPoint
{
    string name;
    SpvExecutionModel execution_model;
    uint work_group_size_x;
    uint work_group_size_y;
    uint work_group_size_z;
}

struct SpvResource
{
    uint id;
    uint type_id;
    uint base_type_id;
    string name;
}

struct SpvShaderResources
{
    SpvResource[] uniform_buffers;
    SpvResource[] storage_buffers;
    SpvResource[] stage_inputs;
    SpvResource[] stage_outputs;
    SpvResource[] subpass_inputs;
    SpvResource[] storage_images;
    SpvResource[] sampled_images;
    SpvResource[] atomic_counters;
    SpvResource[] push_constant_buffers;
    SpvResource[] separate_images;
    SpvResource[] separate_samplers;
}


struct SpvSpecializationConstant
{
    uint id;
    uint constant_id;
}

enum SpvBaseType
{
    Unknown,
    Void,
    Boolean,
    Char,
    Int,
    UInt,
    Int64,
    UInt64,
    AtomicCounter,
    Half,
    Float,
    Double,
    Struct,
    Image,
    SampledImage,
    Sampler
}

struct SpvType
{
    SpvBaseType type;
    uint[] members;
    uint[] array;
}

enum SpvGlslPrecision
{
    DontCare,
    LowP,
    MediumP,
    HighP,
}

struct SpvGlslCompilerOptions
{
    uint ver;
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
}

struct SpvHlslRootConstant
{
    uint start;
    uint end;
    uint binding;
    uint space;
}

struct SpvHlslCompilerOptions
{
    uint shader_model;
    bool vertex_transform_clip_space;
    bool vertex_invert_y;
}

struct SpvMslVertexAttr
{
	uint location = 0;
	uint msl_buffer = 0;
	uint msl_offset = 0;
	uint msl_stride = 0;
	bool per_instance = false;
	bool used_by_shader = false;
}

struct SpvMslResourceBinding
{
	SpvExecutionModel stage;
	uint desc_set = 0;
	uint binding = 0;

	uint msl_buffer = 0;
	uint msl_texture = 0;
	uint msl_sampler = 0;

	bool used_by_shader = false;
}

struct SpvMslCompilerOptions
{
    bool vertex_transform_clip_space;
    bool vertex_invert_y;
}

private void spvEnforce(SpvResult res, string msg)
{
    if (res != SpvResult.Success) {
        throw new Exception(msg);
    }
}

abstract class SpvCompiler
{
    import n = spirv_cross.native;

    private n.SpvCompiler* _cl;

    private this (n.SpvCompiler* cl) {
        _cl = cl;
    }

    ~this() {
        dispose();
    }

    void dispose() {
        if (_cl) {
            n.spv_compiler_delete(_cl);
            _cl = null;
        }
    }

    uint getDecoration(in uint id, in SpvDecoration decoration) const {
        uint result = void;
        string msg = void;
        const res = n.spv_compiler_get_decoration(
            _cl, id, decoration, result, msg
        );
        spvEnforce(res, msg);
        return result;
    }

    void setDecoration(in uint id, in SpvDecoration decoration, in uint arg) {
        string msg = void;
        const res = n.spv_compiler_set_decoration(
            _cl, id, decoration, arg, msg
        );
        spvEnforce(res, msg);
    }

    @property SpvEntryPoint[] entryPoints() const {
        SpvEntryPoint[] ep = void;
        string msg = void;
        const res = n.spv_compiler_get_entry_points(
            _cl, ep, msg
        );
        spvEnforce(res, msg);
        return ep;
    }

    string getCleansedEntryPointName(in string originalEntryPointName,
                                     in SpvExecutionModel executionModel) const
    {
        string compiledEntryPointName = void;
        string msg = void;
        const res = n.spv_compiler_get_cleansed_entry_point_name(
            _cl, originalEntryPointName, executionModel, compiledEntryPointName, msg
        );
        spvEnforce(res, msg);
        return compiledEntryPointName;
    }

    @property SpvShaderResources shaderResources() const
    {
        SpvShaderResources resources;
        string msg = void;
        const res = n.spv_compiler_get_shader_resources(
            _cl, resources, msg
        );
        spvEnforce(res, msg);
        return resources;
    }

    @property SpvSpecializationConstant[] specializationConstants()
    {
        SpvSpecializationConstant[] constants = void;
        string msg = void;
        const res = n.spv_compiler_get_specialization_constants(
            _cl, constants, msg
        );
        spvEnforce(res, msg);
        return constants;
    }

    void setScalarConstant(in uint id, in ulong constant)
    {
        string msg = void;
        const res = n.spv_compiler_set_scalar_constant(
            _cl, id, constant, msg
        );
        spvEnforce(res, msg);
    }

    SpvType getType(in uint id)
    {
        SpvType type;
        string msg = void;
        const res = n.spv_compiler_get_type(
            _cl, id, type, msg
        );
        spvEnforce(res, msg);
        return type;
    }

    string getMemberName(in uint id, in uint index)
    {
        string name = void;
        string msg = void;
        const res = n.spv_compiler_get_member_name(
            _cl, id, index, name, msg
        );
        spvEnforce(res, msg);
        return name;
    }

    uint getMemberDecoration(in uint id, in uint index, in SpvDecoration dec)
    {
        uint result = void;
        string msg = void;
        const res = n.spv_compiler_get_member_decoration(
            _cl, id, index, dec, result, msg
        );
        spvEnforce(res, msg);
        return result;
    }

    void setMemberDecoration(in uint id, in uint index, in SpvDecoration dec, in uint arg)
    {
        string msg = void;
        const res = n.spv_compiler_set_member_decoration(
            _cl, id, index, dec, arg, msg
        );
        spvEnforce(res, msg);
    }

    size_t getDeclaredStructSize(in uint id)
    {
        uint result = void;
        string msg = void;
        const res = n.spv_compiler_get_declared_struct_size(
            _cl, id, result, msg
        );
        spvEnforce(res, msg);
        return cast(size_t)result;
    }

    size_t getDeclaredStructMemberSize(in uint id, in uint index)
    {
        uint result = void;
        string msg = void;
        const res = n.spv_compiler_get_declared_struct_member_size(
            _cl, id, index, result, msg
        );
        spvEnforce(res, msg);
        return cast(size_t)result;
    }

    void renameInterfaceVariable(in SpvResource[] resources, in uint location, in string name)
    {
        string msg = void;
        const res = n.spv_compiler_rename_interface_variable(
            _cl, resources, location, name, msg
        );
        spvEnforce(res, msg);
    }

    string compile() {
        string shader;
        string msg;
        const res = n.spv_compiler_compile(_cl, shader, msg);
        spvEnforce(res, msg);
        return shader;
    }
}

class SpvCompilerGlsl : SpvCompiler
{
    import n = spirv_cross.native;

    private @property inout(n.SpvCompilerGlsl)* glsl() inout
    {
        return cast(inout(n.SpvCompilerGlsl)*)_cl;
    }

    this(in uint[] ir) {
        n.SpvCompilerGlsl *cl;
        string msg;
        const res = n.spv_compiler_glsl_new(ir, cl, msg);
        super(cast(n.SpvCompiler*)cl);
    }

    @property SpvGlslCompilerOptions options() const {
        SpvGlslCompilerOptions opts;
        n.spv_compiler_glsl_get_options(glsl, &opts);
        return opts;
    }

    @property void options(SpvGlslCompilerOptions opts) {
        n.spv_compiler_glsl_set_options(glsl, &opts);
    }

    void buildCombinedImageSamplers() {
        string msg = void;
        const res = n.spv_compiler_glsl_build_combined_image_samplers(glsl, msg);
        spvEnforce(res, msg);
    }
}

class SpvCompilerHlsl : SpvCompiler
{
    import n = spirv_cross.native;

    private @property inout(n.SpvCompilerHlsl)* hlsl() inout
    {
        return cast(inout(n.SpvCompilerHlsl)*)_cl;
    }

    this(in uint[] ir) {
        n.SpvCompilerHlsl *cl;
        string msg;
        const res = n.spv_compiler_hlsl_new(ir, cl, msg);
        super(cast(n.SpvCompiler*)cl);
    }

    @property SpvHlslCompilerOptions options() const {
        SpvHlslCompilerOptions opts;
        n.spv_compiler_hlsl_get_options(hlsl, &opts);
        return opts;
    }

    @property void options(SpvHlslCompilerOptions opts) {
        n.spv_compiler_hlsl_set_options(hlsl, &opts);
    }

    void setRootConstantLayout(in SpvHlslRootConstant[] constants) {
        n.spv_compiler_hlsl_set_root_constant_layout(hlsl, constants);
    }
}

class SpvCompilerMsl : SpvCompiler
{
    import n = spirv_cross.native;

    private @property inout(n.SpvCompilerMsl)* msl() inout
    {
        return cast(inout(n.SpvCompilerMsl)*)_cl;
    }

    this(in uint[] ir) {
        n.SpvCompilerMsl *cl;
        string msg;
        const res = n.spv_compiler_msl_new(ir, cl, msg);
        super(cast(n.SpvCompiler*)cl);
    }

    @property SpvMslCompilerOptions options() const {
        SpvMslCompilerOptions opts;
        n.spv_compiler_msl_get_options(msl, &opts);
        return opts;
    }

    @property void options(SpvMslCompilerOptions opts) {
        n.spv_compiler_msl_set_options(msl, &opts);
    }

    string compiler(in SpvMslVertexAttr[] vat_overrides,
                    in SpvMslResourceBinding[] res_overrides)
    {
        string shader = void;
        string msg = void;
        const res = n.spv_compiler_msl_compile(
            msl, vat_overrides, res_overrides, shader, msg
        );
        spvEnforce(res, msg);
        return shader;
    }
}
