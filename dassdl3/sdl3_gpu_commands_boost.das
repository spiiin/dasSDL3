// Value-only planning scope. Submission is explicit; scope exit discards unsubmitted work.
options gen2
module sdl3_gpu_commands_boost shared public
require dassdl3/sdl3_gpu_image_boost public

def public with_gpu_command_plan(device : SDL_GPUDevice?;
        blk : block<(plan : uint64) : void>) {
    let id = SDL_CreateGPUCommandPlan(device)
    if (id == 0ul) { panic("GPU plan create: {SDL_GetError()}") }
    SDL_ScopeReleaseGPUCommandPlan(device,id,blk)
}

def public gpu_plan_copy_buffer(device : SDL_GPUDevice?; plan, source : uint64; source_offset : uint; destination : uint64; dest_offset, size : uint) {
    if (!SDL_GPUPlanCopyBuffer(device,plan,source,source_offset,destination,dest_offset,size)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_plan_copy_texture(device : SDL_GPUDevice?; plan, source : uint64; source_sub : uint2; source_rect : uint4; destination : uint64; dest_sub, dest_origin : uint2) {
    if (!SDL_GPUPlanCopyTexture(device,plan,source,source_sub,source_rect,destination,dest_sub,dest_origin)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_plan_mipmaps(device : SDL_GPUDevice?; plan, texture : uint64) {
    if (!SDL_GPUPlanMipmaps(device,plan,texture)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_plan_blit(device : SDL_GPUDevice?; plan, source : uint64; source_sub : uint2; source_rect : uint4; destination : uint64; dest_sub : uint2; dest_rect : uint4; filter_mode : uint = SDL_GPU_FILTER_NEAREST) {
    if (!SDL_GPUPlanBlit(device,plan,source,source_sub,source_rect,destination,dest_sub,dest_rect,filter_mode)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_plan_label(device : SDL_GPUDevice?; plan : uint64; text : string) {
    if (!SDL_GPUPlanLabel(device,plan,text)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_plan_push_group(device : SDL_GPUDevice?; plan : uint64; text : string) {
    if (!SDL_GPUPlanPushGroup(device,plan,text)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_plan_pop_group(device : SDL_GPUDevice?; plan : uint64) {
    if (!SDL_GPUPlanPopGroup(device,plan)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_submit_plan(device : SDL_GPUDevice?; plan : uint64) {
    if (!SDL_SubmitGPUCommandPlan(device,plan)) { panic("GPU plan: {SDL_GetError()}") }
}

def public gpu_plan_debug_groups_supported(device : SDL_GPUDevice?) : bool {
    let supported = SDL_GPUPlanDebugGroupsSupported(device)
    if (supported < 0) { panic("GPU plan: {SDL_GetError()}") }
    return supported == 1
}
