"""Consuming builders reject ignored results and references to temporary results."""
from pathlib import Path
import subprocess
import sys
import tempfile

cases = [
    ('gpu_pipeline(GpuShaderHandle(0ul), GpuShaderHandle(0ul))', 'depth_write(true)'),
    ('gpu_shader("x", SDL_GPU_SHADERFORMAT_SPIRV, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)', 'samplers(1u)'),
    ('gpu_texture(1u, 1u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER)', 'mip_levels(1u)'),
    ('gpu_sampler()', 'anisotropy(2.0)'),
    ('gpu_compute_pipeline(SDL_GPU_SHADERFORMAT_SPIRV)', 'threadgroup(1u, 1u, 1u)'),
    ('window_options("test", int2(100, 100))', 'window_flags(SDL_WINDOW_HIDDEN)'),
    ('gpu_graphics_pipeline_info()', 'depth_write(true)'),
    ('gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)', 'color_write_mask(uint8(7))'),
]
header = '''options gen2
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_gpu_pipeline_boost
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_window_boost
[export]
def main(unused : bool) : int {
'''
with tempfile.TemporaryDirectory(prefix='sdl-builder-errors-') as temp:
    for index, (constructor, setter) in enumerate(cases):
        script = Path(temp) / f'discard_{index}.das'
        script.write_text(header + f'    var value <- {constructor}\n    value |> {setter}\n    return 0\n}}\n', encoding='utf-8')
        result = subprocess.run([sys.argv[1], str(script)], capture_output=True, text=True, timeout=30)
        if result.returncode == 0 or 'error[30166]' not in result.stdout + result.stderr:
            raise SystemExit(f'Expected nodiscard rejection for {setter}:\n{result.stdout}{result.stderr}')
    script = Path(temp) / 'temporary_ref.das'
    script.write_text(header + '    var ref : GpuGraphicsPipelineOptions& = gpu_pipeline(GpuShaderHandle(0ul), GpuShaderHandle(0ul)) |> depth_write(true)\n    print("{ref.info.depth_stencil_state.enable_depth_write}\\n")\n    return 0\n}\n', encoding='utf-8')
    result = subprocess.run([sys.argv[1], str(script)], capture_output=True, text=True, timeout=30)
    if result.returncode == 0 or 'error[31019]' not in result.stdout + result.stderr:
        raise SystemExit(f'Expected temporary reference rejection:\n{result.stdout}{result.stderr}')
print('Builder discarded results and dangling temporary references rejected (9 cases)')
