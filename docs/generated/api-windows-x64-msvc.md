# SDL API inventory (generated)

SDL 3.4.16; profile `windows-x64-msvc`.

Active declarations/macros only; inactive platform branches are NOT counted. Record and typedef entries are distinct declarations.

Generated functions: **1005/1263** active non-excluded functions.
Adapted functions: **13**; pending functions: **245**.
Adapted coverage and boost coverage are not inferred from function names.

| Category | Functions | Generated | Adapted | Pending |
| --- | ---: | ---: | ---: | ---: |
| Assert | 6 | 0 | 0 | 6 |
| AsyncIO | 11 | 11 | 0 | 0 |
| Atomic | 16 | 16 | 0 | 0 |
| Audio | 58 | 58 | 0 | 0 |
| Bits | 2 | 0 | 0 | 2 |
| Blendmode | 1 | 1 | 0 | 0 |
| CPUInfo | 19 | 1 | 0 | 18 |
| Camera | 15 | 15 | 0 | 0 |
| Clipboard | 11 | 11 | 0 | 0 |
| Dialog | 4 | 4 | 0 | 0 |
| Endian | 1 | 0 | 0 | 1 |
| Error | 5 | 3 | 1 | 1 |
| Events | 20 | 20 | 0 | 0 |
| Filesystem | 11 | 11 | 0 | 0 |
| GPU | 95 | 95 | 0 | 0 |
| GUID | 2 | 2 | 0 | 0 |
| Gamepad | 73 | 73 | 0 | 0 |
| HIDAPI | 23 | 23 | 0 | 0 |
| Haptic | 31 | 31 | 0 | 0 |
| Hints | 8 | 6 | 0 | 2 |
| IOStream | 48 | 46 | 1 | 1 |
| Init | 10 | 9 | 0 | 1 |
| Joystick | 58 | 58 | 0 | 0 |
| Keyboard | 24 | 24 | 0 | 0 |
| Locale | 1 | 1 | 0 | 0 |
| Log | 18 | 5 | 9 | 4 |
| Main | 7 | 0 | 0 | 7 |
| Messagebox | 2 | 2 | 0 | 0 |
| Metal | 3 | 0 | 0 | 3 |
| Misc | 1 | 1 | 0 | 0 |
| Mouse | 24 | 24 | 0 | 0 |
| Mutex | 28 | 28 | 0 | 0 |
| Pen | 1 | 1 | 0 | 0 |
| Pixels | 11 | 11 | 0 | 0 |
| Platform | 1 | 1 | 0 | 0 |
| Power | 1 | 1 | 0 | 0 |
| Process | 9 | 9 | 0 | 0 |
| Properties | 21 | 19 | 1 | 1 |
| Rect | 18 | 18 | 0 | 0 |
| Render | 102 | 101 | 1 | 0 |
| Sensor | 14 | 14 | 0 | 0 |
| SharedObject | 3 | 3 | 0 | 0 |
| Stdinc | 170 | 1 | 0 | 169 |
| Storage | 17 | 17 | 0 | 0 |
| Surface | 65 | 65 | 0 | 0 |
| System | 13 | 13 | 0 | 0 |
| Thread | 12 | 12 | 0 | 0 |
| Time | 9 | 9 | 0 | 0 |
| Timer | 10 | 8 | 0 | 2 |
| Touch | 4 | 4 | 0 | 0 |
| Tray | 23 | 23 | 0 | 0 |
| Version | 2 | 2 | 0 | 0 |
| Video | 114 | 94 | 0 | 20 |
| Vulkan | 7 | 0 | 0 | 7 |

## Script priority decisions

These decisions do not change raw coverage or remove declarations from its denominator.

| Disposition | Functions |
| --- | ---: |
| c_abi_only | 10 |
| deferred | 16 |
| host_only | 6 |
| native_interop | 15 |
| stdlib | 122 |

| Function | Disposition | Contract |
| --- | --- | --- |
| `SDL_CreateEnvironment` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_DestroyEnvironment` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_GetEnvironment` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_GetEnvironmentVariable` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_GetEnvironmentVariables` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_GetMemoryFunctions` | host_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_GetNumAllocations` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_GetOriginalMemoryFunctions` | host_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_SetEnvironmentVariable` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_SetMemoryFunctions` | host_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_StepBackUTF8` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_StepUTF8` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_UCS4ToUTF8` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_UnsetEnvironmentVariable` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_abs` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_acos` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_acosf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_aligned_alloc` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_aligned_free` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_asin` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_asinf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_asprintf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_atan` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_atan2` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_atan2f` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_atanf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_atof` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_atoi` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_bsearch` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_bsearch_r` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_calloc` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_ceil` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_ceilf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_copysign` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_copysignf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_cos` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_cosf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_crc16` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_crc32` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_exp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_expf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_fabs` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_fabsf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_floor` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_floorf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_fmod` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_fmodf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_getenv` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_getenv_unsafe` | host_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_iconv` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_iconv_close` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_iconv_open` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_iconv_string` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isalnum` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isalpha` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isblank` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_iscntrl` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isdigit` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isgraph` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isinf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isinff` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_islower` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isnan` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isnanf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isprint` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_ispunct` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isspace` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isupper` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_isxdigit` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_itoa` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_lltoa` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_log` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_log10` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_log10f` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_logf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_lround` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_lroundf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_ltoa` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_malloc` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_memcmp` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_memcpy` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_memmove` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_memset` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_memset4` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_modf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_modff` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_murmur3_32` | deferred | [stdinc-policy](../stdinc-policy.md) |
| `SDL_pow` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_powf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_qsort` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_qsort_r` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_rand` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_rand_bits` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_rand_bits_r` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_rand_r` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_randf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_randf_r` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_realloc` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_round` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_roundf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_scalbn` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_scalbnf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_setenv_unsafe` | host_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_sin` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_sinf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_size_add_check_overflow` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_size_add_check_overflow_builtin` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_size_mul_check_overflow` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_size_mul_check_overflow_builtin` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_snprintf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_sqrt` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_sqrtf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_srand` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_sscanf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strcasecmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strcasestr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strchr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strcmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strdup` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strlcat` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strlcpy` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strlen` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strlwr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strncasecmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strncmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strndup` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strnlen` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strnstr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strpbrk` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strrchr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strrev` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strstr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strtod` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strtok_r` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strtol` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strtoll` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strtoul` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strtoull` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_strupr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_swprintf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_tan` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_tanf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_tolower` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_toupper` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_trunc` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_truncf` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_uitoa` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_ulltoa` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_ultoa` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_unsetenv_unsafe` | host_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_utf8strlcpy` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_utf8strlen` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_utf8strnlen` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_vasprintf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_vsnprintf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_vsscanf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_vswprintf` | c_abi_only | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcscasecmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcscmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcsdup` | native_interop | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcslcat` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcslcpy` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcslen` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcsncasecmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcsncmp` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcsnlen` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcsnstr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcsstr` | stdlib | [stdinc-policy](../stdinc-policy.md) |
| `SDL_wcstol` | stdlib | [stdinc-policy](../stdinc-policy.md) |

Declaration counts (including explicitly excluded scaffolding):

- enum: 96
- enumerator: 1163
- function: 1263
- macro: 1816
- record: 164
- typedef: 352

Unobserved, non-excluded headers (must be reviewed, not silently ignored):

- None. Inactive branches inside observed headers still require other profiles.
