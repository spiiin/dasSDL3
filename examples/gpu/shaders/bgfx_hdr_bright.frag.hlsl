// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
#include "bgfx_hdr_common.hlsl"
Texture2D<float4> source:register(t0,space2);SamplerState linearSampler:register(s0,space2);
Texture2D<float4> luminance:register(t1,space2);SamplerState lumSampler:register(s1,space2);
float4 main(In v):SV_Target0{float3 c=0;for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++)c+=source.SampleLevel(linearSampler,v.uv+float2(x,y)*v.sampling.xy,0).rgb;c/=9;
float lum=clamp(luminance.SampleLevel(lumSampler,float2(.5,.5),0).r,.1,.7);c=max(0,c-v.tone.z)*v.tone.x/(lum+.0001);return float4(pow(reinhard2(c,v.tone.y),1/2.2),1);}
