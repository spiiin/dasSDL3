# Filesystem (P4)

Pinned SDL 3.2.18, Windows x64/MSVC. All 11 SDL_filesystem.h functions
are generated, including the native-address SDL_EnumerateDirectory callback.
SDL_Folder, SDL_PathType, SDL_EnumerationResult and SDL_GLOB_CASEINSENSITIVE
are exported. SDL_PathInfo exposes all fields; `type` is named `path_type`
in daScript because `type` is reserved. Timestamps retain SDL_Time units.

## Ownership and errors

`require dassdl3/sdl3_filesystem_boost` provides 11 small Result helpers:
base_path, pref_path, user_folder, current_directory, create_directory,
remove_path, rename_path, copy_file, path_info, glob_directory, enumerate_directory.
The latter two return Result<array<string>, SdlError>; use move initializers.
No initialization scope or new filesystem object is required.

Raw BasePath/UserFolder strings are borrowed; PrefPath/CurrentDirectory strings
and GlobDirectory's single allocation must be released with SDL_free.
Boost copies strings immediately and releases owned native allocations. Successful
path getters produce nonempty paths; empty strings therefore denote failure in
these four helpers. Error text is copied only after the failed operation.
PrefPath can create directories in the application's preference location.

PathInfo on a missing path returns Err, as required by SDL, not None.
Glob returns an empty successful array when no paths match; its default pattern
is "*". SDL patterns can include subdirectories separated by "/"; wildcards
do not cross path separators. A null string disables filtering in the raw/adapted call.
Enumeration returns
entry names (not combined absolute paths), with unspecified order; the input
path identifies their parent. Names are copied, including UTF-8. Enumeration
collects native strings synchronously and allocates script strings after SDL
returns; no script callbacks are retained or invoked by this adapter.
Raw EnumerateDirectory accepts a C callback address and userdata, borrowed only
until return. CONTINUE visits more entries, SUCCESS stops successfully, FAILURE
stops unsuccessfully. A callback should set SDL error text for its own failure.

CreateDirectory also creates missing parents and succeeds for existing directories.
RemovePath removes a file or empty directory only; it is never recursive.
Raw SDL behavior is preserved for missing paths, failed operations and partial
filesystem changes. Copies/renames are not a transaction. PathInfo is a snapshot,
not a permission or lifetime guarantee for a subsequent operation.

## Verification

[Tests](../tests/filesystem.das) exercise every raw function, copied lists,
copy byte contents, rename/remove, directory and file metadata, unmatched glob,
early callback success/failure, saved error text and copied names after removal.
Test files use unique relative directories and nonrecursive cleanup of known paths.
PrefPath's failure path is tested without creating a real user preference directory;
its successful platform-specific directory creation is not certified by this test.
UserFolder may fail under sandbox/OS restrictions; tests check that error contract
instead of assuming a usable home folder on every host.
[Example 73](../examples/73_filesystem.das) reads and prints the current directory.

IOStream, Storage and AsyncIO remain the following P4 packages. In particular,
this package does not establish custom I/O callback or async-buffer lifetimes.

Local verification: 2 main tests, 7 baseline/CppGenBind/strict-AOT and metadata
checks, 6 generation/inventory/boundary gates and 4 standalone clangbind checks
passed. BUILD_TESTING=OFF consumer built with LLVM/Clang/Python discovery disabled;
example 73 and the public API boundary check passed. This is Windows-profile
validation, not cross-platform filesystem certification.
