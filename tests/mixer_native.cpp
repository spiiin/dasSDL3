#include "libraries/mixer.h"
#include <array>
#include <cstdio>
#include <cstdlib>
#define CHECK(x) do { if(!(x)) { std::fprintf(stderr,"Failed: %s (%s)\n",#x,SDL_GetError()); return 1; } } while(0)
struct Counts { int stopped=0, raw=0, cooked=0, group=0, post=0; };
static void SDLCALL stopped(void* p,MIX_Track*) { ++static_cast<Counts*>(p)->stopped; }
static void SDLCALL raw(void* p,MIX_Track*,const SDL_AudioSpec*,float*,int) { ++static_cast<Counts*>(p)->raw; }
static void SDLCALL cooked(void* p,MIX_Track*,const SDL_AudioSpec*,float*,int) { ++static_cast<Counts*>(p)->cooked; }
static void SDLCALL group(void* p,MIX_Group*,const SDL_AudioSpec*,float*,int) { ++static_cast<Counts*>(p)->group; }
static void SDLCALL post(void* p,MIX_Mixer*,const SDL_AudioSpec*,float*,int) { ++static_cast<Counts*>(p)->post; }
struct Input { SDL_IOStream* inner; int closes=0; };
static Sint64 SDLCALL size(void* p) { return SDL_GetIOSize(static_cast<Input*>(p)->inner); }
static Sint64 SDLCALL seek(void* p,Sint64 n,SDL_IOWhence w) { return SDL_SeekIO(static_cast<Input*>(p)->inner,n,w); }
static size_t SDLCALL read(void* p,void* data,size_t n,SDL_IOStatus* status) {
    auto io=static_cast<Input*>(p)->inner; auto got=SDL_ReadIO(io,data,n);*status=SDL_GetIOStatus(io);return got;
}
static bool SDLCALL close(void* p) {auto in=static_cast<Input*>(p);++in->closes;return SDL_CloseIO(in->inner);}
static SDL_IOStream* input(Input& in) {
    in.inner=SDL_IOFromFile(DASSDL3_MIXER_WAV,"rb");
    SDL_IOStreamInterface f;SDL_INIT_INTERFACE(&f);f.size=size;f.seek=seek;f.read=read;f.close=close;
    return in.inner ? SDL_OpenIO(&f,&in) : nullptr;
}
int main() {
    CHECK(MIX_Init());
    SDL_AudioSpec spec{SDL_AUDIO_F32,1,48000};
    auto mixer=MIX_CreateMixer(&spec); CHECK(mixer);
    auto track=MIX_CreateTrack(mixer); auto grp=MIX_CreateGroup(mixer); CHECK(track && grp);
    std::array<float,128> data;data.fill(0.25f);
    auto audio=MIX_LoadRawAudio(mixer,data.data(),sizeof(data),&spec);CHECK(audio);
    CHECK(MIX_SetTrackAudio(track,audio)); MIX_DestroyAudio(audio); // Track retains its own audio reference.
    CHECK(MIX_SetTrackGroup(track,grp));
    Counts count;
    CHECK(MIX_SetTrackStoppedCallbackAddress(track,reinterpret_cast<void*>(stopped),&count));
    CHECK(MIX_SetTrackRawCallbackAddress(track,reinterpret_cast<void*>(raw),&count));
    CHECK(MIX_SetTrackCookedCallbackAddress(track,reinterpret_cast<void*>(cooked),&count));
    CHECK(MIX_SetGroupPostMixCallbackAddress(grp,reinterpret_cast<void*>(group),&count));
    CHECK(MIX_SetPostMixCallbackAddress(mixer,reinterpret_cast<void*>(post),&count));
    CHECK(MIX_PlayTrack(track,0));
    std::array<float,256> output{};CHECK(MIX_Generate(mixer,output.data(),sizeof(output))==sizeof(data));
    CHECK(output[0]==0.25f && output[127]==0.25f && output[128]==0.0f);
    CHECK(count.stopped==1 && count.raw>0 && count.cooked>0 && count.group>0 && count.post>0);
    CHECK(MIX_SetTrackStoppedCallbackAddress(track,nullptr,nullptr));
    CHECK(MIX_SetTrackRawCallbackAddress(track,nullptr,nullptr));
    CHECK(MIX_SetTrackCookedCallbackAddress(track,nullptr,nullptr));
    CHECK(MIX_SetGroupPostMixCallbackAddress(grp,nullptr,nullptr));
    CHECK(MIX_SetPostMixCallbackAddress(mixer,nullptr,nullptr));
    MIX_DestroyTrack(track);MIX_DestroyGroup(grp);
    for(bool transfer:{false,true}) {
        Input in{};auto io=input(in);CHECK(io);
        auto loaded=MIX_LoadAudio_IO(mixer,io,false,transfer);CHECK(loaded);
        MIX_DestroyAudio(loaded);
        CHECK(in.closes==(transfer ? 1 : 0));
        if(!transfer) {CHECK(SDL_SeekIO(io,0,SDL_IO_SEEK_SET)==0);CHECK(SDL_CloseIO(io));}
        CHECK(in.closes==1);
        Input decin{};auto dio=input(decin);CHECK(dio);
        auto decoder=MIX_CreateAudioDecoder_IO(dio,transfer,0);CHECK(decoder);
        MIX_DestroyAudioDecoder(decoder);CHECK(decin.closes==(transfer ? 1 : 0));
        if(!transfer) CHECK(SDL_CloseIO(dio));
        CHECK(decin.closes==1);
    }
    MIX_DestroyMixer(mixer);MIX_Quit();
    std::puts("Mixer native callbacks, PCM oracle, retained audio and IO ownership: PASS");
    return 0;
}
