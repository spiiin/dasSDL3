options gen2
module sdl3_shader_storage_pack shared private
require dassdl3/sdl3_result public
require daslib/ast
require daslib/ast_boost
require daslib/templates_boost
require daslib/shader_block_layout
require daslib/math_boost

[macro_function]
def private storage_shape(st : Structure?; var errors : array<string>) : bool {
    if (st == null) {return false}
    for (f in st.fields) {
        var t <- clone_type(f._type)
        if (t.baseType == Type.tFixedArray) {
            if (t.fixedDim > 4096) {errors |> push("std430 field array is too large"); return false}
            t = t.firstType
        }
        if (t.baseType == Type.tStructure) {if (!storage_shape(t.structType, errors)) {return false}}
        elif (!matrix_info(t).ok && scalar_width(t.baseType) != 32 && t.baseType != Type.tInt64 && t.baseType != Type.tUInt64) {
            errors |> push("std430 pack supports 32-bit numeric fields, scalar int64/uint64, matrices and nested structs")
            return false
        }
    }
    var fields : array<BlockField>
    let layout = compute_block_layout("SDL std430", st, fields, errors, BlockLayoutRules.std430)
    if (!layout.ok) {return false}
    if (layout.size <= 0 || layout.size > 65536) {errors |> push("std430 element must fit in 64 KiB"); return false}
    return true
}

// Use upstream offsets/strides, only decompose accesses here (the upstream leaf
// walker is std140-only). Matrix columns and nested structs are copied separately.
[macro_function]
def private storage_writes(st : Structure?; access : ExpressionPtr; base : int; var writes : array<Std140Write>) {
    var fields : array<BlockField>; var errors : array<string>
    compute_block_layout("SDL std430", st, fields, errors, BlockLayoutRules.std430)
    for (i in 0 .. length(fields)) {
        let f = fields[i]; let t = st.fields[i]._type; let off = base + f.offset
        var field = new ExprField(at = access.at, value <- clone_expression(access), name := st.fields[i].name)
        if (f.is_matrix && f.matrix_width != 4) {
            for (c in 0 .. f.matrix_cols) {
                writes |> push(Std140Write(offset = off + c * 16, access = new ExprAt(at = access.at, subexpr <- clone_expression(field), index = new ExprConstInt(value = c))))
            }
        } elif (f.is_array) {
            for (e in 0 .. f.array_count) {
                var item = new ExprAt(at = access.at, subexpr <- clone_expression(field), index = new ExprConstInt(value = e))
                if (f.is_struct) {storage_writes(t.firstType.structType, item, off + e * f.array_stride, writes)}
                else {writes |> push(Std140Write(offset = off + e * f.array_stride, access = item))}
            }
        } elif (f.is_struct) {storage_writes(t.structType, field, off, writes)}
        else {writes |> push(Std140Write(offset = off, access = field))}
    }
}

class private StoragePackMacro : AstCallMacro {
    unpack : bool
    def override visit(prog : ProgramPtr; mod : Module?; var call : ExprCallMacro?) : ExpressionPtr {
        if (length(call.arguments) != 2) {macro_error(prog, call.at, "std430 pack/unpack expects values and bytes arrays"); return null}
        let values = call.arguments[unpack ? 1 : 0]
        let bytes = call.arguments[unpack ? 0 : 1]
        if (values._type == null) {return null}
        if (values._type.baseType != Type.tArray || values._type.firstType.baseType != Type.tStructure) {
            macro_error(prog, call.at, "std430 pack/unpack expects array<struct>"); return null
        }
        let st = values._type.firstType.structType
        var errors : array<string>; var fields : array<BlockField>
        if (!storage_shape(st, errors)) {macro_error(prog, call.at, empty(errors) ? "Invalid std430 type" : errors[0]); return null}
        let layout = compute_block_layout("SDL std430", st, fields, errors, BlockLayoutRules.std430)
        let stride = round_up(layout.size, layout.align)
        let vn = make_unique_private_name("__storage_values", call.at)
        let bn = make_unique_private_name("__storage_bytes", call.at)
        let ix = make_unique_private_name("__storage_index", call.at)
        var vt = clone_type(values._type); vt.flags.ref = false; vt.flags.constant = !unpack
        var closure : ExprMakeBlock?
        var expression : ExpressionPtr
        if (unpack) {
            expression = qmacro($(var $i(vn) : $t(vt); $i(bn) : array<uint8>) : SdlStatus {
                if (length($i(bn)) % $v(stride) != 0) {return err(SdlError(operation = "unpack_gpu_dsl_storage", message = "Byte count is not a multiple of std430 stride"), type<SdlUnit>)}
                resize($i(vn), length($i(bn)) / $v(stride))
            })
        } else {
            expression = qmacro($(var $i(vn) : $t(vt); var $i(bn) : array<uint8>) : SdlStatus {
                if (length($i(vn)) > 0x7fffffff / $v(stride)) {return err(SdlError(operation = "pack_gpu_dsl_storage", message = "Packed storage array is too large"), type<SdlUnit>)}
                resize($i(bn), length($i(vn)) * $v(stride))
                for (i in 0 .. length($i(bn))) {$i(bn)[i] = uint8(0)}
            })
        }
        closure = expression as ExprMakeBlock
        var body = closure._block as ExprBlock
        var loop = qmacro_block() {for ($i(ix) in 0 .. length($i(vn))) {}}
        var each = (loop as ExprBlock).list[0] as ExprFor
        var writes : array<Std140Write>
        storage_writes(st, qmacro($i(vn)[$i(ix)]), 0, writes)
        for (write in writes) {
            let off = write.offset; let leaf = write.access
            var emitted : ExpressionPtr
            if (unpack) {
                emitted = qmacro_block() {unsafe {
                    memcpy(addr<void?>($e(leaf)), addr<void?>($i(bn)[$i(ix) * $v(stride) + $v(off)]), typeinfo sizeof($e(leaf)))
                }}
            } else {
                emitted = qmacro_block() {unsafe {
                    let leaf_value = $e(leaf)
                    memcpy(addr<void?>($i(bn)[$i(ix) * $v(stride) + $v(off)]), addr<void?>(leaf_value), typeinfo sizeof(leaf_value))
                }}
            }
            for (stmt in (emitted as ExprBlock).list) {var copy = stmt; (each.body as ExprBlock).list |> emplace(copy)}
        }
        for (stmt in (loop as ExprBlock).list) {var copy = stmt; body.list |> emplace(copy)}
        var ret = qmacro_block() {return sdl_ok()}
        for (stmt in (ret as ExprBlock).list) {var copy = stmt; body.list |> emplace(copy)}
        return qmacro(invoke($e(expression), $e(values), $e(bytes)))
    }
}
[call_macro(name="pack_gpu_dsl_storage")]
class private PackStorage : StoragePackMacro {}
[call_macro(name="unpack_gpu_dsl_storage")]
class private UnpackStorage : StoragePackMacro {override unpack = true}
