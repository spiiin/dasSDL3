# IOStream (P4)

Pinned SDL 3.2.18, Windows x64/MSVC. SDL_iostream.h has 48 functions:
46 generated raw signatures, one fixed-text SDL_IOprintfText adapter, and
SDL_IOvprintf pending (native va_list ABI). Arbitrary printf varargs are not
exposed. Format text in daScript before passing it to SDL_IOprintfText; percent
characters are literal. SDL_IOStatus and SDL_IOWhence are available. The seven
SDL_PROP_IOSTREAM_* string macros are registered from the pinned native values.

## Ownership

`require dassdl3/sdl3_iostream_boost` provides file/dynamic/custom stream factories,
with_io_file / with_io_dynamic / with_io scopes, close_io, seek/tell/size,
byte transfer and file/stream load/save helpers. Factories return Result pointers;
Result itself does not own the resource. Extract factory pointers with sdl_try,
or move_unwrap from a mutable Result after checking is_ok. `with_io` adopts an existing pointer.
Use `sdl_scope` and typed pipe-style `sdl_use` for linear scopes.

SDL_CloseIO consumes the stream even when closing fails. `close_io` nulls its
reference before calling SDL. Scopes use defer, close exactly once on normal and
early Result returns, report close failures after successful bodies, and preserve
primary body errors over cleanup errors. They do not catch application panic.
Do not close or retain the stream borrowed by a scope, or call consuming raw
LoadFile_IO/SaveFile_IO with closeio=true on it. No implicit flush is added.
SDL_GetIOProperties is borrowed; do not destroy those properties independently.

Raw IOFromMem / IOFromConstMem retain external memory until close. The memory must
stay alive and at a stable address, and must not be resized or freed. They do not
own that memory. No unrestricted array-to-retained-pointer helper is provided.
Dynamic streams own their storage. Their memory property is borrowed and may move
on writes; setting it to NULL transfers ownership as specified by SDL. The binding
does not manage such explicitly detached native allocations.

## Partial transfers

`read_io(stream, bytes, count, transferred, offset=0)` and `write_io` use bounded
array storage only during the synchronous call. Count and offset are uint64;
bounds are checked before pointer arithmetic. No implicit retry occurs.
Their Result value is SDL_IOStatus: READY, EOF and NOT_READY remain distinct.
ERROR/READONLY/WRITEONLY return SdlError. `transferred` is always set, including
on error, so partial progress is not lost. Only the transferred read prefix is
modified; the rest of the caller's buffer is preserved. After a partial write,
advance offset and reduce count before retrying. A short transfer may still be
READY in SDL; a following read establishes EOF. A zero-byte operation is not an
EOF probe. SDL error strings left by unrelated operations do not imply failure.
`flush_io` returns Result<bool>: true is flushed; false is temporarily NOT_READY.

All 28 endian scalar functions are raw; 14 Read*Ref adapters avoid unsafe addresses.
Unsigned 8/16-bit ref adapters widen through native temporary storage into `uint&`.
Raw pointer readers still need actual uint8/uint16 storage. Signed narrow types
remain int8/int16. The adapters preserve bool failure/EOF rather than manufacturing
an error from SDL_GetError, which can be empty on EOF.

Load helpers copy bytes into script arrays, release SDL allocations and exclude
SDL's extra trailing NUL. Embedded zero bytes and empty files are supported.
Array loads are limited to INT_MAX bytes. load_io/save_io borrow the stream and
leave it open. These SDL bulk operations can wait internally on NOT_READY and
are intended for blocking streams; use individual read_io/write_io for readiness
control. load_io rejects a terminal error status even if SDL returned a partial
buffer. Raw LoadFile_IO can return such a buffer; inspect status before close.
load_file follows SDL_LoadFile's allocation result and cannot recover stream status
that SDL discarded on close; use an explicit stream and load_io when this matters.

## Native custom interfaces

SDL_MakeIOStreamInterface applies SDL_INIT_INTERFACE, SDL_SetIOStreamInterfaceCallbacks
sets all six native function addresses, and SDL_OpenIORef borrows the descriptor
for creation. SDL copies the interface but retains userdata and callback addresses
until close. Callbacks must match SDL calling conventions and signatures; they must
respect byte capacities and report status/error text for partial operations.
They are native C functions, not daScript Func/Block values. The caller owns their
code/userdata lifetimes and serializes access to the non-thread-safe stream.
A failed OpenIO does not invoke the interface close callback.

## Pinned SDL defects and validation limits

SDL 3.2.18 SaveFile_IO advances using the previous write size instead of cumulative
progress. Three successive two-byte writes of [0,1,2,3,4,5] produce [0,1,2,3,2,3].
Raw behavior and the thin save_io array adapter preserve this upstream behavior.
For streams that can short-write, use write_io with an explicit cumulative offset.
Bulk load also continues after positive reads before checking terminal status;
a custom callback must obey SDL's status contract, and bulk load is not a lossless
partial-progress API. Raw bulk closeio ignores CloseIO's boolean result. Use explicit
scopes when close errors must be reported. No changes are made to pinned SDL source.

[Transfer/lifetime tests](../tests/iostream.das) cover file/dynamic/fixed/readonly
streams, zero/short reads, EOF, NOT_READY, partial errors and their counts, offset
bounds, saved errors, native callbacks, interface copying, acquisition failure,
close failure, primary error precedence, move-only bodies and the pinned save bug.
[Endian tests](../tests/iostream_endian.das) execute all 28 raw scalar functions
against an independent byte oracle and all 14 ref adapters.
[Example 74](../examples/74_iostream.das) shows an in-memory roundtrip with sdl_try
and sdl_scope/sdl_use, without unsafe pointers. Real pipes, sockets, Android/stdio/
Windows-handle properties and other OS backends are not certified by these tests.

Local validation: 3 main tests/example, 10 baseline/CppGenBind/strict-AOT/metadata
checks, 6 generation/inventory/boundary gates and 4 standalone clangbind checks
passed. All 46 generated functions are directly called by the two test scripts.
The BUILD_TESTING=OFF consumer built with LLVM/Clang/Python discovery disabled;
example 74 and public boundary checks passed, and SDLTestIOCloses was unavailable.
