#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
Texture2D<float4> sampled : register(t0, space2);
#ifdef __spirv__
[[vk::combinedImageSampler]]
#endif
SamplerState samp : register(s0, space2);
Texture2D<float4> storage_image : register(t1, space2);
StructuredBuffer<float4> storage_data : register(t2, space2);
cbuffer Params : register(b0, space3) { float4 factor; };
struct Vary { float4 position : SV_Position; float4 color : TEXCOORD0; };
float4 main(Vary i) : SV_Target0 { return i.color*sampled.SampleLevel(samp,float2(0.5,0.5),0)*storage_image.Load(int3(0,0,0))*storage_data[0]*factor; }
