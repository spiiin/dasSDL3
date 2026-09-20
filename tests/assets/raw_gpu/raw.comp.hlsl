#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
Texture2D<float4> sampled : register(t0, space0);
#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
SamplerState samp : register(s0, space0);
Texture2D<float4> storage_image : register(t1, space0);
StructuredBuffer<float4> storage_data : register(t2, space0);
RWTexture2D<float4> output_image : register(u0, space1);
RWStructuredBuffer<uint> output_data : register(u1, space1);
cbuffer Params : register(b0, space2) { uint4 params; };
[numthreads(4,1,1)]
void main(uint3 id : SV_DispatchThreadID) {
    output_data[id.x] = params.x + id.x + uint(sampled.SampleLevel(samp,float2(0.5,0.5),0).x + storage_image.Load(int3(0,0,0)).x + storage_data[0].x);
    output_image[int2(id.x,0)] = float4(0.25,0.5,0.75,1);
}
