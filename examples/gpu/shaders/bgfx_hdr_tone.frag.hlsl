// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
#include "bgfx_hdr_common.hlsl"
Texture2D<float4> source:register(t0,space2);SamplerState linearSampler:register(s0,space2);
Texture2D<float4> luminance:register(t1,space2);SamplerState lumSampler:register(s1,space2);
Texture2D<float4> bloom:register(t2,space2);SamplerState bloomSampler:register(s2,space2);
float4 main(In v):SV_Target0{float3 rgb=source.SampleLevel(linearSampler,v.uv,0).rgb;float lum=clamp(luminance.SampleLevel(lumSampler,float2(.5,.5),0).r,.1,.7);
float3 xyz=rgb2xyz(rgb);float mapped=reinhard2((xyz.y*v.tone.x/(lum+.0001)).xxx,v.tone.y).x;rgb=xyz2rgb(xyz*(mapped/max(xyz.y,.000001)));
const float weights[5]={1,.9,.55,.18,.1};float3 blur=bloom.SampleLevel(bloomSampler,v.uv,0).rgb;
for(int i=1;i<5;i++)blur+=(bloom.SampleLevel(bloomSampler,v.uv+float2(i*v.sampling.x,0),0).rgb+bloom.SampleLevel(bloomSampler,v.uv-float2(i*v.sampling.x,0),0).rgb)*weights[i];
return float4(pow(max(0,rgb+.6*v.tone.w*blur/4.46),1/2.2),1);}
