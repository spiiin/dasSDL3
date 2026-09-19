#pragma once
#include <SDL3/SDL.h>
#include "daScript/daScript.h"
#include <climits>
#include <cmath>

inline SDL_Vertex SDL_MakeVertex(float x, float y, float r, float g, float b, float a, float u, float v) {
    return {{x, y}, {r, g, b, a}, {u, v}};
}
// Bound both source and expanded triangle bytes before converting counts to int.
inline bool SDL_GeometryCountsValid(uint32_t vertices, uint32_t indices, bool indexed) {
    constexpr uint32_t limit = INT_MAX / sizeof(SDL_Vertex);
    if (vertices > limit || indices > limit)
        return SDL_SetError("geometry: vertex/index count exceeds byte budget");
    if ((indexed ? indices : vertices) % 3 != 0)
        return SDL_SetError("geometry: triangle count must be a multiple of three");
    return true;
}
inline bool SDL_GeometryUnit(float value) { return std::isfinite(value) && value >= 0.0f && value <= 1.0f; }
inline bool SDL_RenderGeometryChecked(SDL_Renderer * renderer, SDL_Texture * texture,
        const das::TArray<SDL_Vertex> & vertices, const das::TArray<int32_t> * indices) {
    if (!renderer) return SDL_SetError("geometry: null renderer");
    const uint32_t count = indices ? indices->size : 0;
    if (!SDL_GeometryCountsValid(vertices.size, count, indices != nullptr)) return false;
    // Explicit empty indexed draws must NOT fall back to sequential vertices.
    if ((indices ? count : vertices.size) == 0) return true;
    if (!vertices.size || !vertices.data || (indices && !indices->data))
        return SDL_SetError("geometry: missing vertex/index storage");
    const auto * verts = reinterpret_cast<const SDL_Vertex *>(vertices.data);
    const auto * inds = indices ? reinterpret_cast<const int32_t *>(indices->data) : nullptr;
    for (uint32_t i = 0; i < count; ++i)
        if (inds[i] < 0 || uint32_t(inds[i]) >= vertices.size)
            return SDL_SetError("geometry: index out of bounds");
    for (uint32_t i = 0; i < vertices.size; ++i) {
        const auto & v = verts[i];
        if (!std::isfinite(v.position.x) || !std::isfinite(v.position.y) ||
            !SDL_GeometryUnit(v.color.r) || !SDL_GeometryUnit(v.color.g) ||
            !SDL_GeometryUnit(v.color.b) || !SDL_GeometryUnit(v.color.a) ||
            !SDL_GeometryUnit(v.tex_coord.x) || !SDL_GeometryUnit(v.tex_coord.y))
            return SDL_SetError("geometry: non-finite position or color/UV outside 0..1");
    }
    // SDL consumes array data during this call. It may queue its own copied data.
    return SDL_RenderGeometry(renderer, texture, verts, int(vertices.size), inds, int(count));
}
inline bool SDL_RenderGeometryVertices(SDL_Renderer * renderer, SDL_Texture * texture,
        const das::TArray<SDL_Vertex> & vertices) {
    return SDL_RenderGeometryChecked(renderer, texture, vertices, nullptr);
}
inline bool SDL_RenderGeometryIndices(SDL_Renderer * renderer, SDL_Texture * texture,
        const das::TArray<SDL_Vertex> & vertices, const das::TArray<int32_t> & indices) {
    return SDL_RenderGeometryChecked(renderer, texture, vertices, &indices);
}
