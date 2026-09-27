options gen2
module sdl3_shader_storage_spirv shared public
require dassdl3/sdl3_shader_resources
require dassdl3/sdl3_try
require dassdl3/sdl3_result public
require spirv/spirv_dis
require spirv/spirv_grammar

// SDL's readonly storage textures are sampled-image descriptors. dasSpirv emits
// image2D/@readonly as storage images. Legalize only that boundary, using the
// upstream instruction walker; RW images and the shader's arithmetic stay intact.
def public gpu_dsl_storage_spirv(words, reflection, access : array<uint>) : $Result<array<uint>; SdlError> {
    let failure = SdlError(operation = "gpu_dsl_storage_spirv", message = "Unsupported or malformed SPIR-V readonly image shape")
    if (length(reflection) < 2) {return err(failure, type<array<uint>>)}
    gpu_dsl_resource_info(reflection, access, reflection[1]) |> sdl_try
    if (length(words) < 5 || words[0] != 0x07230203u || words[3] == 0u || words[3] > 0x7ffffff0u) {return err(failure, type<array<uint>>)}
    var image_at, pointer_at : table<uint; int>
    var pointers, variables, sets, bindings : table<uint; uint>
    var pointer_storage : table<uint; uint>
    var uint_type = 0u; var zero = 0u; var consumed = 5
    foreach_inst(words) $(op, w, s, n) {
        consumed = s + n
        if (op == uint(SpvOp.TypeImage) && n == 8) {image_at[w[s]] = s}
        elif (op == uint(SpvOp.TypePointer) && n == 3) {pointer_at[w[s]] = s; pointers[w[s]] = w[s + 2]; pointer_storage[w[s]] = w[s + 1]}
        elif (op == uint(SpvOp.Variable) && n >= 3) {variables[w[s + 1]] = w[s]}
        elif (op == uint(SpvOp.Decorate) && n == 3) {
            if (w[s + 1] == uint(SpvDecoration.DescriptorSet)) {sets[w[s]] = w[s + 2]}
            elif (w[s + 1] == uint(SpvDecoration.Binding)) {bindings[w[s]] = w[s + 2]}
        } elif (op == uint(SpvOp.TypeInt) && n == 3 && w[s + 1] == 32u && w[s + 2] == 0u) {uint_type = w[s]}
        elif (op == uint(SpvOp.Constant) && n == 3 && w[s] == uint_type && w[s + 2] == 0u) {zero = w[s + 1]}
    }
    if (consumed != length(words)) {return err(failure, type<array<uint>>)}
    var readonly_vars : table<uint; uint>
    for (id in keys(variables)) {
        let set = sets?[id] ?? 0xffffffffu; let slot = bindings?[id] ?? 0xffffffffu
        let ptr = (variables?[id] ?? 0u); let img = pointers?[ptr] ?? 0u
        if (!key_exists(image_at, img)) {continue}
        for (i in 0 .. int(access[1])) {let a = 2 + i * 3
            if (access[a] == set && access[a + 1] == slot && access[a + 2] == 1u) {readonly_vars[id] = img}
        }
    }
    if (empty(readonly_vars)) {var copy <- clone_to_move(words); return <- move_ok(copy, type<SdlError>)}
    var next_id = words[3]
    var converted_images, converted_pointers, var_image, loaded_images : table<uint; uint>
    var out : array<uint>
    for (i in 0 .. 5) {push(out, words[i])}
    var constants_ready = false; var invalid = false
    var moved_types : table<uint; bool>
    foreach_inst(words) $(op, w, s, n) {
        if ((op == uint(SpvOp.TypeImage) || op == uint(SpvOp.TypePointer)) && n > 0 && (moved_types?[w[s]] ?? false)) {return }
        if (op == uint(SpvOp.Decorate) && n == 2 && w[s + 1] == uint(SpvDecoration.NonWritable) && key_exists(readonly_vars, w[s])) {return }
        if (op == uint(SpvOp.Variable) && n >= 3 && key_exists(readonly_vars, w[s + 1])) {
            let old = readonly_vars[w[s + 1]]; let at = image_at[old]
            if (w[at + 6] != 2u || w[at + 5] != 0u) {invalid = true; return }
            var img = converted_images?[old] ?? 0u
            if (img == 0u) {
                for (candidate in keys(image_at)) {
                    let ca = (image_at?[candidate] ?? 0)
                    var same = w[ca + 6] == 1u && w[ca + 7] == 0u
                    for (k in 1 .. 6) {same = same && w[ca + k] == w[at + k]}
                    if (same) {
                        img = candidate
                        if (ca >= s) {for (k in ca - 1 .. ca + 8) {push(out, w[k])}; moved_types[candidate] = true}
                        break
                    }
                }
                if (img == 0u) {
                    img = next_id; next_id++
                    push(out, 9u * 65536u + uint(SpvOp.TypeImage)); push(out, img)
                    for (k in 1 .. 6) {push(out, w[at + k])}
                    push(out, 1u); push(out, 0u)
                }
                converted_images[old] = img
            }
            var ptr = converted_pointers?[img] ?? 0u
            if (ptr == 0u) {
                for (candidate in keys(pointers)) {if ((pointers?[candidate] ?? 0u) == img && (pointer_storage?[candidate] ?? 0xffffffffu) == 0u) {
                    ptr = candidate
                    let pa = pointer_at?[candidate] ?? 0
                    if (pa >= s) {for (k in pa - 1 .. pa + 3) {push(out, w[k])}; moved_types[candidate] = true}
                    break
                }}
                if (ptr == 0u) {ptr = next_id; next_id++; push(out, 4u * 65536u + uint(SpvOp.TypePointer)); push(out, ptr); push(out, 0u); push(out, img)}
                converted_pointers[img] = ptr
            }
            var_image[w[s + 1]] = img
            push(out, uint(n + 1) * 65536u + op); push(out, ptr)
            for (k in 1 .. n) {push(out, w[s + k])}
            return
        }
        if (op == uint(SpvOp.Function) && !constants_ready) {
            if (uint_type == 0u) {uint_type = next_id; next_id++; push(out, 4u * 65536u + uint(SpvOp.TypeInt)); push(out, uint_type); push(out, 32u); push(out, 0u)}
            if (zero == 0u) {zero = next_id; next_id++; push(out, 4u * 65536u + uint(SpvOp.Constant)); push(out, uint_type); push(out, zero); push(out, 0u)}
            constants_ready = true
        }
        if (op == uint(SpvOp.Load) && n >= 3 && key_exists(var_image, w[s + 2])) {
            let img = var_image[w[s + 2]]; loaded_images[w[s + 1]] = img
            push(out, uint(n + 1) * 65536u + op); push(out, img)
            for (k in 1 .. n) {push(out, w[s + k])}
            return
        }
        if ((op == uint(SpvOp.ImageRead) || op == uint(SpvOp.ImageQuerySize)) && n >= 3 && key_exists(loaded_images, w[s + 2])) {
            if (op == uint(SpvOp.ImageRead)) {
                if (n != 4) {invalid = true; return }
                push(out, 7u * 65536u + uint(SpvOp.ImageFetch))
                for (k in 0 .. 4) {push(out, w[s + k])}
                push(out, uint(SpvImageOperands.Lod)); push(out, zero)
            } else {
                if (n != 3) {invalid = true; return }
                push(out, 5u * 65536u + uint(SpvOp.ImageQuerySizeLod))
                for (k in 0 .. 3) {push(out, w[s + k])}; push(out, zero)
            }
            return
        }
        for (k in s - 1 .. s + n) {push(out, w[k])}
    }
    if (invalid || !constants_ready) {return err(failure, type<array<uint>>)}
    out[3] = next_id
    return <- move_ok(out, type<SdlError>)
}
