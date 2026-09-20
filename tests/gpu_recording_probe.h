#pragma once
#include "sdl3_gpu_recording.h"
#include "gpu_pixel_reference.h"
#include <thread>
namespace sdl3_test {
inline int gpu_recordings() { return int(SDL_GPURecordings.size()+SDL_GPURecordingPasses.size()); }
inline bool gpu_recording_pixels(const das::TArray<uint8_t> & bytes,bool linear) {
    return gpu_bindings_pixels_reference(bytes,linear,true);
}
inline bool gpu_recording_values(SDL_GPUDevice * device,uint64_t command) {
    auto * c=SDL_GPURecordingFind(device,command); if (!c || !c->command) return false;
    float values[4]={1,1,1,1}; das::TArray<uint8_t> bytes{};
    bytes.data=reinterpret_cast<char *>(values);
    for (uint64_t size:{uint64_t(0),uint64_t(15),uint64_t(16385),uint64_t(UINT32_MAX)+1}) {
        bytes.size=size;
        if (SDL_PushGPUUniformBytesChecked(device,command,SDL_GPU_SHADERSTAGE_VERTEX,0,bytes)) return false;
    }
    bytes.size=16;
    if (SDL_PushGPUUniformBytesChecked(device,command,SDL_GPUShaderStage(9),0,bytes) ||
        SDL_PushGPUUniformBytesChecked(device,command,SDL_GPU_SHADERSTAGE_VERTEX,4,bytes)) return false;
    bool rejected=false;
    std::thread worker([&] {
        rejected=!SDL_PushGPUUniformBytesChecked(device,command,SDL_GPU_SHADERSTAGE_VERTEX,0,bytes)
            && !SDL_GPURecordingDiscard(device,command);
    }); worker.join();
    // Exercise the public byte path in an unused slot; required fragment slot remains missing.
    return rejected && SDL_PushGPUUniformBytesChecked(device,command,SDL_GPU_SHADERSTAGE_VERTEX,3,bytes);
}
inline bool recording_fail_submit(SDL_GPUCommandBuffer * command) {
    SDL_CancelGPUCommandBuffer(command); return SDL_SetError("injected recording submit failure");
}
inline bool gpu_recording_failure(SDL_GPUDevice * device,uint64_t target) {
    const auto command=SDL_AcquireGPUCommandBufferChecked(device); if (!command) return false;
    const SDL_FColor black{0,0,0,1};
    const auto pass=SDL_BeginGPURenderPassChecked(device,command,target,{0,0},SDL_GPU_LOADOP_LOAD,black);
    if (!pass) { SDL_GPURecordingDiscard(device,command); return false; }
    if (!SDL_EndGPURenderPassChecked(device,pass)) { SDL_GPURecordingDiscard(device,command); return false; }
    const bool failed=!SDL_SubmitGPUCommandBufferCheckedWithAPI(device,command,recording_fail_submit);
    auto & t=SDL_GPUTransferTextures.at(target);
    const bool invalid=!t.valid[0];
    t.valid[0]=true; // Injection canceled without changing the real texture.
    return failed && invalid && !SDL_GPURecordings.count(command);
}
inline bool gpu_recording_devices(SDL_GPUDevice * first,uint64_t target) {
    const int before=gpu_recordings();
    const auto a=SDL_AcquireGPUCommandBufferChecked(first); if (!a) return false;
    auto * second=SDL_CreateGPUDeviceScoped(SDL_GetGPUShaderFormats(first),true,SDL_GetGPUDeviceDriver(first));
    if (!second) { SDL_GPURecordingDiscard(first,a); return false; }
    const auto texture=SDL_CreateGPUColorTargetTexture(second,8,8,1,1,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM);
    const auto b=SDL_AcquireGPUCommandBufferChecked(second);
    const SDL_FColor black{0,0,0,1};
    bool ok=texture && b && !SDL_SubmitGPUCommandBufferChecked(second,a) &&
        !SDL_BeginGPURenderPassChecked(second,b,target,{0,0},SDL_GPU_LOADOP_LOAD,black);
    const auto pass=texture && b ? SDL_BeginGPURenderPassChecked(second,b,texture,{0,0},SDL_GPU_LOADOP_CLEAR,black) : 0;
    ok=ok && pass;
    // Device cleanup must end/cancel B before its texture is released, and preserve A.
    ok=SDL_DestroyGPUDeviceScoped(second) && ok;
    ok=ok && SDL_GPURecordings.count(a) && !SDL_GPURecordings.count(b) && !SDL_GPURecordingPasses.count(pass);
    ok=SDL_CancelGPUCommandBufferChecked(first,a) && ok;
    return ok && gpu_recordings()==before;
}
}
