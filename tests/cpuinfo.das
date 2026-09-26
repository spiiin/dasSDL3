options gen2
require sdl3

def features() {
    return <- array<bool>(
        SDL_HasAltiVec(),
        SDL_HasMMX(),
        SDL_HasSSE(),
        SDL_HasSSE2(),
        SDL_HasSSE3(),
        SDL_HasSSE41(),
        SDL_HasSSE42(),
        SDL_HasAVX(),
        SDL_HasAVX2(),
        SDL_HasAVX512F(),
        SDL_HasARMSIMD(),
        SDL_HasNEON(),
        SDL_HasLSX(),
        SDL_HasLASX())
}
[export]
def main(smoke : bool) : int {
    verify(SDL_WasInit(0u)==0u)
    SDL_SetErrorMessage("old error is not a query failure")
    let cores=SDL_GetNumLogicalCPUCores()
    let cacheline=SDL_GetCPUCacheLineSize()
    let memory=SDL_GetSystemRAM()
    let page=SDL_GetSystemPageSize()
    let alignment=uint64(SDL_GetSIMDAlignment())
    // Positive memory/page checks are for the local Windows profile, not universal guarantees.
    verify(cores>0 && memory>0 && page>0)
    verify(cacheline>0 && SDL_CACHELINE_SIZE==128)
    verify(alignment>=8ul && (alignment & (alignment-1ul))==0ul)
    var values <- features()
    var repeated <- features()
    verify(length(values)==14 && length(repeated)==14)
    let masked=SDL_GetHint(SDL_HINT_CPU_FEATURE_MASK)=="-all"
    for(i in 0 .. length(values)) {
        verify(values[i]==repeated[i])
        if(masked) {verify(!values[i])}
    }
    // Alignment is computed before the feature mask in the pinned SDL implementation.
    if(SDL_HasAVX512F()) {verify(alignment>=64ul)}
    if(SDL_HasAVX() || SDL_HasAVX2() || SDL_HasLASX()) {verify(alignment>=32ul)}
    if(SDL_HasSSE() || SDL_HasSSE2() || SDL_HasSSE3() || SDL_HasSSE41() || SDL_HasSSE42() || SDL_HasNEON() || SDL_HasAltiVec() || SDL_HasLSX() || SDL_HasARMSIMD()) {verify(alignment>=16ul)}
    verify(SDL_GetError()=="old error is not a query failure")
    verify(SDL_WasInit(0u)==0u)
    print("CPUInfo: 19 queries; cores={cores}, RAM={memory} MiB, cache={cacheline}, page={page}, SIMD alignment={alignment}; masked={masked}\n")
    return 0
}
