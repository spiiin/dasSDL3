options gen2
module sdl3_scope shared private
require dassdl3/sdl3_try public
require daslib/ast
require daslib/ast_boost
require daslib/templates_boost

def private expand_scope(var body : ExprBlock?; prog : ProgramPtr) : bool {
    // Rewrite only this lexical block. A marker in a branch/defer must belong
    // to its own explicit sdl_scope, otherwise SdlUseMacro rejects it.
    for (index in range(length(body.list))) {
        let stmt = body.list[index]
        var marker = stmt
        var binding : VariablePtr
        if (stmt is ExprLet && length((stmt as ExprLet).variables) == 1) {
            binding = (stmt as ExprLet).variables[0]
            marker = binding.init
        }
        if (marker == null || !(marker is ExprCallMacro) || (marker as ExprCallMacro).name != "sdl_use") { continue }
        let use_call = marker as ExprCallMacro
        if (length(use_call.arguments) != 1 || !(use_call.arguments[0] is ExprCall)) {
            macro_error(prog, marker.at, "sdl_use expects one scoped function call without its final block")
            return false
        }
        var owner = clone_expression(use_call.arguments[0]) as ExprCall
        if (binding != null && binding._type.baseType == Type.autoinfer) {
            macro_error(prog, binding.at, "sdl_use binding needs an explicit callback parameter type")
            return false
        }
        var tail = new ExprBlock(at = marker.at)
        tail.blockFlags.isClosure = true
        tail.returnType = new TypeDecl(baseType = Type.autoinfer)
        if (binding != null) {
            var arg = new Variable(at = binding.at, name := string(binding.name))
            arg._type = clone_type(binding._type)
            tail.arguments |> emplace(arg)
        }
        for (next in range(index + 1, length(body.list))) {
            var item = body.list[next]
            tail.list |> emplace(item)
        }
        // Nest the tail before attaching it; each owner's original block
        // contract continues to control acquisition failure and cleanup.
        if (!expand_scope(tail, prog)) { return false }
        var callback : ExpressionPtr = new ExprMakeBlock(at = marker.at, _block = tail)
        owner.arguments |> emplace(callback)
        resize(body.list, index)
        var returned : ExpressionPtr = new ExprReturn(at = marker.at, subexpr = owner)
        (returned as ExprReturn).returnFlags.moveSemantics = true
        body.list |> emplace(returned)
        return true
    }
    return true
}

[call_macro(name="sdl_scope")]
class private SdlScopeMacro : AstCallMacro {
    // The with_* calls are intentionally incomplete until their callbacks
    // have been appended, so do not infer the body before this rewrite.
    def override canVisitArgument(call : ExprCallMacro?; argIndex : int) : bool { return false }
    def override visit(prog : ProgramPtr; mod : Module?; var call : ExprCallMacro?) : ExpressionPtr {
        if (length(call.arguments) != 1 || !(call.arguments[0] is ExprMakeBlock)) {
            macro_error(prog, call.at, "sdl_scope expects one literal block without parameters")
            return null
        }
        var closure = clone_expression(call.arguments[0]) as ExprMakeBlock
        var body = closure._block as ExprBlock
        if (body == null || !empty(body.arguments)) {
            macro_error(prog, call.at, "sdl_scope expects one literal block without parameters")
            return null
        }
        if (!expand_scope(body, prog)) { return null }
        return qmacro(invoke($e(closure)))
    }
}

[call_macro(name="sdl_use")]
class private SdlUseMacro : AstCallMacro {
    def override canVisitArgument(call : ExprCallMacro?; argIndex : int) : bool { return false }
    def override visit(prog : ProgramPtr; mod : Module?; var call : ExprCallMacro?) : ExpressionPtr {
        macro_error(prog, call.at, "sdl_use must be a direct statement or the sole initializer of one let/var inside sdl_scope")
        return null
    }
}
