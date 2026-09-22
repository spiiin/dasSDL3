# Process and LoadSO (P7)

All nine SDL_process.h and three SDL_loadso.h functions from SDL 3.2.18 have
raw bindings. `dassdl3/sdl3_process_loadso` provides Result factories, argv array
conversion, copied binary output with exit code, wait status and deferred release.

argv is a list of arguments, not shell text. The array adapter appends the required
null terminator and borrows strings only while creating the process. No implicit
shell expansion is added. Example 83 runs Windows hostname.exe directly.
The tested cmd.exe /c forms failed with pinned Windows argument quoting. Shell
command-line interpretation needs separate validation; direct executable arguments
with spaces and quotes have their own fixture test.

DestroyProcess (and with_process cleanup) releases tracking and pipes; it does NOT
kill or wait for the child. The body owns that decision. Never destroy borrowed
processes inside the scope. GetProcessInput/Output and process properties are
owned by the process until destruction or explicit close. Closing stdin is supported
and signals EOF; SDL removes the corresponding property, so discard every alias
to the closed stream. Do not retain pipes beyond process destruction. Drain
piped output before a blocking wait or the child can block on a full pipe. Input
and output may require concurrent native servicing for large bidirectional I/O.

read_process returns owned bytes and the integer exit code; a nonzero child exit
is not an SDL error. Like SDL_ReadProcess it blocks and buffers all output: use
stream I/O for untrusted/unbounded output. It checks script array capacity before
copying. Pinned SDL_ReadProcess internally waits after reading, so its own final
error is what raw and boost callers receive.

wait_process returns Result<Option<int>,SdlError>: None is still running. SDL's
raw false sentinel conflates pending with failure, so this helper clears SDL's
thread-local error immediately before the wait and inspects it only after false.
It therefore consumes any previous SDL error; raw SDL_WaitProcess is unchanged.
Background processes report zero exit status, as documented by SDL.

Shared-object pointers own a loaded library; export addresses borrow it. Finish
all calls, workers and retained callbacks before unloading. with_object releases
the library on Result return, including Err, but does not infer dependencies.
Returned native addresses are not daScript functions and have no inferred ABI.
Only explicitly typed native adapters can invoke them safely.

Tests launch a dedicated local fixture executable (output/exit, pending, kill,
properties, missing executable) and load a fixture library (export invocation,
missing symbol, cleanup). Interpreter/AOT and both generators are checked locally
on Windows x64; other OS backends and web process support are not claimed.

`load_function` returns Result<SdlFunctionAddress,SdlError>; its `.address` is a
borrowed void pointer. This single-field payload avoids a pinned daScript generic
collision between Result<void?> and other pointer Results. It is neither an owning
handle nor a callable wrapper. Raw SDL_LoadFunction still returns the native address.
