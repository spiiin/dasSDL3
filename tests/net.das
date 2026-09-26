options gen2
require dassdl3/sdl3_net_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_init_boost
require daslib/defer

// TCP is a byte stream: reads may be partial. The protocol here is four bytes.
def exchange(client : NET_StreamSocket?; peer : NET_StreamSocket?) {
    let checked1 = client |> connection_ready() |> sdl_try
    verify(checked1)
    let checked2 = peer |> pending_stream_writes() |> sdl_try
    verify(checked2 == 0)
    NET_SimulateStreamPacketLoss(client, 0)
    var empty : array<uint8>
    let checked3 = peer |> read_stream(empty) |> sdl_try
    verify(checked3 == 0)
    var scratch : array<uint8>; resize(scratch, 4)
    let checked4 = peer |> read_stream(scratch) |> sdl_try
    verify(checked4 == 0)
    var remote = NET_GetStreamSocketAddress(peer)
    verify(remote != null)
    NET_UnrefAddress(remote)
    var sent <- array<uint8>(72u8, 105u8, 0u8, 255u8)
    client |> write_stream(sent) |> sdl_try
    var received : array<uint8>
    resize(received, 4)
    var offset = 0
    let deadline = SDL_GetTicks() + 3000ul
    while (offset < 4 && SDL_GetTicks() < deadline) {
        peer |> wait_net_input(20) |> sdl_try
        var chunk : array<uint8>
        resize(chunk, 4 - offset)
        let count = peer |> read_stream(chunk) |> sdl_try
        for (i in 0 .. count) { received[offset + i] = chunk[i] }
        offset += count
    }
    if (offset != 4) { return err(SdlError(operation = "exchange", message = "TCP receive timed out"), type<SdlUnit>) }
    for (i in 0 .. 4) {
        if (received[i] != sent[i]) { return err(SdlError(operation = "exchange", message = "TCP payload mismatch"), type<SdlUnit>) }
    }
    let checked5 = client |> drain_stream(3000) |> sdl_try
    verify(checked5 == 0)
    print("TCP: received four bytes, including NUL and 255.\n")
    return sdl_ok()
}
def tcp(address : NET_Address?) {
    return sdl_scope() {
        let server : NET_Server? = address |> with_net_server(uint16(39175)) |> sdl_use
        var absent <- accept_client(server) |> sdl_try
        verify(is_none(absent))
        let checked6 = server |> wait_net_input(0) |> sdl_try
        verify(checked6 == 0)
        let client : NET_StreamSocket? = address |> with_net_client(uint16(39175)) |> sdl_use
        let connected = client |> wait_connection(3000) |> sdl_try
        if (!connected) { return err(SdlError(operation = "tcp", message = "Connect timed out"), type<SdlUnit>) }
        let deadline = SDL_GetTicks() + 3000ul
        while (SDL_GetTicks() < deadline) {
            server |> wait_net_input(20) |> sdl_try
            var accepted <- accept_client(server) |> sdl_try
            if (is_some(accepted)) {
                var peer <- move_unwrap(accepted)
                {
                    defer() { NET_DestroyStreamSocket(peer) }
                    exchange(client, peer) |> sdl_try
                    NET_DestroyStreamSocket(peer)
                    peer = null
                    var buffer : array<uint8>; resize(buffer, 1)
                    let closed_deadline = SDL_GetTicks() + 3000ul
                    while (SDL_GetTicks() < closed_deadline) {
                        var read_result = client |> read_stream(buffer)
                        if (is_err(read_result)) {
                            let failure = unwrap_err(read_result)
                            SDL_ClearError()
                            verify(length(failure.message) > 0)
                            return sdl_ok()
                        }
                        SDL_Delay(1u)
                    }
                    return err(SdlError(operation = "test", message = "Peer closure was not reported"), type<SdlUnit>)
                }
            }
        }
        return err(SdlError(operation = "tcp", message = "Accept timed out"), type<SdlUnit>)
    }
}
def udp(address : NET_Address?) {
    return sdl_scope() {
        let receiver : NET_DatagramSocket? = address |> with_net_datagram_socket(uint16(39176)) |> sdl_use
        let sender : NET_DatagramSocket? = address |> with_net_datagram_socket(uint16(0)) |> sdl_use
        SDL_SetErrorMessage("stale success error")
        var absent <- receive_datagram(receiver) |> sdl_try
        verify(is_none(absent))
        NET_SimulateDatagramPacketLoss(sender, 0)
        var bytes <- array<uint8>(83u8, 68u8, 76u8)
        sender |> send_datagram(address, 39176u, bytes) |> sdl_try
        let deadline = SDL_GetTicks() + 3000ul
        while (SDL_GetTicks() < deadline) {
            receiver |> wait_net_input(20) |> sdl_try
            var packet <- receive_datagram(receiver) |> sdl_try
            if (is_some(packet)) {
                var owned <- move_unwrap(packet)
                if (length(owned.bytes) != 3 || owned.bytes[0] != 83u8 || owned.bytes[1] != 68u8 || owned.bytes[2] != 76u8) {
                    return err(SdlError(operation = "udp", message = "UDP payload mismatch"), type<SdlUnit>)
                }
                var invalid <- sender |> send_datagram(address, 65536u, bytes)
                verify(is_err(invalid))
                var zero : array<uint8>
                sender |> send_datagram(address, 39176u, zero) |> sdl_try
                // SDL_net 3.2.0 treats zero-byte sends as successful no-ops.
                var empty_packet <- receive_datagram(receiver) |> sdl_try
                verify(is_none(empty_packet))
                var too_large : array<uint8>; resize(too_large, 65537)
                var oversized <- sender |> send_datagram(address, 39176u, too_large)
                verify(is_err(oversized))
                print("UDP: received SDL from {owned.address}:{int(owned.port)}; payload is owned.\n")
                return sdl_ok()
            }
        }
        return err(SdlError(operation = "udp", message = "Receive timed out"), type<SdlUnit>)
    }
}
[export]
def main(smoke : bool) : int {
    var result <- sdl_scope() {
        with_sdl(0u) |> sdl_use
        with_net() |> sdl_use
        let address : NET_Address? = with_net_address("127.0.0.1") |> sdl_use
        let ready = address |> wait_address(3000) |> sdl_try
        if (!ready) { return err(SdlError(operation = "resolve", message = "Address timed out"), type<SdlUnit>) }
        verify(NET_Version() == 3002000)
        let checked7 = address |> address_ready() |> sdl_try
        verify(checked7)
        let name = address |> address_string() |> sdl_try
        verify(name == "127.0.0.1")
        var packed <- address |> address_bytes() |> sdl_try
        verify(length(packed) > 0) // Opaque protocol bytes, not a portable IPv4 encoding.
        var refaddr = NET_RefAddress(address)
        verify(NET_CompareAddresses(address, refaddr) == 0)
        NET_UnrefAddress(refaddr)
        var moved <- with_net_address("127.0.0.1") $(temporary : NET_Address?) {
            let resolved = temporary |> wait_address(3000) |> sdl_try
            verify(resolved)
            return address_bytes(temporary)
        }
        verify(is_ok(moved))
        var copied <- move_unwrap(moved)
        verify(length(copied) == length(packed))
        for (i in 0 .. length(packed)) { verify(copied[i] == packed[i]) }
        var bad : NET_Datagram
        bad.buflen = -1
        var rejected : array<uint8>
        unsafe { verify(!NET_CopyDatagramBytes(addr(bad), rejected)) }
        verify(length(rejected) == 0)
        NET_SimulateAddressResolutionLoss(0)
        var no_address = address_ready(null)
        var no_wait = wait_address(null, 0)
        var no_connection = connection_ready(null)
        var no_connect_wait = wait_connection(null, 0)
        verify(is_err(no_address) && is_err(no_wait) && is_err(no_connection) && is_err(no_connect_wait))
        // Preserve raw pinned behavior while boost rejects the invalid argument.
        verify(NET_GetAddressStatus(null) == NET_Status.WAITING)
        unsafe {
            var count = 0
            let locals = NET_GetLocalAddresses(addr(count))
            verify(locals != null && count >= 0)
            NET_FreeLocalAddresses(locals)
        }
        var failed <- accept_client(null)
        verify(is_err(failed))
        let saved = unwrap_err(failed)
        SDL_ClearError()
        verify(length(saved.message) > 0)
        var scoped <- with_net_address("127.0.0.1") $(borrowed) {
            return err(SdlError(operation = "body", message = "preserve me"), type<SdlUnit>)
        }
        verify(is_err(scoped) && unwrap_err(scoped).operation == "body")
        tcp(address) |> sdl_try
        udp(address) |> sdl_try
        return sdl_ok()
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
