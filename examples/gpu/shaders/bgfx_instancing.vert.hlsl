// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
cbuffer Frame : register(b0,space1) { float4 frame; };
struct In { float3 pos:TEXCOORD0;float4 color:TEXCOORD1;float4 m0:TEXCOORD2;float4 m1:TEXCOORD3;float4 m2:TEXCOORD4;float4 m3:TEXCOORD5;float4 tint:TEXCOORD6; };
struct Out { float4 pos:SV_Position;float4 color:COLOR0; };
Out main(In v) { float3 p=(v.m0*v.pos.x+v.m1*v.pos.y+v.m2*v.pos.z+v.m3).xyz;p.z+=frame.z;
 Out o;o.pos=float4(p.x*1.7320508/frame.y,p.y*1.7320508,p.z*100/99.9-10/99.9,p.z);o.color=v.color*v.tint;return o; }
