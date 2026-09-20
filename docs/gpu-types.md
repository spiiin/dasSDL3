# Generated GPU types

Pinned SDL 3.2.18, Windows x64. Both generators use tools/bindings.json for
selection/aliases. All 24 named SDL_GPU enums (230 values), GPU opaque handles,
value records and selected pointer-bearing descriptors are exposed. Current
selection is recorded in src/generated; no historical batch total is authoritative.

Use typed values such as SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM in
typed fields. Flat uint constants remain for older checked helpers; flags stay
bitmasks, including Uint8 color_write_mask. SDL_GPUTextureCreateInfo.type is
aliased to texture_type. Padding is hidden. Zero initialization does not make a
valid descriptor: required formats/dimensions/state and reserved fields matter.

Enums are checked for supported width/range; generated C++ asserts enum values,
sizeof/alignof/offsetof against the compiler. Field-type dependencies determine
annotation registration order. Pointee-const fields are not assignable in pinned
daScript: use [creation/array adapters](gpu-native-boost.md), not disabled pointer
checks. Raw field visibility is not ownership or lifetime validation.

Examples 37–38 demonstrate descriptors without a GPU. Tests gpu_types,
gpu_pipeline_types, gpu_typed_queries and test_gpu_type_errors.py cover values,
leaf fields, nested copies, typed assignments, hidden padding and real queries.
Metadata parity checks aliases, qualifiers, enum values, sizes and offsets.
Broader raw/runtime verification: [gpu-raw-tests.md](gpu-raw-tests.md).
