options gen2
require sdl3
[export]
def main(smoke : bool) : int {
    // These queries require no SDL_Init and do not return Result errors.
    print("Logical CPU cores: {SDL_GetNumLogicalCPUCores()}\n")
    print("System RAM: {SDL_GetSystemRAM()} MiB\n")
    print("L1 cache line: {SDL_GetCPUCacheLineSize()} bytes\n")
    print("Page size: {SDL_GetSystemPageSize()} bytes (0 means unknown)\n")
    print("SIMD allocation alignment: {SDL_GetSIMDAlignment()} bytes\n")
    print("MMX={SDL_HasMMX()}, SSE={SDL_HasSSE()}, SSE2={SDL_HasSSE2()}, SSE3={SDL_HasSSE3()}, SSE4.1={SDL_HasSSE41()}, SSE4.2={SDL_HasSSE42()}\n")
    print("AVX={SDL_HasAVX()}, AVX2={SDL_HasAVX2()}, AVX512F={SDL_HasAVX512F()}\n")
    print("AltiVec={SDL_HasAltiVec()}, ARM SIMD={SDL_HasARMSIMD()}, NEON={SDL_HasNEON()}, LSX={SDL_HasLSX()}, LASX={SDL_HasLASX()}\n")
    // Capability predicates reflect SDL's detection and optional CPU_FEATURE_MASK.
    // They do not change the compiler target or align existing script arrays.
    return 0
}
