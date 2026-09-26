options gen2
require dassdl3/sdl3_boost
require dassdl3/sdl3_try
require opengl
require math
require daslib/defer
require daslib/safe_addr
require strings
var window : SDL_Window?
var context : SDL_GLContextState?
var frames = 0
var started : uint64
var program : uint
var phase_location : int

def report(result : $Result<SdlUnit; SdlError>) : int {
    if (is_err(result)) {let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return -1}
    return 0
}
// Shader compilation and linking stay explicit in the example.
def compile_shader(kind : uint; source : string) : $Result<uint; SdlError> {
    let shader = glCreateShader(kind)
    if (shader == 0u) {return err(SdlError(operation = "glCreateShader", message = "No shader object"), type<uint>)}
    var shader_source = source
    glShaderSource(shader, 1, safe_addr(shader_source), null)
    glCompileShader(shader)
    var status : int
    glGetShaderiv(shader, GL_COMPILE_STATUS, safe_addr(status))
    if (status == 0) {
        var size : int
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, safe_addr(size))
        var text = repeat(" ", max(size, 1))
        var written : int
        glGetShaderInfoLog(shader, max(size, 1), safe_addr(written), text)
        let message = slice(text, 0, written)
        glDeleteShader(shader)
        return err(SdlError(operation = "glCompileShader", message = message), type<uint>)
    }
    return ok(shader, type<SdlError>)
}
def create_program() : $Result<SdlUnit; SdlError> {
    let vertex = compile_shader(GL_VERTEX_SHADER, "#version 300 es\nuniform float phase;\nout vec3 color;\nvoid main() \{\n    vec2 positions[3]=vec2[3](vec2(0.0,0.7),vec2(-0.7,-0.6),vec2(0.7,-0.6));\n    vec3 colors[3]=vec3[3](vec3(1.0,0.1,0.1),vec3(0.1,1.0,0.1),vec3(0.1,0.1,1.0));\n    vec2 position=positions[gl_VertexID];\n    position.x+=0.1*sin(phase);\n    gl_Position=vec4(position,0.0,1.0);\n    color=colors[gl_VertexID];\n\}") |> sdl_try
    {
        defer() {glDeleteShader(vertex)}
        let fragment = compile_shader(GL_FRAGMENT_SHADER, "#version 300 es\nprecision mediump float;\nin vec3 color;\nout vec4 outputColor;\nvoid main() \{outputColor=vec4(color,1.0);\}") |> sdl_try
        {
            defer() {glDeleteShader(fragment)}
            program = glCreateProgram()
            if (program == 0u) {return err(SdlError(operation = "glCreateProgram", message = "No program object"), type<SdlUnit>)}
            glAttachShader(program, vertex)
            glAttachShader(program, fragment)
            glLinkProgram(program)
            var status : int
            glGetProgramiv(program, GL_LINK_STATUS, safe_addr(status))
            if (status == 0) {
                var size : int
                glGetProgramiv(program, GL_INFO_LOG_LENGTH, safe_addr(size))
                var text = repeat(" ", max(size, 1))
                var written : int
                glGetProgramInfoLog(program, max(size, 1), safe_addr(written), text)
                return err(SdlError(operation = "glLinkProgram", message = slice(text, 0, written)), type<SdlUnit>)
            }
        }
    }
    phase_location = glGetUniformLocation(program, "phase")
    if (phase_location < 0) {return err(SdlError(operation = "glGetUniformLocation", message = "Missing phase uniform"), type<SdlUnit>)}
    return sdl_ok()
}

def initialize() : $Result<SdlUnit; SdlError> {
    sdl_init() |> sdl_try
    SDL_GL_ResetAttributes()
    sdl_status(SDL_GL_SetAttribute(SDL_GLAttr.GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES), "SDL_GL_SetAttribute") |> sdl_try
    sdl_status(SDL_GL_SetAttribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION, 3), "SDL_GL_SetAttribute") |> sdl_try
    sdl_status(SDL_GL_SetAttribute(SDL_GLAttr.GL_CONTEXT_MINOR_VERSION, 0), "SDL_GL_SetAttribute") |> sdl_try
    window = create_window("dasSDL3 WebGL 2", 640, 480, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE) |> sdl_try
    context = SDL_GL_CreateContext(window)
    if (context == null) {return err(sdl_error("SDL_GL_CreateContext"), type<SdlUnit>)}
    sdl_status(SDL_GL_MakeCurrent(window, context), "SDL_GL_MakeCurrent") |> sdl_try
    print("OpenGL ES 3.0 / WebGL 2 via daScript dasOpenGL.\n")
    create_program() |> sdl_try
    started = SDL_GetTicks()
    return sdl_ok()
}
def draw_frame() : $Result<SdlUnit; SdlError> {
    var width, height : int
    sdl_status(SDL_GetWindowSizeInPixelsRef(window, width, height), "SDL_GetWindowSizeInPixels") |> sdl_try
    glViewport(0, 0, width, height)
    glClearColor(18.0 / 255.0, 24.0 / 255.0, 38.0 / 255.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)
    glUseProgram(program)
    glUniform1f(phase_location, float(SDL_GetTicks() - started) / 1000.0)
    // GLSL gl_VertexID supplies three vertices; no client-memory pointers.
    glDrawArrays(GL_TRIANGLES, 0, 3)
    let error = glGetError()
    if (error != uint(GL_NO_ERROR)) {return err(SdlError(operation = "OpenGL frame", message = "GL error {error}"), type<SdlUnit>)}
    sdl_status(SDL_GL_SwapWindow(window), "SDL_GL_SwapWindow") |> sdl_try
    frames++
    if (frames == 60) {print("Rendered 60 frames.\n")}
    return sdl_ok()
}
[export]
def app_init() : int {return report(initialize())}
[export]
def app_frame() : int {return report(draw_frame())}
[export]
def app_event(event : SDL_Event) : int {
    if (should_close(event, window)) {return 1}
    return 0
}
[export]
def app_quit {
    if (program != 0u) {glUseProgram(0u); glDeleteProgram(program); program = 0u}
    if (context != null) {
        if (!SDL_GL_DestroyContext(context)) {let error = sdl_error("SDL_GL_DestroyContext"); print("{error.operation}: {error.message}\n")}
        context = null
    }
    destroy_window(window); window = null
    SDL_Quit()
    print("Session released after {frames} frames.\n")
}
