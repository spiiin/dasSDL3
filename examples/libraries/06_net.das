options gen2
require dassdl3/sdl3_net_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_init_boost
require daslib/defer

// TCP is a byte stream: reads may be partial. The protocol here is four bytes.
def exchange(client : NET_StreamSocket?; peer : NET_StreamSocket?) {
    var sent <- array<uint8>(72u8,105u8,0u8,255u8)
    client |> write_stream(sent) |> sdl_try
    var received : array<uint8>
    resize(received,4)
    var offset = 0
    let deadline = SDL_GetTicks()+3000ul
    while (offset < 4 && SDL_GetTicks() < deadline) {
        peer |> wait_net_input(20) |> sdl_try
        var chunk : array<uint8>
        resize(chunk,4-offset)
        let count = peer |> read_stream(chunk) |> sdl_try
        for (i in 0 .. count) { received[offset+i] = chunk[i] }
        offset += count
    }
    if (offset != 4) { return err(SdlError(operation="exchange",message="TCP receive timed out"),type<SdlUnit>) }
    for (i in 0 .. 4) {
        if (received[i] != sent[i]) { return err(SdlError(operation="exchange",message="TCP payload mismatch"),type<SdlUnit>) }
    }
    print("TCP: received four bytes, including NUL and 255.\n")
    return sdl_ok()
}
def tcp(address : NET_Address?) {
    return sdl_scope() {
        let server : NET_Server? = address |> with_net_server(uint16(39173)) |> sdl_use
        let client : NET_StreamSocket? = address |> with_net_client(uint16(39173)) |> sdl_use
        let connected = client |> wait_connection(3000) |> sdl_try
        if (!connected) { return err(SdlError(operation="tcp",message="Connect timed out"),type<SdlUnit>) }
        let deadline = SDL_GetTicks()+3000ul
        while (SDL_GetTicks() < deadline) {
            server |> wait_net_input(20) |> sdl_try
            var accepted <- accept_client(server) |> sdl_try
            if (is_some(accepted)) {
                var peer <- move_unwrap(accepted)
                {
                    defer() { NET_DestroyStreamSocket(peer) }
                    return exchange(client,peer)
                }
            }
        }
        return err(SdlError(operation="tcp",message="Accept timed out"),type<SdlUnit>)
    }
}
def udp(address : NET_Address?) {
    return sdl_scope() {
        let receiver : NET_DatagramSocket? = address |> with_net_datagram_socket(uint16(39174)) |> sdl_use
        let sender : NET_DatagramSocket? = address |> with_net_datagram_socket(uint16(0)) |> sdl_use
        var bytes <- array<uint8>(83u8,68u8,76u8)
        sender |> send_datagram(address,39174u,bytes) |> sdl_try
        let deadline = SDL_GetTicks()+3000ul
        while (SDL_GetTicks() < deadline) {
            receiver |> wait_net_input(20) |> sdl_try
            var packet <- receive_datagram(receiver) |> sdl_try
            if (is_some(packet)) {
                var owned <- move_unwrap(packet)
                if (length(owned.bytes) != 3 || owned.bytes[0] != 83u8 || owned.bytes[1] != 68u8 || owned.bytes[2] != 76u8) {
                    return err(SdlError(operation="udp",message="UDP payload mismatch"),type<SdlUnit>)
                }
                print("UDP: received SDL from {owned.address}:{int(owned.port)}; payload is owned.\n")
                return sdl_ok()
            }
        }
        return err(SdlError(operation="udp",message="Receive timed out"),type<SdlUnit>)
    }
}
[export]
def main(smoke : bool) : int {
    var result <- sdl_scope() {
        with_sdl(0u) |> sdl_use
        with_net() |> sdl_use
        let address : NET_Address? = with_net_address("127.0.0.1") |> sdl_use
        let ready = address |> wait_address(3000) |> sdl_try
        if (!ready) { return err(SdlError(operation="resolve",message="Address timed out"),type<SdlUnit>) }
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
