Texture2D<float4> atlas : register(t0, space2);
SamplerState sampler0 : register(s0, space2);
float4 main(float2 uv : TEXCOORD0) : SV_Target {
    return float4(0.25,0.8,1.0,atlas.Sample(sampler0,uv).a);
}
