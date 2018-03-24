module spirv_cross;


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
