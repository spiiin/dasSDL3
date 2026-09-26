// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
cbuffer Frame:register(b0,space1) {float4 frame;float4 tone;float4 sampling;};
struct Out {float4 pos:SV_Position;float2 uv:TEXCOORD0;nointerpolation float4 frame:TEXCOORD1;nointerpolation float4 tone:TEXCOORD2;nointerpolation float4 sampling:TEXCOORD3;};
Out main(uint id:SV_VertexID){Out o;float2 uv=float2((id<<1)&2,id&2);o.pos=float4(uv.x*2-1,1-uv.y*2,0,1);o.uv=uv;o.frame=frame;o.tone=tone;o.sampling=sampling;return o;}
