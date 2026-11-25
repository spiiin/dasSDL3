#pragma once

#include <SDL3/SDL.h>
#include <algorithm>

namespace dassdl3_ios {
inline bool drawSensorPanel(SDL_Renderer *renderer, const SDL_FRect &panel, const char *label,
                            const float (&values)[3], bool ready, float range) {
    const SDL_Color axes[] = {{77, 215, 255, 255}, {255, 183, 86, 255}, {193, 143, 255, 255}};
    const char *names[] = {"X", "Y", "Z"};
    if (!SDL_SetRenderDrawColor(renderer, 26, 42, 59, 255) || !SDL_RenderFillRect(renderer, &panel) ||
        !SDL_SetRenderDrawColor(renderer, 237, 246, 255, 255) ||
        !SDL_RenderDebugText(renderer, panel.x + 12, panel.y + 14, label)) return false;

    for (int axis = 0; axis < 3; ++axis) {
        const float y = panel.y + 33 + axis * 30;
        const SDL_FRect track{panel.x + 29, y, panel.w - 105, 16};
        const float center = track.x + track.w * 0.5f;
        const float end = center + std::clamp(values[axis] / range, -1.0f, 1.0f) * track.w * 0.5f;
        const auto color = axes[axis];
        const SDL_FRect meter{std::min(center, end), y + 2, SDL_fabsf(end - center), 12};
        char number[24];
        SDL_snprintf(number, sizeof(number), "%+.2f", static_cast<double>(values[axis]));
        if (!SDL_SetRenderDrawColor(renderer, 12, 23, 35, 255) || !SDL_RenderFillRect(renderer, &track) ||
            !SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a) ||
            !SDL_RenderDebugText(renderer, panel.x + 12, y + 4, names[axis]) ||
            !SDL_RenderDebugText(renderer, track.x + track.w + 8, y + 4, ready ? number : "--") ||
            (ready && meter.w > 0 && !SDL_RenderFillRect(renderer, &meter)) ||
            !SDL_SetRenderDrawColor(renderer, 209, 226, 239, 255) ||
            !SDL_RenderLine(renderer, center, y, center, y + track.h)) return false;
    }
    return true;
}

inline bool drawSensorDashboard(SDL_Renderer *renderer, float density,
                                const float (&accel)[3], bool accelReady,
                                const float (&gyro)[3], bool gyroReady,
                                const char *instruction = "Tilt the phone. Tap to finish.") {
    SDL_Rect safe;
    const float scale = density * 1.5f;
    if (!SDL_SetRenderScale(renderer, scale, scale) || !SDL_GetRenderSafeArea(renderer, &safe)) return false;
    constexpr float margin = 16;
    constexpr float gap = 12;
    constexpr float cardHeight = 127;
    const float width = safe.w - 2 * margin;
    const bool landscape = safe.w > safe.h;
    const float cardWidth = landscape ? (width - gap) * 0.5f : width;
    const float x = safe.x + margin;
    const float y = safe.y + 45;
    const SDL_FRect left{x, y, cardWidth, cardHeight};
    const SDL_FRect right{landscape ? x + cardWidth + gap : x, landscape ? y : y + cardHeight + gap,
                          cardWidth, cardHeight};
    return SDL_SetRenderDrawColor(renderer, 10, 19, 30, 255) && SDL_RenderClear(renderer) &&
           SDL_SetRenderDrawColor(renderer, 237, 246, 255, 255) &&
           SDL_RenderDebugText(renderer, x, safe.y + 19, "iPhone motion sensors") &&
           drawSensorPanel(renderer, left, "Accelerometer (m/s^2)", accel, accelReady, 12.0f) &&
           drawSensorPanel(renderer, right, "Gyroscope (rad/s)", gyro, gyroReady, 4.0f) &&
           SDL_SetRenderDrawColor(renderer, 164, 187, 204, 255) &&
           SDL_RenderDebugText(renderer, x, right.y + cardHeight + gap, instruction) &&
           SDL_RenderPresent(renderer);
}
}
