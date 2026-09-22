// Adapted from bgfx 02-metaballs; BSD-2-Clause, ../LICENSE-bgfx.txt.
cbuffer Transform : register(b0, space1) { float4 rotation; float4 projection; };
struct Input { float3 position:TEXCOORD0; float3 normal:TEXCOORD1; float3 color:TEXCOORD2; };
struct Output { float4 position:SV_Position; float3 normal:TEXCOORD0; float3 color:TEXCOORD1; };
float3 rotate(float3 v) {
    float3 x = float3(v.x, v.y*rotation.y-v.z*rotation.x, v.y*rotation.x+v.z*rotation.y);
    return float3(x.x*rotation.w+x.z*rotation.z, x.y, -x.x*rotation.z+x.z*rotation.w);
}
Output main(Input v) {
    Output o;
    float3 p=rotate(v.position); p.z+=50.0;
    // Left-handed perspective, zero-to-one depth; SDL handles Vulkan viewport Y.
    o.position=float4(p.x*projection.x,p.y*projection.y,p.z*projection.z+projection.w,p.z);
    o.normal=rotate(v.normal); o.color=v.color;
    return o;
}
