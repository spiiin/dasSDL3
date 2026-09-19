#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
Texture2D<float4> image : register(t0, space2);
#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
SamplerState image_sampler : register(s0, space2);
cbuffer Lighting : register(b0, space3) { float4 light; };
struct Input { float4 position : SV_Position; float3 normal : TEXCOORD0; float2 uv : TEXCOORD1; nointerpolation float4 color : TEXCOORD2; };
float4 main(Input input) : SV_Target0 {
    // A zero interpolated normal has only ambient illumination.
    float3 normal = input.normal * rsqrt(max(dot(input.normal,input.normal),1e-30));
    float illumination = light.w + (1-light.w)*saturate(dot(normal,light.xyz));
    float4 texel = image.Sample(image_sampler,input.uv);
    return float4(texel.rgb*input.color.rgb*illumination,texel.a*input.color.a);
}
