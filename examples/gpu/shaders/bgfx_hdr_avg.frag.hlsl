// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
#include "bgfx_hdr_common.hlsl"
Texture2D<float4> source:register(t0,space2);SamplerState linearSampler:register(s0,space2);
float4 main(In v):SV_Target0{float sum=0;for(int y=0;y<4;y++)for(int x=0;x<4;x++)sum+=source.SampleLevel(linearSampler,v.uv+(float2(x,y)-1.5)*v.sampling.xy,0).r;return float4(sum/16,0,0,1);}
