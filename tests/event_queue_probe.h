#pragma once
namespace sdl3_test {
inline char drop_source[64] = "source application";
inline char drop_data[96] = u8"\u0444\u0430\u0439\u043b-\u65e5\u672c.txt";
inline SDL_Event drop_event(uint32_t type, uint32_t window_id) {
    SDL_Event event{};
    event.type = type; event.drop.timestamp = 0xfedcba9876543210ull;
    event.drop.windowID = window_id; event.drop.x = 12.5f; event.drop.y = -4.5f;
    event.drop.source = drop_source;
    if (type == SDL_EVENT_DROP_TEXT || type == SDL_EVENT_DROP_FILE) event.drop.data = drop_data;
    return event;
}
inline void mutate_drop_text() {
    SDL_strlcpy(drop_source,"changed source",sizeof(drop_source));
    SDL_strlcpy(drop_data,"changed data",sizeof(drop_data));
}
}
