# System, Power, Locale, Dialog and Tray (P7)

Pinned Windows SDL 3.2.18 coverage: System 13/13, Power 1/1, Locale 1/1,
Dialog 4/4 and Tray 23/23 raw functions. This is the active Windows header census;
Android/iOS/Linux/GDK-only declarations require their own generation profiles.
SDL_SetX11EventHook is declared on Windows but calls a stub there.

## Queries

`dassdl3/sdl3_platform_services` provides power_info Result with Option seconds
and percent: -1 means unavailable, POWERSTATE_UNKNOWN is not an error.
preferred_locales returns an owned array with copied language/country strings;
country may remain null. Raw GetPreferredLocales returns one SDL allocation:
free only that outer allocation with SDL_free. Locale lists can change; refresh
after SDL_EVENT_LOCALE_CHANGED. DXGI output returns Result<int2> indices, subject
to video backend availability. Lifecycle notifications are OS-to-SDL hooks, not
commands for suspending/resuming the operating system. Pinned SDL delivers these
six lifecycle events synchronously to native event watchers, not the polling queue.
Native message hooks must
return quickly and must be removed before freeing code/userdata.

## Tray ownership

CreateTray/with_tray owns the tray. Menus, submenus and entries are children;
remove an entry or destroy its tray to release them. Removing a parent recursively
invalidates descendants. tray_entries copies only the pointer list, not entries;
all pointers still borrow their native owners. tray_entry_label copies the text.
Main-thread restrictions apply to tray operations, including scope cleanup.
Pinned Windows SDL dereferences a documented nullable tooltip. Boost creation
normalizes an empty/null script tooltip to an empty C string via SDL_CreateTrayText;
raw CreateTray/SetTrayTooltip remain unchanged and need a nonnull string on this
pinned backend.
Void setters retain SDL's contract: never infer errors from stale SDL_GetError.
Callbacks are native C addresses with caller-owned userdata until unregistered or
the entry is destroyed. ClickTrayEntry deliberately invokes the native callback.
No script callback is retained and no event dispatcher/framework is introduced.
Pinned Windows CreateTray does not check the return of Shell_NotifyIcon; a nonnull
tray is not proof that a visible notification icon appeared.

## Dialog callbacks

Dialog functions are asynchronous and return void, not a synchronous Result.
Only native SDL_DialogFileCallback addresses are accepted. Never pass a daScript
Func/Block or a callback that concurrently enters the same Context. Keep callback
code, userdata, filters and their strings alive at stable addresses until completion; retain the
parent window as required by its platform. Filters are not copied by this binding. `SDL_MakeDialogFileFilter(name,pattern)`
constructs the raw record with borrowed string pointers; keep both strings alive.
Patterns must be nonnull and nonempty (for example `png;jpg` or `*`): the pinned
validator is not null/empty-safe.
Copy selected UTF-8 paths inside the native callback before it returns. filelist
NULL is error (copy SDL_GetError there on that callback thread); a nonnull empty
list is cancellation; a nonempty list is selection. Do not SDL_free this list.
The raw API has no cancellation token, join or safe synchronous scoped owner, so
no with_dialog abstraction or immediate success Result is manufactured.

## Validation limits

Tests execute power/locales, display failures and available native queries, a
posted Windows message hook, lifecycle event delivery, tray hierarchy/state,
native callback invocation/removal, copied labels/lists and Result cleanup.
Dialog tests use real invalid-filter callbacks and the folder null-callback no-op;
they do NOT claim interactive file selection/cancellation or foreign-thread success
validation. X11 and other OS backends remain untested. These desktop bindings do
not expand the Web profile. Examples 84/85 use no test fixtures or unsafe code.
