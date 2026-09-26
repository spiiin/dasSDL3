# Rect, Clipboard and window hit testing

All Rect and Clipboard functions plus SetWindowHitTest have native registrations.
Native callback parameters are native function addresses (void pointers in daScript),
not script functions or blocks. Never reinterpret a daScript function as a C callback.

Rect helpers preserve SDL integer/float boundary and empty-rectangle semantics.
Array adapters borrow points synchronously. Clipboard text/data/mime copy adapters
copy into script-owned storage and free SDL allocations. Raw getters return owned
allocations and require SDL_free (the MIME array is one allocation).

The copied clipboard setter offers one MIME payload at a time. Raw SetClipboardData
supports multiple MIME types and lazy native providers. The copy's lifetime is owned
by SDL cleanup, including replacement, clear and Quit. In the pinned SDL a backend
error can occur after callback ownership was accepted; a false return does not imply
that raw userdata is safe to release. The copied adapter handles both retained and
immediately cleaned-up failure paths without invoking script from clipboard callbacks.

with_window_hit_test borrows a script block and its live Context only inside its
lexical scope, then unregisters via defer. The helper is never_inline so AOT block
temporaries survive the whole call. Script callbacks receive window, x and y values. Only use it on the main thread. Reentrant
hit tests return NORMAL; callback results must be valid SDL_HitTestResult values.
Do not panic, yield, destroy the window, quit SDL, or change hit-test registration
inside the callback. Do not mix raw registration/replacement with an active scope.
Nested scopes on the same window are rejected. A window destroyed by the scope body
invalidates the token through a property cleanup observer; deferred teardown is safe.
Existing raw callbacks are not restored: enter only with no hit-test registration.
No callback cleanup after an application panic is promised.

Clipboard runtime tests use SDL_VIDEODRIVER=dummy and do not read or overwrite the
system clipboard. Windows hit-test tests drive WM_NCHITTEST through SDL's window
procedure; native test helpers provide callback addresses and OS event injection only.
GL/EGL (20 Video functions) is explicitly deferred to P8. It no longer blocks P2.
