options gen2
module text_editing shared public
require strings public
// SDL text input owns UTF-8. Backspace removes one code point, not one byte.
def public utf8_previous(value : string) : int {
    var index=length(value)-1
    while(index>0 && (uint(character_at(value,index))&0xc0u)==0x80u){index--}
    return index
}
