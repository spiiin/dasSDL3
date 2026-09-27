options gen2
module sdl3_shader_access shared private
require spirv/spirv_shader public
require spirv/spirv_emit
require daslib/ast
require daslib/ast_boost
require daslib/templates_boost

// Companion to the upstream stage annotation. No shader source or SPIR-V parsing.
[function_macro(name="sdl_shader_access")]
class private ShaderAccess : AstFunctionAnnotation {
    def override apply(var fn : FunctionPtr; var group : ModuleGroup; var args : AnnotationArgumentList; var errors : das_string) : bool {
        let name = args |> find_arg("name") ?as tString ?? string(fn.name)
        var t = new TypeDecl(at = fn.at, baseType = Type.tArray)
        t.firstType = new TypeDecl(baseType = Type.tUInt)
        return add_global_var(compiling_module(), "{name}_access", t, fn.at, false)
    }
    def override fixup(var fn : FunctionPtr; var group : ModuleGroup; var args : AnnotationArgumentList; progArgs : AnnotationArgumentList; var errors : das_string) : bool {
        let name = args |> find_arg("name") ?as tString ?? string(fn.name)
        var global <- find_variable(compiling_module(), "{name}_access")
        if (global == null || global.init != null) {return true}
        var records : array<uint3>
        var errs : array<string>
        collect_dependencies(fn) $(_, globals) {
            for (v in globals) {
                let t = v._type
                let image = t.baseType == Type.tStructure && t.structType != null && (t.structType.name == "image2D" || t.structType.name == "image3D" || t.structType.name == "image2DArray")
                if (!(v.annotation |> find_arg("ssbo") is tBool) && !image) {continue}
                if (annotation_int(v.annotation, "enabled", 1, errs) == 0) {continue}
                if (v.annotation |> find_arg("maybe_readonly") is tBool) {errs |> push("SDL access metadata requires explicit @readonly instead of @maybe_readonly"); continue}
                let ro = v.annotation |> find_arg("readonly") is tBool
                let wo = v.annotation |> find_arg("writeonly") is tBool
                if (ro && wo) {errs |> push("SDL resource cannot be both readonly and writeonly"); continue}
                let set = annotation_int(v.annotation, "set", 0, errs)
                let binding = annotation_int(v.annotation, "binding", 0, errs)
                if (set < 0 || binding < 0) {errs |> push("SDL resource set/binding must be nonnegative"); continue}
                records |> push(uint3(uint(set), uint(binding), ro ? 1u : (wo ? 2u : 3u)))
            }
        }
        if (!empty(errs)) {errors := errs[0]; return false}
        // Stable set/binding ordering independent of dependency traversal order.
        for (i in 0 .. length(records)) {for (j in i + 1 .. length(records)) {
            if (records[j].x < records[i].x || (records[j].x == records[i].x && records[j].y < records[i].y)) {
                let saved = records[i]; records[i] = records[j]; records[j] = saved
            }
        }}
        var values <- array<uint>(0x53444c41u, uint(length(records)))
        for (record in records) {push(values, record.x); push(values, record.y); push(values, record.z)}
        var init = new ExprMakeArray(at = fn.at, makeType = new TypeDecl(baseType = Type.tUInt))
        init.gen2 = true
        for (value in values) {init.values |> emplace_new() <| new ExprConstUInt(at = fn.at, value = value)}
        global.init = qmacro(to_array_move($e(init)))
        return true
    }
}
