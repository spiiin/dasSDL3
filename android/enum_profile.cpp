#include <SDL3/SDL.h>
#ifdef DASSDL3_WITH_TTF
#include <SDL3_ttf/SDL_ttf.h>
#endif
#ifdef DASSDL3_WITH_NET
#include <SDL3_net/SDL_net.h>
#endif
#ifdef DASSDL3_WITH_SOUND
#include <SDL3_sound/SDL_sound.h>
#endif
#include <array>
#include <type_traits>

// Each line describes a native SDL enum as seen by the target compiler.
// On MSVC and Android a four-byte C enum can have different signedness.
template<class T, size_t N> constexpr auto describeEnum(const char (&name)[N]) {
    using Base = std::underlying_type_t<T>;
    static_assert(sizeof(Base) == 4, "Extend the AOT enum profile for this width");
    std::array<char, N + 2> line{};
    for (size_t i = 0; i < N - 1; ++i) line[i] = name[i];
    line[N - 1] = ' ';
    line[N] = std::is_signed_v<Base> ? 'i' : 'u';
    line[N + 1] = '\n';
    return line;
}
#define PROFILE(module, T) [[gnu::section(".dassdl3.enums"), gnu::used, gnu::aligned(1)]] \
    static constexpr auto row_##T = describeEnum<T>(#module " " #T);
#include "android_enum_names.inc"
