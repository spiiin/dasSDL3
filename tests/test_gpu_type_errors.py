"""Typed GPU fields reject cross-enum/numeric assignments and hidden padding."""
from pathlib import Path
import subprocess
import sys
import tempfile

cases = [
    ('SDL_GPUGraphicsPipelineCreateInfo', 'value.vertex_shader = null', None),
    ('SDL_GPUGraphicsPipelineCreateInfo', 'value.vertex_input_state.num_vertex_buffers = 1u', None),
    # Pinned daScript preserves const pointer fields as non-assignable views.
    ('SDL_GPUGraphicsPipelineCreateInfo', 'value.target_info.color_target_descriptions = null', 'error[30952]'),
    ('SDL_GPUGraphicsPipelineTargetInfo', 'value.num_color_targets = 1u', None),
    ('SDL_GPUGraphicsPipelineCreateInfo', 'value.primitive_type = SDL_GPUCullMode.CULLMODE_NONE', 'error[30915]'),
    ('SDL_GPUShaderCreateInfo', 'value.stage = SDL_GPUFilter.FILTER_LINEAR', 'error[30915]'),
    ('SDL_GPUShaderCreateInfo', 'value.code = null', 'error[30952]'),
    ('SDL_GPUShaderCreateInfo', 'value.entrypoint = null', 'error[30915]'),
    ('SDL_GPUShaderCreateInfo', 'value.code_size = 1ul', None),
    ('SDL_GPUDepthStencilState', 'value.front_stencil_state.fail_op = SDL_GPUCompareOp.COMPAREOP_ALWAYS', 'error[30915]'),
    ('SDL_GPUColorTargetDescription', 'value.blend_state.padding1 = uint8(1)', 'error[30928]'),
    ('SDL_GPUSamplerCreateInfo', 'value.min_filter = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR', 'error[30915]'),
    ('SDL_GPUTextureCreateInfo', 'value.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM', 'error[30915]'),
    ('SDL_GPUTextureCreateInfo', 'value.sample_count = SDL_GPUTextureType.TEXTURETYPE_2D', 'error[30915]'),
    ('SDL_GPURasterizerState', 'value.padding1 = uint8(1)', 'error[30928]'),
]
with tempfile.TemporaryDirectory(prefix='sdl-gpu-type-errors-') as temp:
    for index, (record, statement, diagnostic) in enumerate(cases):
        script = Path(temp) / f'bad_{index}.das'
        script.write_text('options gen2\nrequire sdl3\n[export]\ndef main(smoke : bool) : int {\n'
                          f'    var value : {record}\n    {statement}\n    return 0\n}}\n', encoding='utf-8')
        result = subprocess.run([sys.argv[1], str(script), '--smoke-test'], capture_output=True, text=True)
        output = result.stdout + result.stderr
        if diagnostic is None:
            if result.returncode != 0:
                raise SystemExit(f'Expected exposed field to compile: {statement}:\n{output}')
            continue
        if result.returncode == 0 or diagnostic not in output:
            raise SystemExit(f'Expected typed-field rejection for {statement}:\n{output}')
print('Exposed fields compile; numeric/cross-enum assignment and hidden padding reject')
