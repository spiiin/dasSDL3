#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
Texture2D<float4> image : register(t0, space2);
#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
SamplerState image_sampler : register(s0, space2);
struct Input { float4 position : SV_Position; float2 uv : TEXCOORD0; };
float4 main(Input input) : SV_Target0 {
    return image.Sample(image_sampler, input.uv);
}
