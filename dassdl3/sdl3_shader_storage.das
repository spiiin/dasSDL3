options gen2
module sdl3_shader_storage shared public
require dassdl3/sdl3_shader_storage_pack public
require dassdl3/sdl3_try

def public gpu_dsl_storage_bytes(values : array<auto>) {
    var bytes : array<uint8>
    pack_gpu_dsl_storage(values, bytes) |> sdl_try
    return <- move_ok(bytes, type<SdlError>)
}
