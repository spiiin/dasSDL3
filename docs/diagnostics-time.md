# Error, logging and time bindings

Pinned SDL 3.2.18; Windows x64/MSVC. This package adds 22 generated signatures:
two Error, five Log, six Timer and all nine Time functions. SDL_GetError,
SDL_GetTicks and SDL_Delay were already generated. SDL_DateTime fields and
SDL_LogCategory/SDL_LogPriority/SDL_DateFormat/SDL_TimeFormat are generated.
SDL_Time is a signed int64 nanosecond timestamp; tick counters are uint64.

## Strings and errors

SDL_SetErrorText calls SDL_SetError("%s", text), preserving its false result.
SDL_LogText, SDL_LogMessageText and Trace/Verbose/Debug/Info/Warn/Error/CriticalText
likewise accept a completed message. Use daScript interpolation before calling.
Percent sequences are literal, never C format directives. A null script string
is treated as empty. C varargs and va_list are not exposed. These are bounded
adapters, not full variadic signatures; V variants remain pending.

SDL_GetErrorCopy / error_string copies the current thread's error. Raw SDL_GetError
borrows storage until that thread changes it. An SDL error string is not a failure
flag: check the function's native return value first. SDL_OutOfMemory always returns
false; tests exercise this sentinel without deliberately exhausting memory.
No wrapper panics, catches exceptions or changes cleanup rules.

## Logging

Priority setters/getters and prefix configuration follow SDL directly. Log state
is process-global; do not treat priority changes as scoped per-context state.
SDL_ResetLogPriorities restores SDL defaults, not a prior application snapshot.
The native test capture checks message bytes and filtering; prefix formatting by
the platform's default output sink is not asserted by that capture.

GetDefaultLogOutputFunction, GetLogOutputFunction and SetLogOutputFunction are now
generated with native C address adapters; GetLogOutputFunctionRef exposes both
outputs. See [native callbacks](native-callbacks.md); no retained script block bridge.

## Time and timers

current_time, time_to_date and date_to_time provide reference adapters, preserving
bool results. SDL_GetDateTimeLocalePreferencesRef and SDL_TimeToWindowsRef expose
scalar outputs without script addresses. Raw pointer signatures remain available.
Calendar tests use UTC and known dates, independent of the host timezone. Local
conversion is available but not exhaustively tested across DST/timezone rules.
FILETIME has 100 ns precision; arbitrary nanosecond values lose precision on a
roundtrip. Timing tests assert monotonicity and lower bounds, never tight upper
bounds. SDL_DelayPrecise may busy-wait and is not a scheduling abstraction.

SDL_RemoveTimer, AddTimer and AddTimerNS are generated. Timer callbacks are native
C addresses and execute on SDL timer threads. Cancellation does not join an active
callback; [the host lifetime contract and tests](native-callbacks.md) cover this.
There is no retained script timer bridge.

Example: [53_diagnostics_time.das](../examples/53_diagnostics_time.das).
Tests: [diagnostics.das](../tests/diagnostics.das), including direct execution of
all 22 new raw functions and the fixed-text logging/error adapters.

## Local validation (Windows x64/MSVC, 2026-09-20)

- Main regression suite: 122/122.
- Package interpreter (baseline and CppGenBind), AOT and metadata: 7/7.
- Generation/freshness/inventory/boundary gates: 6/6; standalone clangbind: 4/4.
- No-LLVM consumer build, example 53 and public API boundary check passed.
- Documentation links and whitespace checks passed.

The full AOT runner was rebuilt. Runtime parity was executed for this package
and metadata; the entire GPU parity runtime suite was not repeated.
