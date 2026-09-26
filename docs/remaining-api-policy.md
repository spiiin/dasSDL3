# Remaining non-Stdinc functions: script priorities

Reviewed against pinned SDL 3.4.16 headers and daScript
`35bf260c0d8a79b94c64005bd3d2435adcf7e261`, Windows x64/MSVC.
All **19 pending functions outside Stdinc** now have an individual
`script_disposition`, reason and contract in [api-policy.json](../tools/api-policy.json).

| Decision | Count | Current action |
| --- | ---: | --- |
| host_only | 13 | Native startup/platform integration and assertion diagnostics |
| stdlib | 2 | Use daScript integer operations; preserve zero behavior |
| deferred | 1 | SDL_SwapFloat only when exact-bit binary interchange needs it |
| c_abi_only | 3 | Keep va_list outside the ordinary script interface |

This classifies the backlog, not implementation coverage. All 19 retain raw
`pending`; none is excluded from the denominator. Core remains **1062 generated
+ 13 adapted + 188 pending / 1263**. Combined with the [169 Stdinc decisions](stdinc-policy.md),
every pending function is reviewed. This does not certify all record fields,
macros, operating systems, physical devices or retained script callbacks.

## Main: seven host responsibilities

| Function | Decision and reason |
| --- | --- |
| SDL_main | Supplied by the application, not by SDL. A script export named main is a different entry point, invoked by the host. |
| SDL_SetMainReady | Already called by [the desktop runner](../src/runner.cpp) and [SDK host](../examples/sdk-consumer/host.cpp) before SDL initialization. Native use does not count as a script binding. |
| SDL_RunApp | Initial-thread startup/teardown around a native C main. A host can choose this instead of SetMainReady; scripts should not launch their host again. |
| SDL_EnterAppMainCallbacks | Header implementation helper; SDL documents it as the sole call inside SDL_main, not an ordinary callable API. [Web runner](../web/runner.cpp) already selects SDL_MAIN_USE_CALLBACKS and implements native SDL_App* functions. |
| SDL_RegisterApp | Optional Windows class/HINSTANCE customization at startup; SDL video normally performs registration itself. |
| SDL_UnregisterApp | Paired native class registration count, normally managed by SDL video. Keep the pair under one host owner. |
| SDL_GDKSuspendComplete | Xbox GDK suspension acknowledgement, ordered with the event watch and renderer/GPU suspension. Other platforms set an unsupported error. Revisit in an actual GDK host profile; desktop declaration visibility is not working GDK support. |

These are placement decisions, not claims that C callbacks or startup functions
cannot technically be bound. A new platform may need host changes even with no
new script exports. Web's existing callback loop does not mean every desktop
function is built or runtime-tested for web.

## Assert: six host diagnostic operations

| Function | Decision and reason |
| --- | --- |
| SDL_ReportAssertion | SDL says never call directly; its C macros provide persistent assertion data and source metadata. |
| SDL_SetAssertionHandler | Native process-wide callback on any asserting thread; survives SDL_Quit. The host owns code, userdata and diagnostic response policy. |
| SDL_GetAssertionHandler | Retrieves the host callback/userdata pair for native diagnostic integration. |
| SDL_GetDefaultAssertionHandler | Native default handler address; assertion responses may involve UI, debugger break or termination. |
| SDL_GetAssertionReport | Borrowed list, invalidated by reset/Quit; must coordinate mutation and readers. A copied report adapter is a possible later tooling feature. |
| SDL_ResetAssertionReport | Not thread safe against report readers or concurrent assertions; owned by host diagnostics. |

No assertion-to-panic or assertion-to-Result bridge is introduced. daScript
`verify` does not reproduce SDL's native diagnostic system and is not an SDL
error-handling replacement. Existing boost failures remain Result values.
A future native assertion integration would need exact SDL_AssertData ownership,
handler restoration and controlled tests without interactive dialogs or aborts.

## Bits: two language alternatives

SDL_MostSignificantBitIndex32 is an integer bit index, not floating-point log2.
For `x : uint`, use `x == 0u ? -1 : 31 - int(clz(x))`; the explicit zero branch
preserves SDL's -1 result without relying on a zero-input intrinsic contract.
SDL_HasExactlyOneBitSet32 corresponds to
`x != 0u && (x & (x - 1u)) == 0u`, including the top bit and false for zero.

The pinned [builtin runtime](../third_party/daScript/src/builtin/module_builtin_runtime.cpp)
registers uint32/uint64 clz; [flat_hash_table.das](../third_party/daScript/daslib/flat_hash_table.das)
already uses it. These are alternatives, not newly exported SDL names.
Both SDL functions are forced-inline header bodies, not DLL symbols. That alone
is not a binding prohibition: a compiled native wrapper is possible if a port
later needs the original names.

## Endian: one optional exact-bit helper

SDL_SwapFloat always reverses the four bytes of a float. It is not float-to-int
numeric conversion, and it is not conditional host-to-little/big endian conversion.
[math_bits.das](../third_party/daScript/daslib/math_bits.das) supplies bit reinterpretation;
existing SDL integer IO functions cover normal byte-order serialization.
Do not assume a numeric cast preserves NaN payloads or signed zero.

Keep this function `deferred`, not a mandatory blocker or an automatic synonym.
When a concrete binary format requires it, bind the header helper and test exact
patterns (signed zero, infinities, NaNs and ordinary values), both byte orders,
and interpreter/AOT parity. SDL_Swap16/32/64 and conditional endian macros are
separate macro entries in this profile, outside these 19 function declarations.

## Three va_list entry points

| Function | Existing script route |
| --- | --- |
| SDL_SetErrorV | SDL_SetErrorText / set_error |
| SDL_LogMessageV | SDL_LogMessageText / log_message |
| SDL_IOvprintf | SDL_IOprintfText or bounded byte writes |

Interpolate text before the call; existing adapters pass it through a literal
`%s` format. They do not implement arbitrary C formatting. va_list represents
native calling-convention state, not a daScript array/tuple or a portable void
pointer. A native host forwarding a real va_list can call SDL directly.
These entries remain raw pending; partial fixed-text coverage belongs to their
existing non-V functions, not to the V declarations.

## Sources and next work

Decisions use the pinned SDL headers: SDL_main.h (entry points and GDK),
SDL_assert.h (report lifetime/handler rules), SDL_bits.h, SDL_endian.h,
SDL_error.h, SDL_log.h and SDL_iostream.h. The generated
[header inventory](generated/api-windows-x64-msvc.md) records header hashes and
per-function classification. No moving wiki or latest release assumptions are used.

The immediate function-declaration audit is complete for the chosen Windows
profile; there is no mandatory new function batch in these 19. Next work should
be concrete record/callback-field accessibility and platform/example validation,
not filling host/libc/va_list counts. Review each newly discovered declaration
on upgrades; no prefix-wide exclusion is allowed.

Validation: inventory, classification contracts and saved-generator freshness passed
(3/3); baseline generation remains reproducible. No native API or runtime behavior changed.
