# SDL record field accessibility (generated)

SDL 3.4.16; windows-x64-msvc; 122 named complete native records, 840 top-level fields.

Direct means listed in bindings.json; other decisions are explicit in tools/record-field-policy.json.
Adapter evidence is static registration/source verification, not a new runtime guarantee.
Opaque forward declarations, nested anonymous-union interiors, project records and other platforms are outside this census.

| Status | Fields |
| --- | ---: |
| adapted | 84 |
| direct | 586 |
| host_only | 9 |
| internal | 98 |
| native_callback | 25 |
| tag | 38 |

## Callback slots

| Field | Status | Entry point / decision |
| --- | --- | --- |
| `SDL_IOStreamInterface.close` | native_callback | SDL_SetIOStreamInterfaceCallbacks |
| `SDL_IOStreamInterface.flush` | native_callback | SDL_SetIOStreamInterfaceCallbacks |
| `SDL_IOStreamInterface.read` | native_callback | SDL_SetIOStreamInterfaceCallbacks |
| `SDL_IOStreamInterface.seek` | native_callback | SDL_SetIOStreamInterfaceCallbacks |
| `SDL_IOStreamInterface.size` | native_callback | SDL_SetIOStreamInterfaceCallbacks |
| `SDL_IOStreamInterface.write` | native_callback | SDL_SetIOStreamInterfaceCallbacks |
| `SDL_StorageInterface.close` | native_callback | SDL_SetStorageInterface_close |
| `SDL_StorageInterface.copy` | native_callback | SDL_SetStorageInterface_copy |
| `SDL_StorageInterface.enumerate` | native_callback | SDL_SetStorageInterface_enumerate |
| `SDL_StorageInterface.info` | native_callback | SDL_SetStorageInterface_info |
| `SDL_StorageInterface.mkdir` | native_callback | SDL_SetStorageInterface_mkdir |
| `SDL_StorageInterface.read_file` | native_callback | SDL_SetStorageInterface_read_file |
| `SDL_StorageInterface.ready` | native_callback | SDL_SetStorageInterface_ready |
| `SDL_StorageInterface.remove` | native_callback | SDL_SetStorageInterface_remove |
| `SDL_StorageInterface.rename` | native_callback | SDL_SetStorageInterface_rename |
| `SDL_StorageInterface.space_remaining` | native_callback | SDL_SetStorageInterface_space_remaining |
| `SDL_StorageInterface.write_file` | native_callback | SDL_SetStorageInterface_write_file |
| `SDL_VirtualJoystickDesc.Cleanup` | native_callback | SDL_SetVirtualJoystickDesc_Cleanup |
| `SDL_VirtualJoystickDesc.Rumble` | native_callback | SDL_SetVirtualJoystickDesc_Rumble |
| `SDL_VirtualJoystickDesc.RumbleTriggers` | native_callback | SDL_SetVirtualJoystickDesc_RumbleTriggers |
| `SDL_VirtualJoystickDesc.SendEffect` | native_callback | SDL_SetVirtualJoystickDesc_SendEffect |
| `SDL_VirtualJoystickDesc.SetLED` | native_callback | SDL_SetVirtualJoystickDesc_SetLED |
| `SDL_VirtualJoystickDesc.SetPlayerIndex` | native_callback | SDL_SetVirtualJoystickDesc_SetPlayerIndex |
| `SDL_VirtualJoystickDesc.SetSensorsEnabled` | native_callback | SDL_SetVirtualJoystickDesc_SetSensorsEnabled |
| `SDL_VirtualJoystickDesc.Update` | native_callback | SDL_SetVirtualJoystickDesc_Update |

## All non-direct fields

| Field | Status | Reason |
| --- | --- | --- |
| `SDL_AssertData.always_ignore` | host_only | Native assertion diagnostics and borrowed report lifetime; not script error handling. |
| `SDL_AssertData.condition` | host_only | Native assertion diagnostics and borrowed report lifetime; not script error handling. |
| `SDL_AssertData.filename` | host_only | Native assertion diagnostics and borrowed report lifetime; not script error handling. |
| `SDL_AssertData.function` | host_only | Native assertion diagnostics and borrowed report lifetime; not script error handling. |
| `SDL_AssertData.linenum` | host_only | Native assertion diagnostics and borrowed report lifetime; not script error handling. |
| `SDL_AssertData.next` | host_only | Native assertion diagnostics and borrowed report lifetime; not script error handling. |
| `SDL_AssertData.trigger_count` | host_only | Native assertion diagnostics and borrowed report lifetime; not script error handling. |
| `SDL_AudioDeviceEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_AudioDeviceEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_AudioDeviceEvent.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_AudioDeviceEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_AudioDeviceEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_CameraDeviceEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_CameraDeviceEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_ClipboardEvent.mime_types` | adapted | Copy MIME list; native pointer array is borrowed. |
| `SDL_ClipboardEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_ClipboardEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_CommonEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_CommonEvent.timestamp` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_CommonEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_DisplayEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_DisplayEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_DisplayMode.internal` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_DropEvent.data` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_DropEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_DropEvent.source` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_DropEvent.timestamp` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_DropEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_DropEvent.windowID` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_DropEvent.x` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_DropEvent.y` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.adevice` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.button` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.cdevice` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.clipboard` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.common` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.display` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.drop` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.edit` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.edit_candidates` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.gaxis` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.gbutton` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.gdevice` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.gsensor` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.gtouchpad` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.jaxis` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.jball` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.jbattery` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.jbutton` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.jdevice` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.jhat` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.kdevice` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.key` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.mdevice` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.motion` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.padding` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_Event.paxis` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.pbutton` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.pinch` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.pmotion` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.pproximity` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.ptouch` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.quit` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.render` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.sensor` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.text` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.tfinger` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.user` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.wheel` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Event.window` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_GPUBlitInfo.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUBlitInfo.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUBlitInfo.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUColorTargetBlendState.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUColorTargetBlendState.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUColorTargetInfo.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUColorTargetInfo.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUDepthStencilState.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUDepthStencilState.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUDepthStencilState.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUGraphicsPipelineTargetInfo.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUGraphicsPipelineTargetInfo.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUGraphicsPipelineTargetInfo.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUMultisampleState.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUMultisampleState.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPURasterizerState.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPURasterizerState.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUSamplerCreateInfo.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUSamplerCreateInfo.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUStorageBufferReadWriteBinding.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUStorageBufferReadWriteBinding.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUStorageBufferReadWriteBinding.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUStorageTextureReadWriteBinding.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUStorageTextureReadWriteBinding.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GPUStorageTextureReadWriteBinding.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadAxisEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadAxisEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadAxisEvent.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadAxisEvent.padding4` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadAxisEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadAxisEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_GamepadBinding.input` | adapted | Tagged native union accessors read the active input/output alternative. |
| `SDL_GamepadBinding.output` | adapted | Tagged native union accessors read the active input/output alternative. |
| `SDL_GamepadButtonEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadButtonEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadButtonEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadButtonEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_GamepadDeviceEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadDeviceEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_GamepadSensorEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadSensorEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_GamepadTouchpadEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_GamepadTouchpadEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_IOStreamInterface.close` | native_callback | Native function addresses can be assigned by the existing callback setter; no script Func/Block retention. |
| `SDL_IOStreamInterface.flush` | native_callback | Native function addresses can be assigned by the existing callback setter; no script Func/Block retention. |
| `SDL_IOStreamInterface.read` | native_callback | Native function addresses can be assigned by the existing callback setter; no script Func/Block retention. |
| `SDL_IOStreamInterface.seek` | native_callback | Native function addresses can be assigned by the existing callback setter; no script Func/Block retention. |
| `SDL_IOStreamInterface.size` | native_callback | Native function addresses can be assigned by the existing callback setter; no script Func/Block retention. |
| `SDL_IOStreamInterface.write` | native_callback | Native function addresses can be assigned by the existing callback setter; no script Func/Block retention. |
| `SDL_JoyAxisEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyAxisEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyAxisEvent.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyAxisEvent.padding4` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyAxisEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyAxisEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_JoyBallEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyBallEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyBallEvent.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyBallEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyBallEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_JoyBatteryEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyBatteryEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_JoyButtonEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyButtonEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyButtonEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyButtonEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_JoyDeviceEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyDeviceEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_JoyHatEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyHatEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyHatEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_JoyHatEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_KeyboardDeviceEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_KeyboardDeviceEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_KeyboardEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_KeyboardEvent.scancode` | adapted | Scalar scancode accessor avoids unprojected enum field. |
| `SDL_KeyboardEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_MouseButtonEvent.padding` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_MouseButtonEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_MouseButtonEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_MouseDeviceEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_MouseDeviceEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_MouseMotionEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_MouseMotionEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_MouseWheelEvent.direction` | adapted | Boolean flipped accessor covers the two current SDL direction values. |
| `SDL_MouseWheelEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_MouseWheelEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_Palette.colors` | adapted | Owned copy of palette colors; returned array length supplies ncolors. |
| `SDL_Palette.ncolors` | adapted | Owned copy of palette colors; returned array length supplies ncolors. |
| `SDL_Palette.refcount` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_Palette.version` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_PenAxisEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_PenAxisEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_PenButtonEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_PenButtonEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_PenMotionEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_PenMotionEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_PenProximityEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_PenProximityEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_PenTouchEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_PenTouchEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_PinchFingerEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_PinchFingerEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_PixelFormatDetails.padding` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_QuitEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_QuitEvent.timestamp` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_QuitEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_RenderEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_RenderEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_SensorEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_SensorEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_StorageInterface.close` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.copy` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.enumerate` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.info` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.mkdir` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.read_file` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.ready` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.remove` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.rename` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.space_remaining` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_StorageInterface.write_file` | native_callback | Native function address setter already exists for this slot; host owns callback/userdata lifetime. |
| `SDL_Surface.flags` | adapted | Read-only metadata and temporary per-plane bytes for valid native SDL surfaces; caller must preserve backing storage and lock lifetime. |
| `SDL_Surface.format` | adapted | Read-only metadata and temporary per-plane bytes for valid native SDL surfaces; caller must preserve backing storage and lock lifetime. |
| `SDL_Surface.h` | adapted | Surface dimensions returned through scalar ref adapter. |
| `SDL_Surface.pitch` | adapted | Read-only metadata and temporary per-plane bytes for valid native SDL surfaces; caller must preserve backing storage and lock lifetime. |
| `SDL_Surface.pixels` | adapted | Read-only metadata and temporary per-plane bytes for valid native SDL surfaces; caller must preserve backing storage and lock lifetime. |
| `SDL_Surface.refcount` | host_only | Native resource reference count; script owners use SDL destruction/scopes, not direct count mutation. |
| `SDL_Surface.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_Surface.w` | adapted | Surface dimensions returned through scalar ref adapter. |
| `SDL_TextEditingCandidatesEvent.candidates` | adapted | Copy candidate strings/list while the SDL payload is valid. |
| `SDL_TextEditingCandidatesEvent.padding1` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_TextEditingCandidatesEvent.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_TextEditingCandidatesEvent.padding3` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_TextEditingCandidatesEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_TextEditingCandidatesEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_TextEditingEvent.length` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_TextEditingEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_TextEditingEvent.start` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_TextEditingEvent.text` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_TextEditingEvent.timestamp` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_TextEditingEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_TextEditingEvent.windowID` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_TextInputEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_TextInputEvent.text` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_TextInputEvent.timestamp` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_TextInputEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_TextInputEvent.windowID` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_Texture.format` | adapted | Read texture dimensions/format through SDL queries and texture properties; no writable native owner layout. |
| `SDL_Texture.h` | adapted | Read texture dimensions/format through SDL queries and texture properties; no writable native owner layout. |
| `SDL_Texture.refcount` | host_only | Native resource reference count; script owners use SDL destruction/scopes, not direct count mutation. |
| `SDL_Texture.w` | adapted | Read texture dimensions/format through SDL queries and texture properties; no writable native owner layout. |
| `SDL_TouchFingerEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_TouchFingerEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_UserEvent.code` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_UserEvent.data1` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_UserEvent.data2` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_UserEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_UserEvent.timestamp` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_UserEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_UserEvent.windowID` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_VirtualJoystickDesc.Cleanup` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.Rumble` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.RumbleTriggers` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.SendEffect` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.SetLED` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.SetPlayerIndex` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.SetSensorsEnabled` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.Update` | native_callback | Native C address setter; userdata/code lifetime remains with the host. |
| `SDL_VirtualJoystickDesc.padding` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_VirtualJoystickDesc.padding2` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_VirtualJoystickTouchpadDesc.padding` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_WindowEvent.data1` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_WindowEvent.data2` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_WindowEvent.reserved` | internal | Padding, reserved or SDL-private implementation state; native ABI layout stays intact. |
| `SDL_WindowEvent.timestamp` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_WindowEvent.type` | tag | Discriminator comes from the enclosing SDL_Event; readers validate the active event alternative. |
| `SDL_WindowEvent.windowID` | adapted | Tag-checked event readers and owned decode_event expose payloads; strings/lists copied, user pointers remain borrowed. |
| `SDL_alignment_test.a` | internal | Header ABI alignment probe, not an application record. |
| `SDL_alignment_test.b` | internal | Header ABI alignment probe, not an application record. |
| `SDL_hid_device_info.manufacturer_string` | adapted | Borrowed next link has an accessor; wchar strings are copied through the UTF conversion adapter. |
| `SDL_hid_device_info.next` | adapted | Borrowed next link has an accessor; wchar strings are copied through the UTF conversion adapter. |
| `SDL_hid_device_info.product_string` | adapted | Borrowed next link has an accessor; wchar strings are copied through the UTF conversion adapter. |
| `SDL_hid_device_info.serial_number` | adapted | Borrowed next link has an accessor; wchar strings are copied through the UTF conversion adapter. |
