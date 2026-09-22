#pragma once
#include <SDL3/SDL.h>
#include <thread>
#include <atomic>
namespace sdl3_test {
// Worker threads never enter daScript or retain script blocks.
inline bool mutex_available(SDL_Mutex * mutex) {
    bool available=false;std::thread worker([&]{available=SDL_TryLockMutex(mutex);if(available)SDL_UnlockMutex(mutex);});worker.join();return available;
}
inline bool rwlock_available(SDL_RWLock * lock,bool write) {
    bool available=false;std::thread worker([&]{available=write?SDL_TryLockRWLockForWriting(lock):SDL_TryLockRWLockForReading(lock);if(available)SDL_UnlockRWLock(lock);});worker.join();return available;
}
inline std::thread sync_worker;
inline std::atomic<bool> condition_ready{false},hold_ready{false},hold_release{false};
inline void hold_start(SDL_Mutex * mutex,SDL_RWLock * lock,bool write) {
    hold_ready=false;hold_release=false;
    sync_worker=std::thread([=]{
        if(mutex)SDL_LockMutex(mutex);else if(write)SDL_LockRWLockForWriting(lock);else SDL_LockRWLockForReading(lock);
        hold_ready=true;while(!hold_release.load())std::this_thread::yield();
        if(mutex)SDL_UnlockMutex(mutex);else SDL_UnlockRWLock(lock);
    });
    while(!hold_ready.load())std::this_thread::yield();
}
inline void hold_stop() {hold_release=true;sync_worker.join();}
inline void condition_start(SDL_Mutex * mutex,SDL_Condition * cond,bool broadcast) {
    condition_ready=false;
    sync_worker=std::thread([=]{SDL_LockMutex(mutex);condition_ready=true;if(broadcast)SDL_BroadcastCondition(cond);else SDL_SignalCondition(cond);SDL_UnlockMutex(mutex);});
}
inline bool condition_done() {return condition_ready.load();}
inline void sync_join() {if(sync_worker.joinable())sync_worker.join();}
inline void semaphore_start(SDL_Semaphore * sem) {sync_worker=std::thread([=]{SDL_SignalSemaphore(sem);});}
}
