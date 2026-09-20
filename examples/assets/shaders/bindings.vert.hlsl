cbuffer Transform : register(b0, space1) { float4 rowX; float4 rowY; };
#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
Texture2D<float4> vertex_image : register(t0, space0);
#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
SamplerState vertex_sampler : register(s0, space0);
struct Input { float2 position : TEXCOORD0; float2 uv : TEXCOORD1; };
struct Output { float4 position : SV_Position; float2 uv : TEXCOORD0; float4 color : TEXCOORD1; };
Output main(Input input) {
    Output output;
    float4 p = float4(input.position,0,1);
    output.position = float4(dot(rowX,p),dot(rowY,p),0,1);
    output.uv = input.uv;
    output.color = vertex_image.SampleLevel(vertex_sampler,float2(0.25,0.25),0);
    return output;
}
