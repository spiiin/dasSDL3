#pragma once
#include <limits>
#include <cstring>
namespace sdl3_test {
inline bool geometry_count_guards(SDL_Renderer * renderer) {
    // Deliberately oversized metadata, no enormous allocation and no valid data.
    das::TArray<SDL_Vertex> vertices{};
    vertices.size = UINT32_MAX;
    if (SDL_RenderGeometryVertices(renderer, nullptr, vertices) ||
        !std::strstr(SDL_GetError(), "byte budget")) return false;
    vertices.size = 0;
    das::TArray<int32_t> indices{};
    indices.size = UINT32_MAX;
    return !SDL_RenderGeometryIndices(renderer, nullptr, vertices, indices) &&
        std::strstr(SDL_GetError(), "byte budget") != nullptr;
}
inline SDL_Vertex nonfinite_vertex(int field) {
    auto v = SDL_MakeVertex(8, 8, 1, 1, 1, 1, 0, 0);
    if (field == 0) v.position.x = std::numeric_limits<float>::infinity();
    if (field == 1) v.color.r = std::numeric_limits<float>::quiet_NaN();
    if (field == 2) v.tex_coord.y = std::numeric_limits<float>::infinity();
    return v;
}
}
