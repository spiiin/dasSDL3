#include "daScript/daScript.h"
#include "daScript/simulate/aot.h"
#include "aot_builtin_clipboard.h"
#include <SDL3/SDL.h>
#include <memory>
#include <string>

// The pinned dasImgui module references these two text callbacks from its
// desktop clipboard module. The iOS build uses SDL for clipboard access.
namespace das {
const char *builtin_clipboard_get_text_temporary(int32_t &status) {
    thread_local std::unique_ptr<char, decltype(&SDL_free)> text(nullptr, SDL_free);
    text.reset(SDL_GetClipboardText());
    status = static_cast<int32_t>(!text ? ClipboardStatus::failed :
                                  *text ? ClipboardStatus::ok : ClipboardStatus::no_text);
    return text.get();
}

int32_t builtin_clipboard_set_text(const char *text, int32_t size) {
    if (size < 0 || (!text && size)) return static_cast<int32_t>(ClipboardStatus::failed);
    const std::string value(text ? text : "", static_cast<size_t>(size));
    return static_cast<int32_t>(SDL_SetClipboardText(value.c_str()) ?
                                ClipboardStatus::ok : ClipboardStatus::failed);
}
}
