# SDL_net

Optional `DASSDL3_WITH_NET=ON`; independent of ImGui, image and ttf. The libraries
runner registers `sdl3_net`; scripts import `dassdl3/sdl3_net_boost`.

## Version and generation

Pinned [SDL_net 3.2.0](https://github.com/libsdl-org/SDL_net/tree/release-3.2.0),
zlib license, uses the existing SDL 3.2.18 target (requires SDL >= 3.0.0).
FetchContent archive SHA256:
`195036ba82322e03fd3562149634fb582e5e9298ccc6cb2c5e362bf40c5018be`.
Static library, no additional codec/compiler dependency; upstream selects socket
system libraries. Examples and installation targets of SDL_net are not required.

All **34** exports in pinned `SDL_net.h` are registered, plus NET_Status, opaque
address/server/stream/datagram socket types, NET_Datagram and three property names.
`NET_Datagram.addr` is exposed as `address` because `addr` is a daScript keyword;
the generated annotation retains native C++ field name `addr` for AOT.
Function signatures, native ownership and sentinels are unchanged.

`tools/generate_net_bindings.py <path-to-SDL_net.h> [--check]` verifies the pinned
version and complete export count. It snapshots declarations/types; DAS_BIND_FUN
infers C signatures at compile time, as in the image/ttf modules. Consumers use
committed snapshots without Python, dasclang or LLVM. Eleven separate adapters
provide out references, copied data, bounded byte arrays and typed single-socket
waits. Raw mixed-socket `NET_WaitUntilInputAvailable` remains available.

## Boost contracts

| Operation | Result |
| --- | --- |
| resolve_hostname | Result<NET_Address?, SdlError>, resolution starts asynchronously |
| address_ready / wait_address | Result<bool, SdlError>, false = pending or timeout |
| create_net_client | Result<NET_StreamSocket?, SdlError>, connection starts asynchronously |
| connection_ready / wait_connection | Result<bool, SdlError>, false = pending or timeout |
| create_net_server / create_net_datagram_socket | Result<native pointer, SdlError> |
| accept_client | Result<Option<NET_StreamSocket?>, SdlError>, None = no connection ready |
| read_stream(socket, bytes) | Result<int, SdlError>, writes caller buffer, returns actual count; zero = no bytes available |
| write_stream / send_datagram | Result<SdlUnit, SdlError>, SDL copies/queues data; success is not delivery acknowledgement |
| pending_stream_writes / drain_stream | Result<int, SdlError>, bytes still queued; nonzero after timeout is normal |
| receive_datagram | Result<Option<NetDatagram>, SdlError>, owned sender string, port and byte array |
| wait_net_input | Result<int, SdlError>, zero = timeout; overloads for server, stream and datagram |
| address_string / address_bytes | Result<owned value, SdlError>, requires completed resolution |

`address_bytes` contains opaque protocol storage, **not** a portable IPv4/IPv6
encoding; do not persist it. Polling helpers do not block. Wait timeouts are in
milliseconds; negative means unbounded waiting according to SDL_net. Examples use
bounded waits for a command-line exchange; an interactive render loop should poll
or wait with timeout zero. TCP has no message boundaries: accumulate partial reads.
Zero read count does not mean EOF; SDL_net reports closed streams as failure.
No error kind is inferred from error-message text.

`with_net`, `with_net_address`, `with_net_client`, `with_net_server` and
`with_net_datagram_socket` use existing Result/defer conventions and work with
`sdl_scope` / `sdl_use`. A scope result propagates the body result, including moved
arrays. Create every network resource inside `with_net`; destroy/unref all owned
resources before NET_Quit. Blocks borrow resources and must not destroy or retain
those references. A separate explicit NET_RefAddress is an independently owned
reference which also must be released. No arbitrary-panic cleanup guarantee.

`accept_client` returns an **owned** socket. After Some, enter a nested defer scope
and destroy it with NET_DestroyStreamSocket. `NET_GetStreamSocketAddress` also
adds a reference: unref that address. Raw received datagrams own their address and
buffer until NET_DestroyDatagram. Boost receive_datagram copies then destroys the
native packet, so its returned value survives socket teardown. Raw local address
arrays require NET_FreeLocalAddresses; ref individual addresses before retaining.
Do not treat copied raw pointers as additional ownership.

## Pinned implementation details

- NET_GetAddressStatus / NET_WaitUntilResolved and connection-status helpers return
  zero after invalid null input in 3.2.0, despite setting SDL's error string. Boost
  explicitly rejects null for those four operations; it does not inspect stale
  SDL error text after successful operations. Live-pointer/thread rules still apply.
- NET_SendDatagram with length zero succeeds **without transmitting a packet**.
  Boost preserves that behavior. A received native zero-length packet is still
  Some, not None, but receiving one from an external socket has not been tested.
- DestroyStreamSocket may discard data still queued in SDL_net. Use drain_stream
  with an appropriate timeout before teardown when delivery to the OS matters.
- No DNS cancellation facade: releasing an address drops the caller reference;
  it does not promise to cancel an in-flight resolver job.

## Example and checks

[06_net.das](../examples/libraries/06_net.das) performs TCP and UDP exchanges on
127.0.0.1, using ports 39173/39174. No external server, firewall rule or outbound
internet access is needed. Occupied ports produce a normal Result error.
Tests use 39175/39176 and CTest's `sdl_net_loopback` resource lock.

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\06_net.das
ctest --test-dir build/ninja -R 'sdl3_(tests_net|examples_libraries_06_net)$' --output-on-failure
```

`tests/net.das` checks binary TCP payloads, partial-read accumulation, pending
reads/accept/receive, sender metadata and UDP bytes, invalid ports/oversized payload,
zero-send behavior, peer closure, address refs/local enumeration, owned address data
after scope cleanup, body-error propagation and copied error lifetime. It does not
claim runtime coverage of all 34 raw exports.

Parity is enabled by `DASSDL3_TEST_NET=ON` and `SDL_NET_INCLUDE`; it runs the example
and tests through legacy registration, CppGenBind and a separate net_aot_runner
with fallback disabled. A NET-only consumer build disables the other libraries
and generation/LLVM discovery. Validation is Windows x64 loopback; IPv6, real DNS
failures, lossy remote networks, other OSes and shared-library packaging remain
unverified. No TLS, HTTP, network protocol framework or retained script callbacks.
Browser WebAssembly sockets are not enabled by this change; web transport needs
its own compatibility plan.

Local verification (2026-09-26): both main CTest entries passed; all six
legacy/CppGenBind/AOT entries passed; NET-only no-LLVM consumer built and ran both
scripts. Generator snapshot check, documentation links and public API boundary
check passed. Main generator configuration was restored after consumer validation.
