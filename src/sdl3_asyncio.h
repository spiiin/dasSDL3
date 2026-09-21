#pragma once
#include "sdl3_storage.h"
inline bool SDL_GetAsyncIOResultRef(SDL_AsyncIOQueue * queue,SDL_AsyncIOOutcome & outcome) {
    if(SDL_GetAsyncIOResult(queue,&outcome))return true;
    outcome={};return false;
}
inline bool SDL_WaitAsyncIOResultRef(SDL_AsyncIOQueue * queue,SDL_AsyncIOOutcome & outcome,int32_t timeout) {
    if(SDL_WaitAsyncIOResult(queue,&outcome,timeout))return true;
    outcome={};return false;
}
inline bool SDL_CloseAsyncIORef(SDL_AsyncIO *& io,bool flush,SDL_AsyncIOQueue * queue,void * userdata) {
    if(!SDL_CloseAsyncIO(io,flush,queue,userdata))return false;
    io=nullptr;return true;
}
// Requires an unmodified, exclusively owned LoadFileAsync READ outcome.
// Outcome copies alias the same buffer: this is explicit consumption, not shared ownership.
inline bool SDL_TakeAsyncFileBytes(SDL_AsyncIOOutcome & outcome,das::TArray<uint8_t> & bytes,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(bytes,0,1,ctx,at);
    if(outcome.asyncio || outcome.type!=SDL_ASYNCIO_TASK_READ || !outcome.buffer)
        return SDL_SetError("Expected an unconsumed SDL_LoadFileAsync read outcome");
    std::unique_ptr<void,decltype(&SDL_free)> owned(outcome.buffer,SDL_free);
    outcome.buffer=nullptr;
    if(outcome.result!=SDL_ASYNCIO_COMPLETE)
        return SDL_SetError(outcome.result==SDL_ASYNCIO_CANCELED ? "Async file load canceled" : "Async file load failed");
    if(outcome.bytes_transferred>outcome.bytes_requested || outcome.bytes_transferred>INT_MAX)
        return SDL_SetError("Async file result exceeds script array range");
    das::builtin_array_resize(bytes,int(outcome.bytes_transferred),1,ctx,at);
    if(outcome.bytes_transferred)SDL_memcpy(bytes.data,owned.get(),size_t(outcome.bytes_transferred));
    return true;
}
