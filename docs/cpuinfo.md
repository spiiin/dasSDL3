# CPU information

Pinned SDL 3.4.16, Windows x64/MSVC. CPUInfo now has 19/19 raw functions:
18 newly generated queries plus the existing SDL_GetSystemPageSize.
The SDL_CACHELINE_SIZE compile-time padding constant is also exposed (128 in
this pin). It is a conservative guess, not the measured L1 cache line size.

Use `require sdl3`. No boost wrapper is needed: these functions return direct
scalar values or capability predicates, without ownership or output parameters.
False capability answers and unknown sizes must not be turned into Result errors
based on stale SDL_GetError contents. The example needs no SDL_Init/SDL_Quit.

- SDL_GetNumLogicalCPUCores reports logical processors, not physical cores.
- SDL_GetCPUCacheLineSize is in bytes; SDL_GetSystemRAM is in MiB and describes
  system RAM, not currently free memory or a script allocation budget.
- SDL_GetSystemPageSize can return zero when unknown, without setting an error.
- SDL_GetSIMDAlignment returns native size_t (uint64 in this Windows x64 profile).
  It describes required native allocation alignment; it does not align script
  arrays or enable instruction sets in the daScript/AOT compiler.
- Fourteen SDL_Has* predicates cover AltiVec, MMX, SSE/SSE2/SSE3/SSE41/SSE42,
  AVX/AVX2/AVX512F, ARMSIMD, NEON, LSX and LASX. No assumption that all exist on
  a machine, or that features remain hierarchically related after masking.
- SDL_CPU_FEATURE_MASK limits detected features; it cannot create CPU support.
  Configure it before first detection (prefer process environment). The pinned
  implementation caches the feature result. It computes SIMD alignment before
  applying the feature mask, so `-all` does not imply pointer-size alignment.

Sources: [alignment](https://wiki.libsdl.org/SDL3/SDL_GetSIMDAlignment),
[feature mask](https://wiki.libsdl.org/SDL3/SDL_HINT_CPU_FEATURE_MASK), and pinned
SDL_cpuinfo.h / src/cpuinfo/SDL_cpuinfo.c for actual sentinel/cache behavior.

## Tests

`tests/cpuinfo.das` executes all nineteen queries before SDL initialization,
checks scalar units/ranges on the Windows host, verifies alignment against
reported SIMD features, repeatability and independence from a stale error string.
A separate process starts with SDL_CPU_FEATURE_MASK=-all and checks all fourteen
predicates are false. It deliberately does not assume masked alignment shrinks.
`examples/91_cpuinfo.das` prints the values using the raw API.

Positive RAM/page assertions are Windows test expectations, not a promise that
all SDL platforms can detect them. Interpreter/AOT parity does not establish
ARM, PowerPC, LoongArch or browser detection; those need platform runs. Stdinc
allocation/math functions remain outside this package as requested.
