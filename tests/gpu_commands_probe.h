#pragma once
#include "sdl3_gpu_commands.h"
namespace sdl3_test {
inline int gpu_plans() { return int(SDL_GPUCommandPlans.size()); }
struct GPUPlanFault {
    inline static int mode=0, acquisitions=0, begins=0, submits=0, cancels=0;
    static SDL_GPUCommandBuffer * SDLCALL acquire(SDL_GPUDevice * device) {
        ++acquisitions;
        if (mode==1) { SDL_SetError("plan acquire fault"); return nullptr; }
        return SDL_AcquireGPUCommandBuffer(device);
    }
    static SDL_GPUCopyPass * SDLCALL begin(SDL_GPUCommandBuffer * command) {
        ++begins;
        if ((mode==2 && begins==1) || (mode==3 && begins==2)) { SDL_SetError("plan begin fault"); return nullptr; }
        return SDL_BeginGPUCopyPass(command);
    }
    static bool SDLCALL cancel(SDL_GPUCommandBuffer * command) {
        ++cancels; return SDL_CancelGPUCommandBuffer(command);
    }
    static bool SDLCALL submit(SDL_GPUCommandBuffer * command) {
        ++submits;
        if (mode==4) { SDL_CancelGPUCommandBuffer(command); return SDL_SetError("plan submit fault"); }
        return SDL_SubmitGPUCommandBuffer(command);
    }
};
inline bool gpu_plan_faults(SDL_GPUDevice * device,uint64_t source,uint64_t destination) {
    const SDL_GPUPlanAPI api{GPUPlanFault::acquire,GPUPlanFault::begin,GPUPlanFault::submit,GPUPlanFault::cancel};
    for (int mode=1;mode<=4;++mode) {
        GPUPlanFault::mode=mode; GPUPlanFault::acquisitions=GPUPlanFault::begins=GPUPlanFault::submits=GPUPlanFault::cancels=0;
        const auto id=SDL_CreateGPUCommandPlan(device);
        const bool groups=SDL_GPUPlanDebugGroupsSupported(device)==1;
        bool ok=id && (!groups || SDL_GPUPlanPushGroup(device,id,"fault scope")) &&
            SDL_GPUPlanCopyBuffer(device,id,source,0,destination,0,4) &&
            SDL_GPUPlanCopyBuffer(device,id,source,4,destination,4,4) && (!groups || SDL_GPUPlanPopGroup(device,id));
        ok=ok && !SDL_SubmitGPUCommandPlanWithAPI(device,id,api) && SDL_GPUCommandPlans.at(id).consumed &&
            GPUPlanFault::acquisitions==1 && GPUPlanFault::submits==(mode==4 ? 1 : 0) &&
            GPUPlanFault::cancels==((mode==2 || mode==3) ? 1 : 0) &&
            SDL_GPUDataBuffers.at(destination).valid==(mode!=4);
        ok=ok && !SDL_SubmitGPUCommandPlanWithAPI(device,id,api) && GPUPlanFault::acquisitions==1;
        SDL_ReleaseGPUCommandPlan(device,id);
        if (!ok) return false;
    }
    // No actual work was submitted; caller must use the public full-update
    // recovery path for the conservatively invalidated destination.
    return true;
}
inline bool gpu_plan_no_acquire(SDL_GPUDevice * device,uint64_t plan) {
    GPUPlanFault::acquisitions=0; GPUPlanFault::mode=1;
    SDL_GPUPlanAPI api{}; api.acquire=GPUPlanFault::acquire;
    return !SDL_SubmitGPUCommandPlanWithAPI(device,plan,api) && GPUPlanFault::acquisitions==0;
}
inline bool gpu_plan_fail_submit(SDL_GPUDevice * device,uint64_t plan) {
    GPUPlanFault::mode=4; GPUPlanFault::submits=0;
    SDL_GPUPlanAPI api{}; api.submit=GPUPlanFault::submit;
    return !SDL_SubmitGPUCommandPlanWithAPI(device,plan,api) && GPUPlanFault::submits==1;
}
inline bool gpu_plan_text_copy(SDL_GPUDevice * device,uint64_t plan) {
    auto * entry=SDL_GPUPlanOpen(device,plan); if (!entry) return false;
    std::string limit(4096,'x'), over(4097,'x');
    const auto size=entry->ops.size();
    if (SDL_GPUPlanLabel(device,plan,over.c_str()) || entry->ops.size()!=size ||
        !SDL_GPUPlanLabel(device,plan,limit.c_str())) return false;
    char text[]="copied label";
    if (!SDL_GPUPlanLabel(device,plan,text)) return false;
    text[0]='X';
    return entry->ops.back().text=="copied label";
}
}
