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
cbuffer Params : register(b0, space1) { float4 factor; };
struct Vary { float4 position : SV_Position; float4 color : TEXCOORD0; };
Vary main(float2 position : TEXCOORD0) { Vary o; o.position=float4(position,0,1); o.color=sampled.SampleLevel(samp,float2(0.5,0.5),0)*storage_image.Load(int3(0,0,0))*storage_data[0]*factor; return o; }
