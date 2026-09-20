options gen2
require dassdl3/sdl3_properties_boost
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl(0u) {
        let global=SDL_GetGlobalProperties()
        verify(global!=0u && SDL_GetGlobalProperties()==global)
        var called=false
        let bad=with_properties_lock(0u) { called=true
            return sdl_ok()
        } |> is_ok
        verify(!bad && !called)
        var names : array<string>
        push(names,"old")
        verify(!is_ok(property_names(0u,names)) && length(names)==0)
        verify(!SDL_SetNumberProperty(0u,"answer",42l))
        verify(SDL_GetNumberProperty(0u,"answer",-77l)==-77l)
        let baseline=SDLTestPropertyCleanupCount()
        var saved=""
        var owned_id=0u
        let owned=with_properties() $(props : uint) {
            owned_id=props
            verify(SDL_GetPropertyType(props,"absent")==SDL_PropertyType.PROPERTY_TYPE_INVALID)
            verify(!SDL_HasProperty(props,"absent"))
            verify(SDL_GetBooleanProperty(props,"absent",true))
            verify(SDL_GetFloatProperty(props,"absent",2.5)==2.5)
            verify(unwrap_or(property_string(props,"absent","fallback"), "")=="fallback")
            verify(is_ok(property_names(props,names)) && length(names)==0)
            verify(SDL_SetStringProperty(props,"имя","Привет SDL"))
            saved=unwrap_or(property_string(props,"имя"), "")
            verify(SDL_GetStringProperty(props,"имя","")==saved)
            verify(SDL_GetPropertyType(props,"имя")==SDL_PropertyType.PROPERTY_TYPE_STRING)
            verify(SDL_SetNumberProperty(props,"answer",42l))
            verify(SDL_SetNumberProperty(props,"wide",9007199254740993l))
            verify(SDL_GetNumberProperty(props,"wide",0l)==9007199254740993l)
            verify(SDL_GetPropertyType(props,"wide")==SDL_PropertyType.PROPERTY_TYPE_NUMBER)
            verify(unwrap_or(property_string(props,"wide","fallback"), "")=="9007199254740993")
            verify(SDL_GetNumberProperty(props,"имя",-1l)==0l)
            verify(SDL_SetFloatProperty(props,"float",1.25))
            verify(SDL_GetFloatProperty(props,"float",0.0)==1.25)
            verify(unwrap_or(property_string(props,"float"), "")=="1.250000")
            verify(SDL_GetPropertyType(props,"float")==SDL_PropertyType.PROPERTY_TYPE_FLOAT)
            verify(SDL_SetBooleanProperty(props,"bool",false))
            verify(!SDL_GetBooleanProperty(props,"bool",true))
            verify(unwrap_or(property_string(props,"bool"), "")=="false")
            verify(SDL_GetPropertyType(props,"bool")==SDL_PropertyType.PROPERTY_TYPE_BOOLEAN)
            unsafe {
                let ptr=SDLTestPropertyPointer()
                verify(SDL_SetPointerProperty(props,"pointer",ptr))
                verify(SDL_GetPointerProperty(props,"pointer",null)==ptr)
                verify(SDL_GetPropertyType(props,"pointer")==SDL_PropertyType.PROPERTY_TYPE_POINTER)
                verify(unwrap_or(property_string(props,"pointer","fallback"), "")=="fallback")
                verify(SDL_SetPointerProperty(props,"pointer",null))
                verify(!SDL_HasProperty(props,"pointer"))
            }
            let locked=with_properties_lock(props) {
                // SDL property locks are recursive on the current thread.
                verify(SDL_LockProperties(props))
                SDL_UnlockProperties(props)
                return sdl_ok()
            } |> is_ok
            verify(locked && SDLTestPropertiesOtherThread(props))
            verify(SDLTestAttachPropertyCleanup(props,"owned"))
            let copy=SDL_CreateProperties()
            verify(copy!=0u)
            verify(SDL_CopyProperties(props,copy))
            verify(SDL_GetNumberProperty(copy,"answer",0l)==42l)
            verify(unwrap_or(property_string(copy,"имя"), "")==saved)
            verify(!SDL_HasProperty(copy,"owned")) // SDL excludes pointers with cleanup.
            SDL_DestroyProperties(copy)
            verify(SDLTestPropertyCleanupCount()==baseline)
            verify(SDL_ClearProperty(props,"owned"))
            verify(SDLTestPropertyCleanupCount()==baseline+1)
            verify(SDLTestAttachPropertyCleanup(props,"owned"))
            verify(SDL_SetStringProperty(props,"owned","replacement"))
            verify(SDLTestPropertyCleanupCount()==baseline+2)
            verify(SDLTestAttachPropertyCleanup(props,"owned"))
            verify(is_ok(property_names(props,names)))
            verify(length(names)==6)
            var found=false
            for(name in names) { if(name=="имя") { found=true } }
            verify(found)
            verify(SDL_SetStringProperty(props,"имя","changed"))
            verify(saved=="Привет SDL")
            return sdl_ok()
        } |> is_ok
        verify(owned && SDLTestPropertyCleanupCount()==baseline+3)
        verify(saved=="Привет SDL" && length(names)==6)
        verify(!SDL_LockProperties(owned_id))
        verify(SDL_GetGlobalProperties()==global) // Borrowed global was not destroyed.
        verify(!SDL_CopyProperties(0u,global))

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    print("Properties values, copies, enumeration, locks and ownership PASS\n")
    return 0
}
