options gen2
module bgfx_multipass_checks shared public
require bgfx_capture public
require daslib/defer public
require math public

def changed(a, b : array<uint8>; tolerance : int = 2) : int {
    verify(length(a) == length(b), "Image extent mismatch")
    var count = 0
    for (i in 0..length(a) / 4) {
        var different = false
        for (c in 0..3) { if (abs(int(a[i * 4 + c]) - int(b[i * 4 + c])) > tolerance) { different = true } }
        if (different) { count++ }
    }
    return count
}
def visible(bytes : array<uint8>) {
    var lo = 255; var hi = 0
    for (i in 0..length(bytes) / 4) { let c = int(bytes[i * 4]) + int(bytes[i * 4 + 1]) + int(bytes[i * 4 + 2]); lo = min(lo, c); hi = max(hi, c) }
    verify(hi - lo > 50, "Empty or constant image")
}
