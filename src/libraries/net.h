#pragma once
#include "daScript/daScript.h"
#include "daScript/simulate/bind_enum.h"
#include <SDL3_net/SDL_net.h>
#include "generated/net_casts.inc"
static_assert(SDL_NET_VERSION == 3002000,"Review bindings when updating SDL_net");
inline bool NET_AcceptClientRef(NET_Server* server, NET_StreamSocket*& client) {
    client=nullptr; return NET_AcceptClient(server,&client);
}
inline bool NET_ReceiveDatagramRef(NET_DatagramSocket* sock, NET_Datagram*& packet) {
    packet=nullptr; return NET_ReceiveDatagram(sock,&packet);
}
inline int NET_ReadStreamBytes(NET_StreamSocket* sock, das::TArray<uint8_t>& bytes) {
    if (bytes.size>INT_MAX) { SDL_SetError("Buffer exceeds INT_MAX"); return -1; }
    uint8_t empty=0;
    return NET_ReadFromStreamSocket(sock,bytes.size ? bytes.data : (char*)&empty,int(bytes.size));
}
inline bool NET_WriteStreamBytes(NET_StreamSocket* sock, const das::TArray<uint8_t>& bytes) {
    if (bytes.size>INT_MAX) return SDL_SetError("Buffer exceeds INT_MAX");
    uint8_t empty=0;
    return NET_WriteToStreamSocket(sock,bytes.size ? bytes.data : (char*)&empty,int(bytes.size));
}
inline bool NET_SendDatagramBytes(NET_DatagramSocket* sock, NET_Address* address, uint32_t port, const das::TArray<uint8_t>& bytes) {
    if (port>65535 || bytes.size>INT_MAX) return SDL_SetError("Invalid datagram port or buffer size");
    uint8_t empty=0;
    return NET_SendDatagram(sock,address,Uint16(port),bytes.size ? bytes.data : (char*)&empty,int(bytes.size));
}
inline bool NET_CopyDatagramBytes(NET_Datagram* packet, das::TArray<uint8_t>& bytes, das::Context* context, das::LineInfoArg* at) {
    das::builtin_array_resize(bytes,0,1,context,at);
    if (!packet || packet->buflen<0 || (packet->buflen && !packet->buf)) return SDL_InvalidParamError("packet");
    das::builtin_array_resize(bytes,packet->buflen,1,context,at);
    if (packet->buflen) std::memcpy(bytes.data,packet->buf,packet->buflen);
    return true;
}
inline char* NET_GetAddressStringCopy(NET_Address* address, das::Context* context, das::LineInfoArg* at) {
    const char* value=NET_GetAddressString(address);
    return value ? context->allocateString(value,at) : nullptr;
}
inline bool NET_GetAddressBytesCopy(NET_Address* address, das::TArray<uint8_t>& bytes, das::Context* context, das::LineInfoArg* at) {
    das::builtin_array_resize(bytes,0,1,context,at);
    int size=0; const void* value=NET_GetAddressBytes(address,&size);
    if (!value) return false;
    if(size<0) return SDL_SetError("Invalid address byte count");
    das::builtin_array_resize(bytes,size,1,context,at);
    if(size) std::memcpy(bytes.data,value,size);
    return true;
}
// Single-socket overloads avoid void-pointer casts in public scripts.
inline int NET_WaitServerInput(NET_Server* socket,int timeout) { void* p=socket; return NET_WaitUntilInputAvailable(&p,1,timeout); }
inline int NET_WaitStreamInput(NET_StreamSocket* socket,int timeout) { void* p=socket; return NET_WaitUntilInputAvailable(&p,1,timeout); }
inline int NET_WaitDatagramInput(NET_DatagramSocket* socket,int timeout) { void* p=socket; return NET_WaitUntilInputAvailable(&p,1,timeout); }
