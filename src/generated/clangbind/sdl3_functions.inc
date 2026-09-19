addAnnotation(new DummyTypeAnnotation("SDL_Window", "SDL_Window", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Renderer", "SDL_Renderer", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Surface", "SDL_Surface", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Texture", "SDL_Texture", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_AudioStream", "SDL_AudioStream", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Wav", "SDL_Wav", 1, 1));
addAnnotation(new SDL_AudioSpecAnnotation(lib));
addAnnotation(new SDL_FRectAnnotation(lib));
addAnnotation(new SDL_KeyboardEventAnnotation(lib));
addAnnotation(new SDL_MouseMotionEventAnnotation(lib));
addAnnotation(new SDL_MouseButtonEventAnnotation(lib));
addAnnotation(new SDL_MouseWheelEventAnnotation(lib));
addAnnotation(new SDL_EventAnnotation(lib));
static_assert(static_cast<uint32_t>(SDL_INIT_VIDEO) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_INIT_VIDEO", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_RESIZABLE) == static_cast<uint64_t>(0x20ULL));
addConstant(*this, "SDL_WINDOW_RESIZABLE", static_cast<uint64_t>(0x20ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_HIDDEN) == static_cast<uint64_t>(0x8ULL));
addConstant(*this, "SDL_WINDOW_HIDDEN", static_cast<uint64_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_QUIT) == static_cast<uint32_t>(0x100ULL));
addConstant(*this, "SDL_EVENT_QUIT", static_cast<uint32_t>(0x100ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_KEY_DOWN) == static_cast<uint32_t>(0x300ULL));
addConstant(*this, "SDL_EVENT_KEY_DOWN", static_cast<uint32_t>(0x300ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_KEY_UP) == static_cast<uint32_t>(0x301ULL));
addConstant(*this, "SDL_EVENT_KEY_UP", static_cast<uint32_t>(0x301ULL));
static_assert(static_cast<uint32_t>(SDLK_ESCAPE) == static_cast<uint32_t>(0x1bULL));
addConstant(*this, "SDLK_ESCAPE", static_cast<uint32_t>(0x1bULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_TEXT_INPUT) == static_cast<uint32_t>(0x303ULL));
addConstant(*this, "SDL_EVENT_TEXT_INPUT", static_cast<uint32_t>(0x303ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_TEXT_EDITING) == static_cast<uint32_t>(0x302ULL));
addConstant(*this, "SDL_EVENT_TEXT_EDITING", static_cast<uint32_t>(0x302ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_MOTION) == static_cast<uint32_t>(0x400ULL));
addConstant(*this, "SDL_EVENT_MOUSE_MOTION", static_cast<uint32_t>(0x400ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_BUTTON_DOWN) == static_cast<uint32_t>(0x401ULL));
addConstant(*this, "SDL_EVENT_MOUSE_BUTTON_DOWN", static_cast<uint32_t>(0x401ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_BUTTON_UP) == static_cast<uint32_t>(0x402ULL));
addConstant(*this, "SDL_EVENT_MOUSE_BUTTON_UP", static_cast<uint32_t>(0x402ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_WHEEL) == static_cast<uint32_t>(0x403ULL));
addConstant(*this, "SDL_EVENT_MOUSE_WHEEL", static_cast<uint32_t>(0x403ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_CLOSE_REQUESTED) == static_cast<uint32_t>(0x210ULL));
addConstant(*this, "SDL_EVENT_WINDOW_CLOSE_REQUESTED", static_cast<uint32_t>(0x210ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_LEFT) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_BUTTON_LEFT", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_MIDDLE) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_BUTTON_MIDDLE", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_RIGHT) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_BUTTON_RIGHT", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_LMASK) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_BUTTON_LMASK", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_MMASK) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_BUTTON_MMASK", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_RMASK) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_BUTTON_RMASK", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_SHIFT) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_KMOD_SHIFT", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_CTRL) == static_cast<uint32_t>(0xc0ULL));
addConstant(*this, "SDL_KMOD_CTRL", static_cast<uint32_t>(0xc0ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_ALT) == static_cast<uint32_t>(0x300ULL));
addConstant(*this, "SDL_KMOD_ALT", static_cast<uint32_t>(0x300ULL));
static_assert(static_cast<uint32_t>(SDLK_BACKSPACE) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDLK_BACKSPACE", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDLK_RETURN) == static_cast<uint32_t>(0xdULL));
addConstant(*this, "SDLK_RETURN", static_cast<uint32_t>(0xdULL));
static_assert(static_cast<uint32_t>(SDLK_LEFT) == static_cast<uint32_t>(0x40000050ULL));
addConstant(*this, "SDLK_LEFT", static_cast<uint32_t>(0x40000050ULL));
static_assert(static_cast<uint32_t>(SDLK_RIGHT) == static_cast<uint32_t>(0x4000004fULL));
addConstant(*this, "SDLK_RIGHT", static_cast<uint32_t>(0x4000004fULL));
static_assert(static_cast<uint32_t>(SDLK_UP) == static_cast<uint32_t>(0x40000052ULL));
addConstant(*this, "SDLK_UP", static_cast<uint32_t>(0x40000052ULL));
static_assert(static_cast<uint32_t>(SDLK_DOWN) == static_cast<uint32_t>(0x40000051ULL));
addConstant(*this, "SDLK_DOWN", static_cast<uint32_t>(0x40000051ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_A) == static_cast<int32_t>(4ULL));
addConstant(*this, "SDL_SCANCODE_A", static_cast<int32_t>(4ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_LEFT) == static_cast<int32_t>(80ULL));
addConstant(*this, "SDL_SCANCODE_LEFT", static_cast<int32_t>(80ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_RIGHT) == static_cast<int32_t>(79ULL));
addConstant(*this, "SDL_SCANCODE_RIGHT", static_cast<int32_t>(79ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_UP) == static_cast<int32_t>(82ULL));
addConstant(*this, "SDL_SCANCODE_UP", static_cast<int32_t>(82ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_DOWN) == static_cast<int32_t>(81ULL));
addConstant(*this, "SDL_SCANCODE_DOWN", static_cast<int32_t>(81ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_ESCAPE) == static_cast<int32_t>(41ULL));
addConstant(*this, "SDL_SCANCODE_ESCAPE", static_cast<int32_t>(41ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_SPACE) == static_cast<int32_t>(44ULL));
addConstant(*this, "SDL_SCANCODE_SPACE", static_cast<int32_t>(44ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_COUNT) == static_cast<int32_t>(512ULL));
addConstant(*this, "SDL_SCANCODE_COUNT", static_cast<int32_t>(512ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_AUDIO) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_INIT_AUDIO", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_S16) == static_cast<uint32_t>(0x8010ULL));
addConstant(*this, "SDL_AUDIO_S16", static_cast<uint32_t>(0x8010ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_S16LE) == static_cast<uint32_t>(0x8010ULL));
addConstant(*this, "SDL_AUDIO_S16LE", static_cast<uint32_t>(0x8010ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_F32) == static_cast<uint32_t>(0x8120ULL));
addConstant(*this, "SDL_AUDIO_F32", static_cast<uint32_t>(0x8120ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK) == static_cast<uint32_t>(0xffffffffULL));
addConstant(*this, "SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK", static_cast<uint32_t>(0xffffffffULL));
// from SDL3/SDL_stdinc.h:1405:34
	makeExtern< void (*)(void *) , SDL_free , SimNode_ExtFuncCall >(lib,"SDL_free","SDL_free")
		->args({"mem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_error.h:158:42
	makeExtern< const char * (*)() , SDL_GetError , SimNode_ExtFuncCall >(lib,"SDL_GetError","SDL_GetError")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1039:47
	makeExtern< unsigned int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamDevice","SDL_GetAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1061:47
	makeExtern< struct SDL_AudioStream * (*)(const struct SDL_AudioSpec *,const struct SDL_AudioSpec *) , SDL_CreateAudioStream , SimNode_ExtFuncCall >(lib,"SDL_CreateAudioStream","SDL_CreateAudioStream")
		->args({"src_spec","dst_spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1092:34
	makeExtern< bool (*)(struct SDL_AudioStream *,struct SDL_AudioSpec *,struct SDL_AudioSpec *) , SDL_GetAudioStreamFormat , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamFormat","SDL_GetAudioStreamFormat")
		->args({"stream","src_spec","dst_spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1415:34
	makeExtern< bool (*)(struct SDL_AudioStream *,const void *,int) , SDL_PutAudioStreamData , SimNode_ExtFuncCall >(lib,"SDL_PutAudioStreamData","SDL_PutAudioStreamData")
		->args({"stream","buf","len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1445:33
	makeExtern< int (*)(struct SDL_AudioStream *,void *,int) , SDL_GetAudioStreamData , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamData","SDL_GetAudioStreamData")
		->args({"stream","buf","len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1471:33
	makeExtern< int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamAvailable , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamAvailable","SDL_GetAudioStreamAvailable")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1510:33
	makeExtern< int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamQueued , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamQueued","SDL_GetAudioStreamQueued")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1531:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_FlushAudioStream , SimNode_ExtFuncCall >(lib,"SDL_FlushAudioStream","SDL_FlushAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1552:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_ClearAudioStream , SimNode_ExtFuncCall >(lib,"SDL_ClearAudioStream","SDL_ClearAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1576:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_PauseAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_PauseAudioStreamDevice","SDL_PauseAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1599:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_ResumeAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_ResumeAudioStreamDevice","SDL_ResumeAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1618:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_AudioStreamDevicePaused , SimNode_ExtFuncCall >(lib,"SDL_AudioStreamDevicePaused","SDL_AudioStreamDevicePaused")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1825:34
	makeExtern< void (*)(struct SDL_AudioStream *) , SDL_DestroyAudioStream , SimNode_ExtFuncCall >(lib,"SDL_DestroyAudioStream","SDL_DestroyAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2096:34
	makeExtern< bool (*)(const char *,struct SDL_AudioSpec *,unsigned char **,unsigned int *) , SDL_LoadWAV , SimNode_ExtFuncCall >(lib,"SDL_LoadWAV","SDL_LoadWAV")
		->args({"path","spec","audio_buf","audio_len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:213:34
	makeExtern< void (*)(struct SDL_Surface *) , SDL_DestroySurface , SimNode_ExtFuncCall >(lib,"SDL_DestroySurface","SDL_DestroySurface")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:528:43
	makeExtern< struct SDL_Surface * (*)(const char *) , SDL_LoadBMP , SimNode_ExtFuncCall >(lib,"SDL_LoadBMP","SDL_LoadBMP")
		->args({"file"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1129:42
	makeExtern< struct SDL_Window * (*)(const char *,int,int,SDL_WindowFlags) , SDL_CreateWindow , SimNode_ExtFuncCall >(lib,"SDL_CreateWindow","SDL_CreateWindow")
		->args({"title","w","h","flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1386:42
	makeExtern< unsigned int (*)(struct SDL_Window *) , SDL_GetWindowID , SimNode_ExtFuncCall >(lib,"SDL_GetWindowID","SDL_GetWindowID")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1404:42
	makeExtern< struct SDL_Window * (*)(unsigned int) , SDL_GetWindowFromID , SimNode_ExtFuncCall >(lib,"SDL_GetWindowFromID","SDL_GetWindowFromID")
		->args({"id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1615:34
	makeExtern< bool (*)(struct SDL_Window *,const char *) , SDL_SetWindowTitle , SimNode_ExtFuncCall >(lib,"SDL_SetWindowTitle","SDL_SetWindowTitle")
		->args({"window","title"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2838:34
	makeExtern< void (*)(struct SDL_Window *) , SDL_DestroyWindow , SimNode_ExtFuncCall >(lib,"SDL_DestroyWindow","SDL_DestroyWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:159:42
	makeExtern< const bool * (*)(int *) , SDL_GetKeyboardState , SimNode_ExtFuncCall >(lib,"SDL_GetKeyboardState","SDL_GetKeyboardState")
		->args({"numkeys"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:379:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_StartTextInput , SimNode_ExtFuncCall >(lib,"SDL_StartTextInput","SDL_StartTextInput")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:494:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_TextInputActive , SimNode_ExtFuncCall >(lib,"SDL_TextInputActive","SDL_TextInputActive")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:512:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_StopTextInput , SimNode_ExtFuncCall >(lib,"SDL_StopTextInput","SDL_StopTextInput")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:528:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_ClearComposition , SimNode_ExtFuncCall >(lib,"SDL_ClearComposition","SDL_ClearComposition")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:261:50
	makeExtern< unsigned int (*)(float *,float *) , SDL_GetMouseState , SimNode_ExtFuncCall >(lib,"SDL_GetMouseState","SDL_GetMouseState")
		->args({"x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1071:34
	makeExtern< void (*)() , SDL_PumpEvents , SimNode_ExtFuncCall >(lib,"SDL_PumpEvents","SDL_PumpEvents")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1270:34
	makeExtern< bool (*)(union SDL_Event *) , SDL_PollEvent , SimNode_ExtFuncCall >(lib,"SDL_PollEvent","SDL_PollEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1358:34
	makeExtern< bool (*)(union SDL_Event *) , SDL_PushEvent , SimNode_ExtFuncCall >(lib,"SDL_PushEvent","SDL_PushEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:96:42
	makeExtern< const char * (*)() , SDL_GetBasePath , SimNode_ExtFuncCall >(lib,"SDL_GetBasePath","SDL_GetBasePath")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:236:34
	makeExtern< bool (*)(unsigned int) , SDL_Init , SimNode_ExtFuncCall >(lib,"SDL_Init","SDL_Init")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:282:43
	makeExtern< unsigned int (*)(unsigned int) , SDL_WasInit , SimNode_ExtFuncCall >(lib,"SDL_WasInit","SDL_WasInit")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:300:34
	makeExtern< void (*)() , SDL_Quit , SimNode_ExtFuncCall >(lib,"SDL_Quit","SDL_Quit")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:246:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Window *,const char *) , SDL_CreateRenderer , SimNode_ExtFuncCall >(lib,"SDL_CreateRenderer","SDL_CreateRenderer")
		->args({"window","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:345:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Window *) , SDL_GetRenderer , SimNode_ExtFuncCall >(lib,"SDL_GetRenderer","SDL_GetRenderer")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:584:43
	makeExtern< struct SDL_Texture * (*)(struct SDL_Renderer *,struct SDL_Surface *) , SDL_CreateTextureFromSurface , SimNode_ExtFuncCall >(lib,"SDL_CreateTextureFromSurface","SDL_CreateTextureFromSurface")
		->args({"renderer","surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:865:34
	makeExtern< bool (*)(struct SDL_Texture *,float *,float *) , SDL_GetTextureSize , SimNode_ExtFuncCall >(lib,"SDL_GetTextureSize","SDL_GetTextureSize")
		->args({"texture","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1782:34
	makeExtern< bool (*)(struct SDL_Renderer *,unsigned char,unsigned char,unsigned char,unsigned char) , SDL_SetRenderDrawColor , SimNode_ExtFuncCall >(lib,"SDL_SetRenderDrawColor","SDL_SetRenderDrawColor")
		->args({"renderer","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1949:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderClear , SimNode_ExtFuncCall >(lib,"SDL_RenderClear","SDL_RenderClear")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2073:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FRect *) , SDL_RenderFillRect , SimNode_ExtFuncCall >(lib,"SDL_RenderFillRect","SDL_RenderFillRect")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2113:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_FRect *,const struct SDL_FRect *) , SDL_RenderTexture , SimNode_ExtFuncCall >(lib,"SDL_RenderTexture","SDL_RenderTexture")
		->args({"renderer","texture","srcrect","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2374:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderPresent , SimNode_ExtFuncCall >(lib,"SDL_RenderPresent","SDL_RenderPresent")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2391:34
	makeExtern< void (*)(struct SDL_Texture *) , SDL_DestroyTexture , SimNode_ExtFuncCall >(lib,"SDL_DestroyTexture","SDL_DestroyTexture")
		->args({"texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2407:34
	makeExtern< void (*)(struct SDL_Renderer *) , SDL_DestroyRenderer , SimNode_ExtFuncCall >(lib,"SDL_DestroyRenderer","SDL_DestroyRenderer")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:197:36
	makeExtern< Uint64 (*)() , SDL_GetTicks , SimNode_ExtFuncCall >(lib,"SDL_GetTicks","SDL_GetTicks")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:259:34
	makeExtern< void (*)(unsigned int) , SDL_Delay , SimNode_ExtFuncCall >(lib,"SDL_Delay","SDL_Delay")
		->args({"ms"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_version.h:148:33
	makeExtern< int (*)() , SDL_GetVersion , SimNode_ExtFuncCall >(lib,"SDL_GetVersion","SDL_GetVersion")
		->addToModule(*this, SideEffects::worstDefault);
