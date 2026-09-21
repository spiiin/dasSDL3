# Storage (P4)

SDL 3.2.18, Windows x64/MSVC: all 17 SDL_storage.h functions have generated raw
signatures. SDL_Storage is opaque; SDL_StorageInterface exposes its version and
native callback-address setters for all 11 fields. SDL_MakeStorageInterface uses
SDL_INIT_INTERFACE. No script callbacks are retained.

## API and ownership

`require dassdl3/sdl3_storage_boost` exposes Result factories for file/title/user/
custom storage, scalar/ref queries, bounded byte arrays, copied file contents and
copied enumeration/glob names. Use `<-` and sdl_try for returned arrays. Empty files
and unmatched glob are successful empty arrays; missing files are errors.
Enumeration returns entry names in unspecified order; join with the requested path
if needed. NULL or an empty enumeration path selects the storage root.

with_file_storage / with_title_storage / with_user_storage acquire and own one
SDL_Storage. with_storage adopts an existing storage pointer. These helpers use
ordinary defer and pass the Result of the body outward. They report failed close
only after a successful body, preserving the primary body error otherwise.
SDL_CloseStorage consumes even on failure; close_storage nulls the caller's pointer
before calling SDL. Closing NULL remains an SDL error. Do not close or retain the
borrowed pointer from a scope. Arbitrary panic does not guarantee cleanup.
No implicit wait, readiness loop, flush or retry is added.

StorageReady/storage_ready is a bool predicate: false means not ready for a valid
storage, not proof of an SDL failure. Callers must check readiness before access.
GetStorageSpaceRemaining/storage_space_remaining preserves the uint64 value;
zero is ambiguous (no capacity, unsupported or failure). Generic file storage in
this pinned SDL returns UINT64_MAX instead of querying the actual disk quota.
Do not interpret a stale SDL error as failure after a successful operation.

## Bytes and paths

ReadStorageFile and WriteStorageFile are synchronous. Array adapters borrow script
memory only until return and reject counts beyond capacity before calling SDL.
A failed read can have modified a prefix of the caller's array; SDL reports only a
bool, not a partial byte count. Read length must equal the file length according
to SDL's contract; first query GetStorageFileSize. load_storage_file does this,
limits allocation to INT_MAX bytes, clears output on failure and returns owned
bytes on success. The size query and read are not atomic: concurrent changes can
still fail or invalidate a snapshot. Empty-file operations use valid zero-length
buffer storage. No arbitrary array pointers escape into a storage object.

Paths inside storage use '/' and reject '.'/'..' components and backslashes.
The root passed to OpenFileStorage/OpenTitleStorage is an OS path, not an internal
storage path. Storage is not a security sandbox; no symlink containment guarantee
is added. File/title opening may succeed for a nonexistent root; operations later
report failure. File storage is writable; generic title storage is read-only.
User storage can choose platform/cloud backends and creates application-specific
locations; closing may finalize platform work, so check its Result.

## Native callback contracts

OpenStorage copies the interface but borrows native function addresses and userdata
until close. The caller owns their code, synchronization and userdata lifetime;
failed creation does not invoke close. Set callbacks with SDL_SetStorageInterface_*
using native C addresses matching SDL's exact signatures and calling convention.
These are not daScript Func/Block values. A native enumerate implementation must
forward dirname/name to the supplied callback, honor CONTINUE/SUCCESS/FAILURE and
not retain that enumeration callback or its userdata. Copied-list adapters collect
native strings first and allocate script strings after enumeration returns.
SDL does not universally check readiness or make custom storage thread-safe.

## Validation

[Tests](../tests/storage.das) directly invoke all 17 raw functions. File and custom
backends cover binary/empty files, UTF-8 names, copy/rename/remove, path metadata,
invalid paths, short source/capacity errors, copied lists, empty glob and native
enumeration stop/failure. All 11 custom interface callbacks execute, including
pending readiness and zero space. Scopes test consumed pointers, close failure,
primary error precedence, acquisition failure and move-only array results.
Title storage rejects writing. User storage's invalid-application failure path is
tested without creating a real preference directory. Positive user/cloud storage,
real quota accounting, other platforms and hardware are not certified.
[Example 75](../examples/75_storage.das) reads the current directory through file
storage using sdl_scope/sdl_use and sdl_try, without modifying user files.

Local checks passed: 2 main tests/example, 7 baseline/CppGenBind/strict-AOT and
metadata checks, 6 generation/inventory/boundary gates and 4 standalone clangbind
checks. BUILD_TESTING=OFF consumer built without LLVM/Clang/Python discovery;
example 75 and boundary checks passed, and test-only storage exports were absent.
