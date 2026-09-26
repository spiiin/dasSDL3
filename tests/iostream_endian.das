options gen2
require dassdl3/sdl3_iostream_boost
require daslib/safe_addr
[export]
def main(smoke : bool) : int {
    let io = SDL_IOFromDynamicMem()
    verify(io != null)
    verify(SDL_WriteU8(io, 225u))
    verify(SDL_WriteS8(io, int8(-2)))
    verify(SDL_WriteU16LE(io, 41394u))
    verify(SDL_WriteS16LE(io, int16(-2)))
    verify(SDL_WriteU16BE(io, 41394u))
    verify(SDL_WriteS16BE(io, int16(-2)))
    verify(SDL_WriteU32LE(io, 2712847316u))
    verify(SDL_WriteS32LE(io, -2))
    verify(SDL_WriteU32BE(io, 2712847316u))
    verify(SDL_WriteS32BE(io, -2))
    verify(SDL_WriteU64LE(io, 11651590505119483672ul))
    verify(SDL_WriteS64LE(io, int64(-2)))
    verify(SDL_WriteU64BE(io, 11651590505119483672ul))
    verify(SDL_WriteS64BE(io, int64(-2)))
    verify(SDL_SeekIO(io, 0l, SDL_IOWhence.IO_SEEK_SET) == 0l)
    var actual : array<uint8>
    resize(actual, 58)
    var count = 0ul
    verify(is_ok(read_io(io, actual, uint64(length(actual)), count)))
    let expected <- array<uint8>(225, 254, 178, 161, 254, 255, 161, 178, 255, 254, 212, 195, 178, 161, 254, 255, 255, 255, 161, 178, 195, 212, 255, 255, 255, 254, 24, 7, 246, 229, 212, 195, 178, 161, 254, 255, 255, 255, 255, 255, 255, 255, 161, 178, 195, 212, 229, 246, 7, 24, 255, 255, 255, 255, 255, 255, 255, 254)
    verify(count == uint64(length(expected)))
    for (i in range(length(expected))) {verify(actual[i] == expected[i])}
    verify(SDL_SeekIO(io, 0l, SDL_IOWhence.IO_SEEK_SET) == 0l)
    var v0 : uint8
    verify(SDL_ReadU8(io, safe_addr(v0)) && v0 == uint8(225))
    var v1 : int8
    verify(SDL_ReadS8(io, safe_addr(v1)) && v1 == int8(-2))
    var v2 : uint16
    verify(SDL_ReadU16LE(io, safe_addr(v2)) && v2 == uint16(41394))
    var v3 : int16
    verify(SDL_ReadS16LE(io, safe_addr(v3)) && v3 == int16(-2))
    var v4 : uint16
    verify(SDL_ReadU16BE(io, safe_addr(v4)) && v4 == uint16(41394))
    var v5 : int16
    verify(SDL_ReadS16BE(io, safe_addr(v5)) && v5 == int16(-2))
    var v6 : uint
    verify(SDL_ReadU32LE(io, safe_addr(v6)) && v6 == 2712847316u)
    var v7 : int
    verify(SDL_ReadS32LE(io, safe_addr(v7)) && v7 == -2)
    var v8 : uint
    verify(SDL_ReadU32BE(io, safe_addr(v8)) && v8 == 2712847316u)
    var v9 : int
    verify(SDL_ReadS32BE(io, safe_addr(v9)) && v9 == -2)
    var v10 : uint64
    verify(SDL_ReadU64LE(io, safe_addr(v10)) && v10 == 11651590505119483672ul)
    var v11 : int64
    verify(SDL_ReadS64LE(io, safe_addr(v11)) && v11 == int64(-2))
    var v12 : uint64
    verify(SDL_ReadU64BE(io, safe_addr(v12)) && v12 == 11651590505119483672ul)
    var v13 : int64
    verify(SDL_ReadS64BE(io, safe_addr(v13)) && v13 == int64(-2))
    verify(SDL_SeekIO(io, 0l, SDL_IOWhence.IO_SEEK_SET) == 0l)
    var ref0 = 0xffffffffu
    verify(SDL_ReadU8Ref(io, ref0) && ref0 == uint(v0))
    verify(SDL_ReadS8Ref(io, v1) && v1 == int8(-2))
    var ref2 = 0xffffffffu
    verify(SDL_ReadU16LERef(io, ref2) && ref2 == uint(v2))
    verify(SDL_ReadS16LERef(io, v3) && v3 == int16(-2))
    var ref4 = 0xffffffffu
    verify(SDL_ReadU16BERef(io, ref4) && ref4 == uint(v4))
    verify(SDL_ReadS16BERef(io, v5) && v5 == int16(-2))
    verify(SDL_ReadU32LERef(io, v6) && v6 == 2712847316u)
    verify(SDL_ReadS32LERef(io, v7) && v7 == -2)
    verify(SDL_ReadU32BERef(io, v8) && v8 == 2712847316u)
    verify(SDL_ReadS32BERef(io, v9) && v9 == -2)
    verify(SDL_ReadU64LERef(io, v10) && v10 == 11651590505119483672ul)
    verify(SDL_ReadS64LERef(io, v11) && v11 == int64(-2))
    verify(SDL_ReadU64BERef(io, v12) && v12 == 11651590505119483672ul)
    verify(SDL_ReadS64BERef(io, v13) && v13 == int64(-2))
    var eof : uint64
    verify(!SDL_ReadU64BERef(io, eof) && SDL_GetIOStatus(io) == SDL_IOStatus.IO_STATUS_EOF)
    verify(SDL_CloseIO(io))
    print("IOStream: all 28 endian read/write functions and reference adapters passed.\n")
    return 0
}
