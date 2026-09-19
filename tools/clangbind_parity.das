// Compatibility experiment: CppGenBind emits functions; existing type/constant
// registrations and native adapters remain the common compatibility contract.
options gen2
options no_unused_block_arguments = false
require cbind/cbind_boost
require daslib/fio
require daslib/strings_boost
require strings

class SdlParityGen : CppGenBind {
    selected : table<string; bool>
    signatures : FILE const?
    def SdlParityGen(inc, sdk, output, allowlist : string) {
        let args <- array<string>("-xc-header", "-std=c11", "--target=x86_64-pc-windows-msvc",
            "-Wno-pragma-pack", "-I{inc}", "-resource-dir={sdk}/lib/clang/22")
        super("SDL3/SDL.h", "{inc}/", args)
        for (name in split(replace(fread(allowlist), "\r", ""), "\n")) {
            if (!empty(name)) { selected[name] = true }
        }
        func_file = fopen("{output}/functions.inc", "wb")
        signatures = fopen("{output}/signatures.tsv", "wb")
        if (func_file == null || signatures == null) { panic("Cannot open parity output") }
    }
    def override skip_file(fname : string) : bool { return false }
    def override parse(var cursor : CXCursor) {
        // Function-only parity: do not descend into unrelated system-header AST.
        clang_visitChildren(cursor) $(var c, parent) {
            if (clang_getCursorKind(c) == CXCursorKind.FunctionDecl && !skip_function(c)) {
                parse_FunctionDecl(c)
            }
            return CXChildVisitResult.Continue
        }
    }
    def override skip_function(var c : CXCursor) : bool {
        return !key_exists(selected, string(clang_getCursorSpelling(c))) || AnyGenBind`skip_function(self, c)
    }
    def override skip_alias(var c : CXCursor) : bool { return true }
    def override parse_Struct(var c : CXCursor; struct_name : string) { pass }
    def override parse_Field(var c : CXCursor) { pass }
    def override parse_Enum(var c : CXCursor; enum_name : string) { pass }
    def override step_Function { pass }
    def override functionPtrSpelling(var c : CXCursor; isMethod : bool) : string {
        return replace(CppGenBind`functionPtrSpelling(self, c, isMethod), "_Bool", "bool")
    }
    def override parse_FunctionDecl(var c : CXCursor) {
        let name = string(clang_getCursorSpelling(c))
        var tp = clang_getCursorType(c)
        let cc = clang_getFunctionTypeCallingConv(tp)
        if (cc != CXCallingConv.C && cc != CXCallingConv.Win64) {
            panic("Unsupported calling convention for {name}: {int(cc)}")
        }
        fwrite(signatures, "{name}\t{string(clang_getTypeSpelling(tp))}")
        for (i in urange(clang_Cursor_getNumArguments(c))) {
            var arg = clang_Cursor_getArgument(c, i)
            fwrite(signatures, "\t{string(clang_getCursorSpelling(arg))}")
        }
        fwrite(signatures, "\n")
        CppGenBind`parse_FunctionDecl(self, c)
    }
    def finish { fclose(func_file); fclose(signatures) }
}

[export]
def main : int {
    let args <- get_command_line_arguments()
    if (length(args) < 5) { return 2 }
    var gen = new SdlParityGen(args[length(args)-4], args[length(args)-3], args[length(args)-2], args[length(args)-1])
    AnyGenBind`generate(*gen)
    gen->finish()
    unsafe { delete gen }
    return 0
}
