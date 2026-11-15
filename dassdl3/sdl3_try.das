options gen2
module sdl3_try shared private
require dassdl3/sdl3_result public
require daslib/ast
require daslib/ast_boost
require daslib/templates_boost

// Type-inference signature only. The infer pass expands direct uses and rejects
// all remaining calls/addresses before optimization or execution.
[unused_argument(value)]
def public sdl_try(value : $Result<auto(T); SdlError>) : T {
    var inferred : T
    return <- inferred
}

def is_sdl_try_function(fn : Function?) : bool {
    if (fn == null) { return false }
    let origin = fn.fromGeneric
    return origin != null && origin.name == "sdl_try" && origin._module.name == "sdl3_try"
}

def is_sdl_error(error_type : TypeDeclPtr) : bool {
    return (error_type.baseType == Type.tStructure && error_type.structType.name == "SdlError"
        && error_type.structType._module.name == "sdl3_result")
}

// daslib/result is tuple<_is_ok; _value; _error> up to daslang 0.6.4 and variant<err; ok> from
// 0.6.5 on. Either way the value type is argTypes[1]; the expansion below goes through the
// Result API both shapes share. The value leaves the macro's own temporary with move_unwrap:
// unwrap takes its Result const, which a pointer payload does not survive.
def is_sdl_result(rt : TypeDeclPtr) : bool {
    if (rt == null) { return false }
    if (rt.baseType == Type.tTuple && length(rt.argTypes) == 3 && length(rt.argNames) == 3) {
        return (rt.argNames[0] == "_is_ok" && rt.argNames[1] == "_value" && rt.argNames[2] == "_error"
            && rt.argTypes[0].baseType == Type.tBool && is_sdl_error(rt.argTypes[2]))
    }
    if (rt.baseType == Type.tVariant && length(rt.argTypes) == 2 && length(rt.argNames) == 2) {
        return rt.argNames[0] == "err" && rt.argNames[1] == "ok" && is_sdl_error(rt.argTypes[0])
    }
    return false
}

class SdlTryVisitor : AstVisitor {
    changed : bool
    @do_not_delete func : Function?
    returns : array<TypeDeclPtr>
    in_finally : int
    def override preVisitExprBlockFinal(blk : ExprBlock?) { in_finally++ }
    def override visitExprBlockFinal(blk : ExprBlock?) { in_finally-- }
    def override preVisitFunction(var fn : FunctionPtr) {
        func = fn
        clear(returns)
        var rt = clone_type(fn.result)
        emplace(returns, rt)
    }
    def override preVisitExprBlock(var blk : ExprBlock?) {
        if (blk.blockFlags.isClosure) {
            var rt = clone_type(blk.returnType)
            emplace(returns, rt)
        }
    }
    def override visitExprBlock(var blk : ExprBlock?) : ExpressionPtr {
        var expanded : array<ExpressionPtr>
        for (stmt in blk.list) {
            var target = stmt
            if (stmt is ExprLet && length((stmt as ExprLet).variables) == 1) {
                target = (stmt as ExprLet).variables[0].init
            } elif (stmt is ExprCopy && (stmt as ExprCopy).left is ExprVar) {
                target = (stmt as ExprCopy).right
            } elif (stmt is ExprMove && (stmt as ExprMove).left is ExprVar) {
                target = (stmt as ExprMove).right
            }
            if (target != null && target is ExprCall && is_sdl_try_function((target as ExprCall).func)) {
                let call = target as ExprCall
                let tmp = make_unique_private_name("__sdl_try", call.at)
                if (empty(returns) || !is_sdl_result(returns[length(returns) - 1]) || in_finally != 0) {
                    macro_sticky_error(compiling_program(), call.at, "sdl_try requires an enclosing Result-returning function or block")
                    var copy = stmt
                    expanded |> emplace(copy)
                    continue
                }
                let rt = returns[length(returns) - 1]
                let output = rt.argTypes[1]
                var prefix = qmacro_block() {
                    var $i(tmp) <- $e(call.arguments[0])
                    if (!result::is_ok($i(tmp))) {
                        return result::err(result::unwrap_err($i(tmp)), type<$t(output)>)
                    }
                }
                // Copy scalar/string/pointer results, consume move-only results.
                ((prefix as ExprBlock).list[0] as ExprLet).variables[0].flags.init_via_move = !call.arguments[0]._type.canCopy
                prefix |> force_at(call.at)
                for (item in (prefix as ExprBlock).list) {
                    var copy = item
                    expanded |> emplace(copy)
                }
                if (stmt is ExprLet) {
                    (stmt as ExprLet).variables[0].init = qmacro(result::move_unwrap($i(tmp)))
                    var copy = stmt
                    expanded |> emplace(copy)
                } elif (stmt is ExprCopy) {
                    (stmt as ExprCopy).right = qmacro(result::move_unwrap($i(tmp)))
                    var copy = stmt
                    expanded |> emplace(copy)
                } elif (stmt is ExprMove) {
                    (stmt as ExprMove).right = qmacro(result::move_unwrap($i(tmp)))
                    var copy = stmt
                    expanded |> emplace(copy)
                }
                changed = true
                func.not_inferred()
            } else {
                var copy = stmt
                expanded |> emplace(copy)
            }
        }
        clear(blk.list)
        for (item in expanded) { blk.list |> emplace(item) }
        if (blk.blockFlags.isClosure) { pop(returns) }
        return <- blk
    }
}
class SdlTryUnexpanded : AstVisitor {
    def override visitExprCall(var call : ExprCall?) : ExpressionPtr {
        if (is_sdl_try_function(call.func)) {
            macro_sticky_error(compiling_program(), call.at, "sdl_try must be a standalone statement, the sole initializer of one let/var, or the full RHS of assignment to a variable; it is forbidden in finally/defer")
        }
        return <- call
    }
    def override visitExprAddr(var expr : ExprAddr?) : ExpressionPtr {
        if (is_sdl_try_function(expr.func)) {
            macro_sticky_error(compiling_program(), expr.at, "sdl_try is a macro; taking its function address is forbidden")
        }
        return <- expr
    }
}
[infer_macro]
class SdlTryPass : AstPassMacro {
    def override apply(prog : ProgramPtr; mod : Module?) : bool {
        var visitor = new SdlTryVisitor()
        make_visitor(*visitor) $(adapter) { visit_module(prog, adapter, mod) }
        let changed = visitor.changed
        unsafe { delete visitor }
        var remaining = new SdlTryUnexpanded()
        make_visitor(*remaining) $(adapter) { visit_module(prog, adapter, mod) }
        unsafe { delete remaining }
        return changed
    }
}
