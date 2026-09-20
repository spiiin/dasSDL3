float4 main(float4 position : SV_Position, float3 color : TEXCOORD0) : SV_Target0 {
    return float4(color, 1.0);
}
