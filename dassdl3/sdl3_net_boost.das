options gen2
module sdl3_net_boost shared public
require sdl3_net public
require dassdl3/sdl3_result public
require daslib/option public
require daslib/defer

// All resources must be released before NET_Quit; scope blocks borrow them.
def public with_net(blk : block<() : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    if (!NET_Init()) { return err(sdl_error("NET_Init"),type<NetScopeValue>) }
    var result : $Result<NetScopeValue; SdlError>
    {
        defer() { NET_Quit() }
        static_if (typeinfo can_copy(type<$Result<NetScopeValue; SdlError>>)) { result = blk() }
        else { result <- blk() }
    }
    return <- result
}

def public resolve_hostname(host : string) {
    var value = NET_ResolveHostname(host)
    if (value == null) { return err(sdl_error("NET_ResolveHostname"),type<NET_Address?>) }
    return <- move_ok(value,type<SdlError>)
}
def public with_net_address(host : string; blk : block<(value : NET_Address?) : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    var loaded = resolve_hostname(host)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<NetScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<NetScopeValue; SdlError>
    {
        defer() { NET_UnrefAddress(value) }
        static_if (typeinfo can_copy(type<$Result<NetScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_net_client(address : NET_Address?; port : uint16; props : uint = 0u) {
    var value = NET_CreateClient(address,port,props)
    if (value == null) { return err(sdl_error("NET_CreateClient"),type<NET_StreamSocket?>) }
    return <- move_ok(value,type<SdlError>)
}
def public with_net_client(address : NET_Address?; port : uint16; props : uint; blk : block<(value : NET_StreamSocket?) : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    var loaded = create_net_client(address,port,props)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<NetScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<NetScopeValue; SdlError>
    {
        defer() { NET_DestroyStreamSocket(value) }
        static_if (typeinfo can_copy(type<$Result<NetScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_net_server(address : NET_Address?; port : uint16; props : uint = 0u) {
    var value = NET_CreateServer(address,port,props)
    if (value == null) { return err(sdl_error("NET_CreateServer"),type<NET_Server?>) }
    return <- move_ok(value,type<SdlError>)
}
def public with_net_server(address : NET_Address?; port : uint16; props : uint; blk : block<(value : NET_Server?) : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    var loaded = create_net_server(address,port,props)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<NetScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<NetScopeValue; SdlError>
    {
        defer() { NET_DestroyServer(value) }
        static_if (typeinfo can_copy(type<$Result<NetScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_net_datagram_socket(address : NET_Address?; port : uint16; props : uint = 0u) {
    var value = NET_CreateDatagramSocket(address,port,props)
    if (value == null) { return err(sdl_error("NET_CreateDatagramSocket"),type<NET_DatagramSocket?>) }
    return <- move_ok(value,type<SdlError>)
}
def public with_net_datagram_socket(address : NET_Address?; port : uint16; props : uint; blk : block<(value : NET_DatagramSocket?) : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    var loaded = create_net_datagram_socket(address,port,props)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<NetScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<NetScopeValue; SdlError>
    {
        defer() { NET_DestroyDatagramSocket(value) }
        static_if (typeinfo can_copy(type<$Result<NetScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

// false means pending; failure alone captures SDL_GetError.
def net_status(status : NET_Status; operation : string) {
    if (status == NET_Status.FAILURE) { return err(sdl_error(operation),type<bool>) }
    return ok(status == NET_Status.SUCCESS,type<SdlError>)
}
def public address_ready(address : NET_Address?) {
    // Pinned native NULL handling incorrectly returns WAITING (zero).
    if (address == null) { return err(SdlError(operation="NET_GetAddressStatus",message="address is null"),type<bool>) }
    return net_status(NET_GetAddressStatus(address),"NET_GetAddressStatus") }
def public wait_address(address : NET_Address?; timeout_ms : int) {
    // Pinned native NULL handling incorrectly returns WAITING (zero).
    if (address == null) { return err(SdlError(operation="NET_WaitUntilResolved",message="address is null"),type<bool>) }
    return net_status(NET_WaitUntilResolved(address,timeout_ms),"NET_WaitUntilResolved") }
def public connection_ready(socket : NET_StreamSocket?) {
    // Pinned native NULL handling incorrectly returns WAITING (zero).
    if (socket == null) { return err(SdlError(operation="NET_GetConnectionStatus",message="socket is null"),type<bool>) }
    return net_status(NET_GetConnectionStatus(socket),"NET_GetConnectionStatus") }
def public wait_connection(socket : NET_StreamSocket?; timeout_ms : int) {
    // Pinned native NULL handling incorrectly returns WAITING (zero).
    if (socket == null) { return err(SdlError(operation="NET_WaitUntilConnected",message="socket is null"),type<bool>) }
    return net_status(NET_WaitUntilConnected(socket,timeout_ms),"NET_WaitUntilConnected") }

def public address_string(address : NET_Address?) {
    var value = NET_GetAddressStringCopy(address)
    if (value == "") { return err(sdl_error("NET_GetAddressString"),type<string>) }
    return ok(value,type<SdlError>)
}
def public address_bytes(address : NET_Address?) {
    var value : array<uint8>
    if (!NET_GetAddressBytesCopy(address,value)) { return err(sdl_error("NET_GetAddressBytes"),type<array<uint8>>) }
    return <- move_ok(value,type<SdlError>)
}
def public accept_client(server : NET_Server?) {
    var client : NET_StreamSocket?
    if (!NET_AcceptClientRef(server,client)) { return err(sdl_error("NET_AcceptClient"),type<$Option<NET_StreamSocket?>>) }
    var value <- none(type<NET_StreamSocket?>)
    if (client != null) { value <- move_some(client) }
    return <- move_ok(value,type<SdlError>)
}
def public write_stream(socket : NET_StreamSocket?; bytes : array<uint8>) {
    return sdl_status(NET_WriteStreamBytes(socket,bytes),"NET_WriteToStreamSocket")
}
def public read_stream(socket : NET_StreamSocket?; var bytes : array<uint8>) {
    let count = NET_ReadStreamBytes(socket,bytes)
    if (count < 0) { return err(sdl_error("NET_ReadFromStreamSocket"),type<int>) }
    return ok(count,type<SdlError>)
}
def public send_datagram(socket : NET_DatagramSocket?; address : NET_Address?; port : uint; bytes : array<uint8>) {
    return sdl_status(NET_SendDatagramBytes(socket,address,port,bytes),"NET_SendDatagram")
}
struct NetDatagram {
    address : string
    port : uint
    bytes : array<uint8>
}
def public receive_datagram(socket : NET_DatagramSocket?) {
    var packet : NET_Datagram?
    if (!NET_ReceiveDatagramRef(socket,packet)) { return err(sdl_error("NET_ReceiveDatagram"),type<$Option<NetDatagram>>) }
    if (packet == null) {
        var empty <- none(type<NetDatagram>)
        return <- move_ok(empty,type<SdlError>)
    }
    {
        defer() { NET_DestroyDatagram(packet) }
        var value : NetDatagram
        value.address = NET_GetAddressStringCopy(packet.address)
        if (value.address == "") { return err(sdl_error("NET_GetAddressString"),type<$Option<NetDatagram>>) }
        value.port = uint(packet.port)
        if (!NET_CopyDatagramBytes(packet,value.bytes)) { return err(sdl_error("NET_CopyDatagramBytes"),type<$Option<NetDatagram>>) }
        var present <- move_some(value)
        return <- move_ok(present,type<SdlError>)
    }
}
def public wait_net_input(socket : NET_Server?; timeout_ms : int) {
    let count = NET_WaitServerInput(socket,timeout_ms)
    if (count < 0) { return err(sdl_error("NET_WaitUntilInputAvailable"),type<int>) }
    return ok(count,type<SdlError>)
}
def public wait_net_input(socket : NET_StreamSocket?; timeout_ms : int) {
    let count = NET_WaitStreamInput(socket,timeout_ms)
    if (count < 0) { return err(sdl_error("NET_WaitUntilInputAvailable"),type<int>) }
    return ok(count,type<SdlError>)
}
def public wait_net_input(socket : NET_DatagramSocket?; timeout_ms : int) {
    let count = NET_WaitDatagramInput(socket,timeout_ms)
    if (count < 0) { return err(sdl_error("NET_WaitUntilInputAvailable"),type<int>) }
    return ok(count,type<SdlError>)
}
def public pending_stream_writes(socket : NET_StreamSocket?) {
    let count = NET_GetStreamSocketPendingWrites(socket)
    if (count < 0) { return err(sdl_error("NET_GetStreamSocketPendingWrites"),type<int>) }
    return ok(count,type<SdlError>)
}
def public drain_stream(socket : NET_StreamSocket?; timeout_ms : int) {
    let count = NET_WaitUntilStreamSocketDrained(socket,timeout_ms)
    if (count < 0) { return err(sdl_error("NET_WaitUntilStreamSocketDrained"),type<int>) }
    return ok(count,type<SdlError>)
}

def public with_net_client(address : NET_Address?; port : uint16; blk : block<(value : NET_StreamSocket?) : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    return <- with_net_client(address,port,0u,blk)
}

def public with_net_server(address : NET_Address?; port : uint16; blk : block<(value : NET_Server?) : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    return <- with_net_server(address,port,0u,blk)
}

def public with_net_datagram_socket(address : NET_Address?; port : uint16; blk : block<(value : NET_DatagramSocket?) : $Result<auto(NetScopeValue); SdlError>>) : $Result<NetScopeValue; SdlError> {
    return <- with_net_datagram_socket(address,port,0u,blk)
}
