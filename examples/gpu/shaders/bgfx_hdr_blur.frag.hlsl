// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
#include "bgfx_hdr_common.hlsl"
Texture2D<float4> source:register(t0,space2);SamplerState linearSampler:register(s0,space2);
float3 blur9(float2 uv,float2 delta){const float weights[5]={1,.9,.55,.18,.1};float3 c=source.SampleLevel(linearSampler,uv,0).rgb;for(int i=1;i<5;i++)c+=(source.SampleLevel(linearSampler,uv+i*delta,0).rgb+source.SampleLevel(linearSampler,uv-i*delta,0).rgb)*weights[i];return c/4.46;}
float4 main(In v):SV_Target0{return float4(blur9(v.uv,float2(0,v.sampling.y)),1);}
