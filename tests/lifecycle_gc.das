options gen2
options gc
options persistent_heap
var frames = 0
var keep : array<int>
var frame_text = ""
var collections_before = 0ul
[export]
def init() {
    // Exercise host collection within the 60-frame smoke run, independently
    // of the SDK's default allocation budget.
    set_gc_allocation_budget(262144ul, 262144ul)
    collections_before = gc_collection_stats().x
    resize(keep, 4)
    keep[0] = 123
}
[export]
def update() : bool {
    verify(keep[0] == 123)
    var junk : array<float>
    resize(junk, 16384)
    junk[0] = float(frames)
    frame_text = "frame {frames}"
    keep[1] = int(junk[0]) + length(frame_text)
    frames++
    return frames < 400
}
[export]
def shutdown() {
    verify(frames >= 60)
    verify(keep[0] == 123 && length(frame_text) > 0)
    verify(gc_collection_stats().x > collections_before)
    print("GC frames={frames} heap={heap_bytes_allocated()}\n")
    verify(heap_bytes_allocated() < 1048576ul)
    print("GC roots and bounded heap PASS\n")
}
