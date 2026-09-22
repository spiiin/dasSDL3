#pragma once
#include <SDL3/SDL.h>
inline SDL_Thread * SDL_CreateThreadRuntimeAddress(void * fn,const char * name,void * data,void * begin,void * end) {return SDL_CreateThreadRuntime(reinterpret_cast<SDL_ThreadFunction>(fn),name,data,reinterpret_cast<SDL_FunctionPointer>(begin),reinterpret_cast<SDL_FunctionPointer>(end));}
inline SDL_Thread * SDL_CreateThreadWithPropertiesRuntimeAddress(uint32_t props,void * begin,void * end) {return SDL_CreateThreadWithPropertiesRuntime(props,reinterpret_cast<SDL_FunctionPointer>(begin),reinterpret_cast<SDL_FunctionPointer>(end));}
inline bool SDL_SetTLSAddress(SDL_TLSID * id,const void * value,void * destructor) {return SDL_SetTLS(id,value,reinterpret_cast<SDL_TLSDestructorCallback>(destructor));}
// Invoke SDL macros here so the binding's platform C runtime initializes workers.
inline SDL_Thread * SDL_CreateThreadNative(void * fn,const char * name,void * data) {return SDL_CreateThread(reinterpret_cast<SDL_ThreadFunction>(fn),name,data);}
inline SDL_Thread * SDL_CreateThreadWithPropertiesNative(uint32_t props) {return SDL_CreateThreadWithProperties(props);}
inline int SDL_WaitThreadRef(SDL_Thread * thread) {int status=0;SDL_WaitThread(thread,&status);return status;}
inline void * SDL_GetTLSRef(SDL_TLSID & id) {return SDL_GetTLS(&id);}
inline bool SDL_SetTLSRef(SDL_TLSID & id,const void * value,void * destructor) {return SDL_SetTLSAddress(&id,value,destructor);}
inline bool SDL_TryLockSpinlockRef(SDL_SpinLock & value) {return SDL_TryLockSpinlock(&value);}
inline void SDL_LockSpinlockRef(SDL_SpinLock & value) {return SDL_LockSpinlock(&value);}
inline void SDL_UnlockSpinlockRef(SDL_SpinLock & value) {return SDL_UnlockSpinlock(&value);}
inline bool SDL_CompareAndSwapAtomicIntRef(SDL_AtomicInt & value,int old_value,int new_value) {return SDL_CompareAndSwapAtomicInt(&value,old_value,new_value);}
inline int SDL_SetAtomicIntRef(SDL_AtomicInt & value,int next) {return SDL_SetAtomicInt(&value,next);}
inline int SDL_GetAtomicIntRef(SDL_AtomicInt & value) {return SDL_GetAtomicInt(&value);}
inline int SDL_AddAtomicIntRef(SDL_AtomicInt & value,int amount) {return SDL_AddAtomicInt(&value,amount);}
inline bool SDL_CompareAndSwapAtomicU32Ref(SDL_AtomicU32 & value,uint32_t old_value,uint32_t new_value) {return SDL_CompareAndSwapAtomicU32(&value,old_value,new_value);}
inline uint32_t SDL_SetAtomicU32Ref(SDL_AtomicU32 & value,uint32_t next) {return SDL_SetAtomicU32(&value,next);}
inline uint32_t SDL_GetAtomicU32Ref(SDL_AtomicU32 & value) {return SDL_GetAtomicU32(&value);}
inline bool SDL_CompareAndSwapAtomicPointerRef(void * & value,void * old_value,void * new_value) {return SDL_CompareAndSwapAtomicPointer(&value,old_value,new_value);}
inline void * SDL_SetAtomicPointerRef(void * & value,void * next) {return SDL_SetAtomicPointer(&value,next);}
inline void * SDL_GetAtomicPointerRef(void * & value) {return SDL_GetAtomicPointer(&value);}
