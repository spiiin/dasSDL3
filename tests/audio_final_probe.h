#pragma once
#include <atomic>
#include <thread>
namespace sdl3_test {
struct AudioFinalProbe {std::atomic<int> get{0},put{0},post{0},bad{0},foreign{0};std::thread::id owner;};
inline AudioFinalProbe audio_final_probe;
inline void audio_final_reset() {auto & p=audio_final_probe;p.get=0;p.put=0;p.post=0;p.bad=0;p.foreign=0;p.owner=std::this_thread::get_id();}
inline void * audio_final_data() {return &audio_final_probe;}
inline void audio_final_check(void * data) {auto & p=audio_final_probe;if(data!=&p)p.bad++;if(std::this_thread::get_id()!=p.owner)p.foreign++;}
inline void SDLCALL audio_final_get(void * data,SDL_AudioStream * stream,int additional,int total) {
    audio_final_check(data);audio_final_probe.get++;
    if(additional<0 || total<0)audio_final_probe.bad++;
    if(additional>0) {float samples[256];for(float & value:samples)value=0.25f;
        const int count=SDL_min(additional/4,256);if(count && !SDL_PutAudioStreamData(stream,samples,count*4))audio_final_probe.bad++;}
}
inline void SDLCALL audio_final_put(void * data,SDL_AudioStream *,int additional,int total) {audio_final_check(data);audio_final_probe.put++;if(additional<0 || total<0)audio_final_probe.bad++;}
inline void SDLCALL audio_final_post(void * data,const SDL_AudioSpec * spec,float * buffer,int bytes) {
    audio_final_check(data);audio_final_probe.post++;
    if(!spec || spec->format!=SDL_AUDIO_F32 || spec->channels<=0 || spec->freq<=0 || bytes<=0 || bytes%4 || !buffer)audio_final_probe.bad++;
    if(buffer && bytes>=4)buffer[0]=0.0f;
}
inline void * audio_final_callback(int kind) {switch(kind) {case 0:return reinterpret_cast<void *>(audio_final_get);case 1:return reinterpret_cast<void *>(audio_final_put);case 2:return reinterpret_cast<void *>(audio_final_post);default:return nullptr;}}
inline int audio_final_count(int kind) {auto & p=audio_final_probe;switch(kind) {case 0:return p.get.load();case 1:return p.put.load();case 2:return p.post.load();case 3:return p.bad.load();case 4:return p.foreign.load();default:return -1;}}
inline bool audio_final_read_on_thread(SDL_AudioStream * stream) {bool ok=false;std::thread worker([&] {float data[4]{};ok=SDL_GetAudioStreamData(stream,data,16)==16;for(float value:data)ok=ok && value==0.25f;});worker.join();return ok;}
}
