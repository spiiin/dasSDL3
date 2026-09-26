options gen2
module sdl3_camera_boost shared public
require dassdl3/sdl3_boost public
require daslib/option public
require daslib/defer

// Borrowed frame. Release to its camera, never destroy_surface. No automatic ownership.
struct CameraFrame {
    surface : SDL_Surface?
    timestamp_ns : uint64
}
def public cameras() {
    var ids : array<uint>
    if(!SDL_GetCamerasCopy(ids)) {return err(sdl_error("SDL_GetCameras"),type<array<uint>>)}
    return <- move_ok(ids,type<SdlError>)
}
def public camera_supported_formats(id : uint) {
    var specs : array<SDL_CameraSpec>
    if(!SDL_GetCameraSupportedFormatsCopy(id,specs)) {return err(sdl_error("SDL_GetCameraSupportedFormats"),type<array<SDL_CameraSpec>>)}
    return <- move_ok(specs,type<SdlError>)
}
def public camera_driver(index : int) {
    if(index<0 || index>=SDL_GetNumCameraDrivers()) {return none(type<string>)}
    return some(SDL_GetCameraDriverCopy(index))
}
def public current_camera_driver() {
    let name=SDL_GetCurrentCameraDriverCopy()
    if(length(name)==0) {return none(type<string>)}
    return some(name)
}
def public camera_name(id : uint) {
    var name : string
    if(!SDL_GetCameraNameCopy(id,name)) {return err(sdl_error("SDL_GetCameraName"),type<string>)}
    return ok(name,type<SdlError>)
}
// UNKNOWN can also be returned for an invalid id; preserve SDL's ambiguous sentinel.
def public camera_position(id : uint) {return SDL_GetCameraPosition(id)}
// Live camera precondition: -1 denied, 0 pending, 1 approved; not a bool or Result.
def public camera_permission_state(camera : SDL_Camera?) : SDL_CameraPermissionState {return SDL_GetCameraPermissionState(camera)}
def public camera_id(camera : SDL_Camera?) {
    let id=SDL_GetCameraID(camera)
    if(id==0u) {return err(sdl_error("SDL_GetCameraID"),type<uint>)}
    return ok(id,type<SdlError>)
}
def public camera_properties(camera : SDL_Camera?) {
    let id=SDL_GetCameraProperties(camera)
    if(id==0u) {return err(sdl_error("SDL_GetCameraProperties"),type<uint>)}
    return ok(id,type<SdlError>)
}
def public camera_format(camera : SDL_Camera?) {
    var spec : SDL_CameraSpec
    if(!SDL_GetCameraFormatRef(camera,spec)) {return err(sdl_error("SDL_GetCameraFormat"),type<SDL_CameraSpec>)}
    return ok(spec,type<SdlError>)
}
def public open_camera(id : uint) {
    var camera=SDL_OpenCamera(id,null)
    if(camera==null) {return err(sdl_error("SDL_OpenCamera"),type<SDL_Camera?>)}
    return <- move_ok(camera,type<SdlError>)
}
def public open_camera(id : uint; spec : SDL_CameraSpec) {
    var camera=SDL_OpenCameraRef(id,spec)
    if(camera==null) {return err(sdl_error("SDL_OpenCamera"),type<SDL_Camera?>)}
    return <- move_ok(camera,type<SdlError>)
}
def public close_camera(var camera : SDL_Camera?&) {SDL_CloseCamera(camera);camera=null}
def public acquire_camera_frame(camera : SDL_Camera?) {
    var frame : CameraFrame
    let state=SDL_AcquireCameraFrameRef(camera,frame.surface,frame.timestamp_ns)
    if(state<0) {return err(sdl_error("SDL_AcquireCameraFrame"),type<$Option<CameraFrame>>)}
    var value : $Option<CameraFrame>
    if(state>0) {value <- move_some(frame)}
    return <- move_ok(value,type<SdlError>)
}
def public release_camera_frame(camera : SDL_Camera?; var frame : CameraFrame) {
    SDL_ReleaseCameraFrame(camera,frame.surface)
    frame.surface=null
    frame.timestamp_ns=0ul
}
def public with_camera(id : uint; body : block<(camera : SDL_Camera?) : $Result<auto(CameraValue); SdlError>>) {
    let camera=SDL_OpenCamera(id,null)
    if(camera==null) {return err(sdl_error("SDL_OpenCamera"),type<CameraValue>)}
    {
        defer() {SDL_CloseCamera(camera)}
        static_if(typeinfo can_copy(type<$Result<CameraValue; SdlError>>)) {return body(camera)}
        else {return <- body(camera)}
    }
}
def public with_camera(id : uint; spec : SDL_CameraSpec; body : block<(camera : SDL_Camera?) : $Result<auto(CameraValue); SdlError>>) {
    let camera=SDL_OpenCameraRef(id,spec)
    if(camera==null) {return err(sdl_error("SDL_OpenCamera"),type<CameraValue>)}
    {
        defer() {SDL_CloseCamera(camera)}
        static_if(typeinfo can_copy(type<$Result<CameraValue; SdlError>>)) {return body(camera)}
        else {return <- body(camera)}
    }
}
// None skips the body. Result/Option do not extend the lifetime of the borrowed frame.
def public with_camera_frame(camera : SDL_Camera?; body : block<(frame : CameraFrame) : $Result<auto(CameraValue); SdlError>>) {
    var frame : CameraFrame
    let state=SDL_AcquireCameraFrameRef(camera,frame.surface,frame.timestamp_ns)
    if(state<0) {return err(sdl_error("SDL_AcquireCameraFrame"),type<$Option<CameraValue>>)}
    if(state==0) {
        var absent : $Option<CameraValue>
        return <- move_ok(absent,type<SdlError>)
    }
    {
        defer() {SDL_ReleaseCameraFrame(camera,frame.surface)}
        var result <- body(frame)
        if(is_err(result)) {return err(unwrap_err(result),type<$Option<CameraValue>>)}
        var value : CameraValue -const
        static_if(typeinfo can_copy(value)) {value = move_unwrap(result)}
        else {value <- move_unwrap(result)}
        var present <- move_some(value)
        return <- move_ok(present,type<SdlError>)
    }
}
