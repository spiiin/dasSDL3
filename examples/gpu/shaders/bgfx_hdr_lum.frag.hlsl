// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
#include "bgfx_hdr_common.hlsl"
Texture2D<float4> source:register(t0,space2);SamplerState linearSampler:register(s0,space2);
float4 main(In v):SV_Target0{float sum=0;for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++)sum+=dot(source.SampleLevel(linearSampler,v.uv+float2(x,y)*v.sampling.xy,0).rgb,float3(.2126,.7152,.0722));return float4(sum/9,0,0,1);}
