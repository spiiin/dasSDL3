struct Output { float4 position : SV_Position; float3 color : TEXCOORD0; };
Output main(float2 position : TEXCOORD0, float3 color : TEXCOORD1) {
    Output result;
    result.position = float4(position, 0.0, 1.0);
    result.color = color;
    return result;
}
