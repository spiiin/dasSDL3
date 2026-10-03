options gen2
module sdl3_shader_uniform_pack shared private
require dassdl3/sdl3_result public
require daslib/ast
require daslib/ast_boost
require daslib/templates_boost
require daslib/shader_block_layout
require daslib/math_boost

// Bound composites before the upstream layout's int arithmetic and AST unrolling.
[macro_function]
def private uniform_size_ok(st : Structure?; var errors : array<string>) : bool {
    if (st == null) { return false }
    for (field in st.fields) {
        let t = field._type
        if (t.baseType == Type.tStructure && !uniform_size_ok(t.structType, errors)) {return false}
        if (t.baseType == Type.tFixedArray) {
            if (t.fixedDim > 2048) {errors |> push("SDL uniform exceeds 32 KiB"); return false}
            if (t.firstType != null && t.firstType.baseType == Type.tStructure && !uniform_size_ok(t.firstType.structType, errors)) {return false}
        }
    }
    var fields : array<BlockField>
    let layout = compute_block_layout("SDL uniform", st, fields, errors)
    if (!layout.ok) {return false}
    if (layout.size <= 0 || layout.size > 32768) {errors |> push("SDL uniform exceeds 32 KiB"); return false}
    return true
}

// Offsets and leaf accesses come from the same std140 walk as dasSpirv.
[call_macro(name="pack_gpu_dsl_uniform")]
class private UniformBytesMacro : AstCallMacro {
    def override visit(prog : ProgramPtr; mod : Module?; var call : ExprCallMacro?) : ExpressionPtr {
        if (length(call.arguments) != 2) {
            macro_error(prog, call.at, "pack_gpu_dsl_uniform expects a struct value and mutable byte array")
            return null
        }
        let argument = call.arguments[0]
        if (argument._type == null) { return null }
        if (argument._type.baseType != Type.tStructure) {
            macro_error(prog, call.at, "pack_gpu_dsl_uniform expects a std140 struct")
            return null
        }
        var fields : array<BlockField>
        var errors : array<string>
        if (!uniform_size_ok(argument._type.structType, errors)) {
            macro_error(prog, call.at, empty(errors) ? "Unsupported SDL uniform" : errors[0])
            return null
        }
        let layout = compute_block_layout("SDL uniform", argument._type.structType, fields, errors)
        if (!layout.ok || layout.size > 32768) {
            macro_error(prog, call.at, empty(errors) ? "SDL uniform exceeds 32 KiB" : errors[0])
            return null
        }
        let size = round_up(layout.size, 16)
        let value_name = make_unique_private_name("__uniform_value", call.at)
        let bytes_name = make_unique_private_name("__uniform_bytes", call.at)
        var value_type = clone_type(argument._type)
        value_type.flags.ref = false
        value_type.flags.constant = true
        var closure = qmacro($(var $i(value_name) : $t(value_type); var $i(bytes_name) : array<uint8>) {
            resize($i(bytes_name), $v(size))
            for (i in 0 .. $v(size)) {$i(bytes_name)[i] = uint8(0)}
        }) as ExprMakeBlock
        var body = closure._block as ExprBlock
        var writes : array<Std140Write>
        std140_block_writes(argument._type.structType, new ExprVar(at = call.at, name := value_name), 0, writes)
        for (write in writes) {
            let offset = write.offset
            let leaf = write.access
            var emitted = qmacro_block() {
                unsafe {
                    let leaf_value = $e(leaf)
                    memcpy(addr<void?>($i(bytes_name)[$v(offset)]), addr<void?>(leaf_value), typeinfo sizeof(leaf_value))
                }
            }
            for (stmt in (emitted as ExprBlock).list) { var copy = stmt; body.list |> emplace(copy) }
        }
        return qmacro(invoke($e(closure), $e(argument), $e(call.arguments[1])))
    }
}

