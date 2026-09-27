options gen2
[no_aot, never_inline]
def interpreted_only() : bool { print("must not execute"); return false }
[export]
def init() {}
[export]
def update() : bool { return interpreted_only() }
[export]
def shutdown() {}
