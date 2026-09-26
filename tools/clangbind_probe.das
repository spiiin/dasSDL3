// Usage: daslang tools/clangbind_probe.das -- <SDL include> <LLVM SDK root>
// Toolchain probe only: this does not replace generated SDL registrations.
options gen2
options no_unused_block_arguments = false
require cbind/cbind_boost
require daslib/fio
require daslib/safe_addr
require strings

[export]
def main : int {
    let cmd <- get_command_line_arguments()
    if (length(cmd) < 3) {
        print("Expected SDL include directory and LLVM SDK root\n")
        return 2
    }
    let inc = cmd[length(cmd) - 2]
    let sdk = cmd[length(cmd) - 1]
    let args <- array<string>("-xc-header", "-std=c11", "--target=x86_64-pc-windows-msvc",
        "-Wno-pragma-pack", "-I{inc}", "-resource-dir={sdk}/lib/clang/22")
    print("libclang: {string(clang_getClangVersion())}\n")
    var index = clang_createIndex(0, 0)
    if (index == null) { return 1 }
    var unit = clang_parseTranslationUnit(index, "{inc}/SDL3/SDL.h",
        unsafe(addr(args[0])), length(args), null, 0u, CXTranslationUnit_SkipFunctionBodies)
    if (unit == null) {
        clang_disposeIndex(index)
        print("Could not parse SDL.h\n")
        return 1
    }
    var errors = 0
    for (i in urange(clang_getNumDiagnostics(unit))) {
        var diag = clang_getDiagnostic(unit, i)
        if (int(clang_getDiagnosticSeverity(diag)) >= 3) { errors++ }
        print("{string(clang_formatDiagnostic(diag, clang_defaultDiagnosticDisplayOptions()))}\n")
        clang_disposeDiagnostic(diag)
    }
    var rect_ok, enum_ok, gpu_ok, callback_ok, array_ok = false
    var functions = 0
    var cursor = clang_getTranslationUnitCursor(unit)
    clang_visitChildren(cursor) $(var c, parent) {
        let name = string(clang_getCursorSpelling(c))
        let kind = clang_getCursorKind(c)
        if (kind == CXCursorKind.FunctionDecl && starts_with(name, "SDL_")) { functions++ }
        if (kind == CXCursorKind.StructDecl && name == "SDL_FRect") {
            var tp = clang_getCursorType(c)
            rect_ok = clang_Type_getSizeOf(tp) == 16l
        }
        if (kind == CXCursorKind.EnumConstantDecl && name == "SDL_PIXELFORMAT_RGBA8888") {
            enum_ok = clang_getEnumConstantDeclUnsignedValue(c) != 0ul
        }
        if (kind == CXCursorKind.StructDecl && name == "SDL_GPUGraphicsPipelineCreateInfo") {
            var tp = clang_getCursorType(c)
            gpu_ok = clang_Type_getSizeOf(tp) > 0l
        }
        if (kind == CXCursorKind.TypedefDecl && name == "SDL_AudioStreamCallback") {
            var tp = clang_getTypedefDeclUnderlyingType(c)
            var pointee = clang_getPointeeType(tp)
            callback_ok = pointee.kind == CXTypeKind.FunctionProto
        }
        if (kind == CXCursorKind.FieldDecl && name == "data" && string(clang_getCursorSpelling(parent)) == "SDL_GUID") {
            var tp = clang_getCursorType(c)
            array_ok = clang_getArraySize(tp) == 16l
        }
        return CXChildVisitResult.Recurse
    }
    clang_disposeTranslationUnit(unit)
    clang_disposeIndex(index)
    print("SDL probe: functions={functions}, rect={rect_ok}, enum={enum_ok}, gpu={gpu_ok}, callback={callback_ok}, fixed_array={array_ok}, errors={errors}\n")
    return errors == 0 && functions > 1000 && rect_ok && enum_ok && gpu_ok && callback_ok && array_ok ? 0 : 1
}
