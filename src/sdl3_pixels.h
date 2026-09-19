#pragma once
#include <SDL3/SDL.h>
#include "daScript/daScript.h"
#include <climits>
#include <cstring>
#include <memory>

// Byte RGBA order, independent of integer endianness. No last-row padding needed.
inline int SDL_RGBA8BufferSize(int width, int height, int pitch) {
    if (width <= 0 || height <= 0 || width > INT_MAX / 4 || pitch < width * 4) {
        SDL_SetError("RGBA8: invalid dimensions or pitch"); return -1;
    }
    const int64_t size = int64_t(height - 1) * pitch + int64_t(width) * 4;
    if (size > INT_MAX) { SDL_SetError("RGBA8: buffer exceeds INT_MAX bytes"); return -1; }
    return int(size);
}
inline SDL_Texture * SDL_CreateRGBA8Texture(SDL_Renderer * renderer, int width, int height, bool target) {
    if (!renderer || width <= 0 || height <= 0 || width > INT_MAX / 4) {
        SDL_SetError("RGBA8: invalid renderer or dimensions"); return nullptr;
    }
    return SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32,
        target ? SDL_TEXTUREACCESS_TARGET : SDL_TEXTUREACCESS_STREAMING, width, height);
}
inline bool SDL_UploadRGBA8(SDL_Texture * texture, const das::TArray<uint8_t> & bytes, int pitch) {
    if (!texture) return SDL_SetError("upload_rgba8: null texture");
    const auto props = SDL_GetTextureProperties(texture);
    if (!props) return false;
    if (SDL_GetNumberProperty(props, SDL_PROP_TEXTURE_FORMAT_NUMBER, 0) != SDL_PIXELFORMAT_RGBA32 ||
        SDL_GetNumberProperty(props, SDL_PROP_TEXTURE_ACCESS_NUMBER, -1) != SDL_TEXTUREACCESS_STREAMING)
        return SDL_SetError("upload_rgba8: expected RGBA32 streaming texture");
    const int width = int(SDL_GetNumberProperty(props, SDL_PROP_TEXTURE_WIDTH_NUMBER, 0));
    const int height = int(SDL_GetNumberProperty(props, SDL_PROP_TEXTURE_HEIGHT_NUMBER, 0));
    const int needed = SDL_RGBA8BufferSize(width, height, pitch);
    if (needed < 0) return false;
    if (bytes.size < uint32_t(needed) || !bytes.data)
        return SDL_SetError("upload_rgba8: source array too small");
    void * pixels = nullptr;
    int lockedPitch = 0;
    if (!SDL_LockTexture(texture, nullptr, &pixels, &lockedPitch)) return false;
    struct Unlock { SDL_Texture * texture; ~Unlock() { SDL_UnlockTexture(texture); } } unlock{texture};
    if (!pixels || lockedPitch < width * 4) return SDL_SetError("upload_rgba8: invalid SDL lock layout");
    for (int y = 0; y < height; ++y)
        std::memcpy(static_cast<uint8_t *>(pixels) + size_t(y) * lockedPitch,
                    bytes.data + size_t(y) * pitch, size_t(width) * 4);
    return true;
}
inline SDL_Surface * SDL_ReadPixelsOwned(SDL_Renderer * renderer) {
    if (!renderer) { SDL_SetError("read_pixels: null renderer"); return nullptr; }
    return SDL_RenderReadPixels(renderer, nullptr);
}
inline bool SDL_SurfaceSizeRef(const SDL_Surface * surface, int & width, int & height) {
    width = height = 0;
    if (!surface) return SDL_SetError("surface_size: null surface");
    width = surface->w; height = surface->h;
    return true;
}
inline bool SDL_CopySurfaceRGBA8(SDL_Surface * surface, das::TArray<uint8_t> & bytes, int pitch) {
    if (!surface) return SDL_SetError("copy_surface_rgba8: null surface");
    const int needed = SDL_RGBA8BufferSize(surface->w, surface->h, pitch);
    if (needed < 0) return false;
    if (bytes.size < uint32_t(needed) || !bytes.data)
        return SDL_SetError("copy_surface_rgba8: destination array too small");
    std::unique_ptr<SDL_Surface, decltype(&SDL_DestroySurface)> converted(
        SDL_ConvertSurface(surface, SDL_PIXELFORMAT_RGBA32), SDL_DestroySurface);
    if (!converted) return false;
    if (!SDL_LockSurface(converted.get())) return false;
    struct Unlock { SDL_Surface * surface; ~Unlock() { SDL_UnlockSurface(surface); } } unlock{converted.get()};
    if (!converted->pixels || converted->pitch < converted->w * 4)
        return SDL_SetError("copy_surface_rgba8: invalid SDL surface layout");
    for (int y = 0; y < converted->h; ++y)
        std::memcpy(bytes.data + size_t(y) * pitch,
                    static_cast<const uint8_t *>(converted->pixels) + size_t(y) * converted->pitch,
                    size_t(converted->w) * 4);
    return true;
}
