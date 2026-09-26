options gen2
require dassdl3/sdl3_ttf_boost
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope

def show_shaping(renderer : SDL_Renderer?; title,arabic,latin : TTF_Text?; smoke : bool) {
    title |> set_text_color(uint4(210u,215u,225u,255u)) |> sdl_try
    arabic |> set_text_color(uint4(100u,215u,255u,255u)) |> sdl_try
    latin |> set_text_color(uint4(255u,205u,100u,255u)) |> sdl_try
    let size = arabic |> text_size() |> sdl_try
    var running = true
    var frames = 0
    var event = SDL_MakeEvent()
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event)) { running = false }
        }
        if (!running) { break }
        renderer |> clear(uint4(25u,30u,40u,255u)) |> sdl_try
        title |> draw_text(30.0,20.0) |> sdl_try
        // A single Arabic run: input stays in logical Unicode order.
        // Explicit RTL shaping, right-aligned using the measured advance.
        arabic |> draw_text(690.0-float(size.x),85.0) |> sdl_try
        latin |> draw_text(30.0,240.0) |> sdl_try
        renderer |> present() |> sdl_try
        frames++
        if (smoke && frames == 3) { break }
        SDL_Delay(16u)
    }
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let assets = "{SDL_GetBasePath()}assets/libraries/"
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        with_ttf() |> sdl_use
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        let window : SDL_Window? = with_window("SDL_ttf shaping - Escape to exit",720,400,flags) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let label_font : TTF_Font? = with_font("{assets}JetBrainsMono-Regular.ttf",20.0) |> sdl_use
        let arabic_font : TTF_Font? = with_font("{assets}Amiri-Regular.ttf",56.0) |> sdl_use
        let latin_font : TTF_Font? = with_font("{assets}Amiri-Regular.ttf",36.0) |> sdl_use
        arabic_font |> set_font_direction(TTF_Direction.DIRECTION_RTL) |> sdl_try
        arabic_font |> set_font_script("Arab") |> sdl_try
        arabic_font |> set_font_language("ar") |> sdl_try
        latin_font |> set_font_direction(TTF_Direction.DIRECTION_LTR) |> sdl_try
        latin_font |> set_font_script("Latn") |> sdl_try
        latin_font |> set_font_language("en") |> sdl_try
        let engine : TTF_TextEngine? = renderer |> with_renderer_text_engine() |> sdl_use
        let title : TTF_Text? = engine |> with_text(label_font,"HarfBuzz: Arabic joining and mark positioning") |> sdl_use
        let arabic : TTF_Text? = engine |> with_text(arabic_font,"سَلَامٌ عَلَيْكُمْ") |> sdl_use
        let latin : TTF_Text? = engine |> with_text(latin_font,"Latin ligatures: office\nComposed / combining: café / café") |> sdl_use
        return show_shaping(renderer,title,arabic,latin,smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("HarfBuzz Arabic/Latin shaping example completed.\n")
    return 0
}
