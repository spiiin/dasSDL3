// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
#include "bgfx_hdr_common.hlsl"
TextureCube<float4> environment:register(t0,space2);SamplerState envSampler:register(s0,space2);
float4 main(In v):SV_Target0{float3 d=rotateY(normalize(float3((v.uv.x*2-1)*v.frame.y,1-v.uv.y*2,1.7320508)),v.frame.x);return float4(max(0,environment.SampleLevel(envSampler,d,0).rgb),1);}
