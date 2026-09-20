# GPU pipeline descriptors

See [generated GPU types](gpu-types.md) for the shared ABI policy.
SDL_GPUSamplerCreateInfo, SDL_GPUStencilOpState, SDL_GPUColorTargetBlendState,
SDL_GPUTransferBufferCreateInfo, SDL_GPUDepthStencilState and
SDL_GPUColorTargetDescription are editable value records with hidden padding.
Shader/graphics/compute create-info records additionally expose native fields.

Descriptor creation alone does not validate shader ABI, usage or resource lifetime.
Generated raw create/release calls follow SDL ownership; use the creating device,
release once and never use stale pointers. SDL defers physical destruction for
submitted work. Defaults and scopes are separate conveniences.

- [Native pointer creation from arrays/files](gpu-native-boost.md).
- Checked IDs: [samplers](gpu-samplers.md), [shaders](gpu-shaders.md), [pipelines](gpu-pipelines.md).
- Example [38](../examples/38_gpu_pipeline_descriptors.das) and tests/gpu_pipeline_types.das:
  nested leaf fields, array copies and enum assignments.
- tests/gpu_typed_queries.das checks actual raw sampler creation; recording and
  native adapter tests additionally validate sampled pixels and attachments.
