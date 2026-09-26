options gen2
require sdl3
require daslib/rtti
require strings

[export]
def main(smoke : bool) : int {
    verify(smoke)
    var first = ""
    var second = ""
    var caught = false
    try {
        try { panic("first") } recover {
            first := rtrim(this_context().last_exception)
            panic("second")
        }
    } recover {
        second := rtrim(this_context().last_exception)
        caught = true
    }
    verify(caught && first == "first" && second == "second", "recover saw stale panic")
    verify(SDL_GetVersion() == 3004016)
    print("Recover sees current panic; rethrow reaches outer handler: OK\n")
    return 0
}
