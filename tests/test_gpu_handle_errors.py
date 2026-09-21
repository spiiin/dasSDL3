"""Distinct IDs must reject accidental cross-kind use before executing SDL."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

KINDS = ('Buffer', 'IndexBuffer', 'Texture', 'Volume', 'Readback', 'Shader',
         'Sampler', 'Pipeline', 'CommandBuffer', 'RenderPass')
CASES = {
    'integer': 'SDL_ReleaseGPUDataBuffer(null,0ul)',
    'pointer': 'var p : SDL_GPUBuffer?; SDL_ReleaseGPUDataBuffer(null,p)',
    'buffer_as_texture': 'SDL_ReleaseGPUTransferTexture(null,GpuBufferHandle(1ul))',
    'command_as_pass': 'SDL_EndGPURenderPassChecked(null,GpuCommandBufferHandle(1ul))',
    'boost': 'gpu_wait_readback(null,GpuTextureHandle(1ul))',
    'integer_array': 'var a : array<uint64>; var offsets : array<uint>; SDL_BindGPUVertexBuffersChecked(null,GpuRenderPassHandle(0ul),0u,a,offsets)',
    'wrong_array': 'var a : array<GpuTextureHandle>; var offsets : array<uint>; SDL_BindGPUVertexBuffersChecked(null,GpuRenderPassHandle(0ul),0u,a,offsets)',
    'result_payload': 'let value=ok(GpuTextureHandle(1ul),type<SdlError>) |> sdl_try; SDL_ReleaseGPUDataBuffer(null,value)',
}
for kind in KINDS[1:]:
    CASES['buffer_vs_' + kind] = f'SDL_ReleaseGPUDataBuffer(null,Gpu{kind}Handle(1ul))'

def main():
    runner = str(Path(sys.argv[1]).resolve())
    prefix = 'options gen2\nrequire dassdl3/sdl3_gpu_recording_boost\nrequire dassdl3/sdl3_try\n'
    with tempfile.TemporaryDirectory(prefix='sdl3-handle-errors-') as directory:
        # A successful control prevents missing modules or broken runners passing the suite.
        cases = {'valid': 'SDL_ReleaseGPUDataBuffer(null,GpuBufferHandle(0ul))', **CASES}
        for name, body in cases.items():
            script = Path(directory) / (name + '.das')
            script.write_text(prefix + 'def run { ' + body + '; return sdl_ok() }\n[export]\ndef main(smoke : bool) : int { run(); return 0 }\n', encoding='utf-8')
            result = subprocess.run([runner, str(script), '--smoke-test'], capture_output=True, text=True,
                                    timeout=30, env={**os.environ, 'SDL_VIDEODRIVER': 'dummy'})
            output = result.stdout + result.stderr
            if name == 'valid':
                assert result.returncode == 0, output
            else:
                assert result.returncode != 0 and 'error[30341]' in output and 'Gpu' in output, (name, output)
            print(name + ': ' + ('accepted' if name == 'valid' else 'rejected'))

if __name__ == '__main__':
    main()
