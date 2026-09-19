// Vertex-ID triangle: no vertex buffers, uniforms or resource bindings.
struct Output { float4 position : SV_Position; float3 color : TEXCOORD0; };
Output main(uint id : SV_VertexID) {
    const float2 positions[3] = {float2(-0.75, -0.75), float2(0.0, 0.75), float2(0.75, -0.75)};
    const float3 colors[3] = {float3(1,0,0), float3(0,1,0), float3(0,0,1)};
    Output result;
    result.position = float4(positions[id], 0.0, 1.0);
    result.color = colors[id];
    return result;
}
