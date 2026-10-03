options gen2
// Deliberately excluded from the Mac AOT source list.
[export]
def main(smoke : bool) : int {
    print("must not execute: missing Mac AOT code\n")
    return 0
}
