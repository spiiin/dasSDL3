// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
cbuffer Frame : register(b0,space1) { float4 frame; };
struct In { float3 pos:TEXCOORD0;float3 normal:TEXCOORD1;float4 tangent:TEXCOORD2;float2 uv:TEXCOORD3;float4 m0:TEXCOORD4;float4 m1:TEXCOORD5;float4 m2:TEXCOORD6;float4 m3:TEXCOORD7; };
struct Out { float4 pos:SV_Position;float3 world:TEXCOORD0;float3 normal:TEXCOORD1;float3 tangent:TEXCOORD2;float3 bitangent:TEXCOORD3;float2 uv:TEXCOORD4;nointerpolation float4 frame:TEXCOORD5; };
Out main(In v) { Out o;float3 p=(v.m0*v.pos.x+v.m1*v.pos.y+v.m2*v.pos.z+v.m3).xyz;o.world=p;p.z+=frame.z;
 o.pos=float4(p.x*1.7320508/frame.y,p.y*1.7320508,p.z*100/99.9-10/99.9,p.z);
 o.normal=v.m0.xyz*v.normal.x+v.m1.xyz*v.normal.y+v.m2.xyz*v.normal.z;
 o.tangent=v.m0.xyz*v.tangent.x+v.m1.xyz*v.tangent.y+v.m2.xyz*v.tangent.z;
 o.bitangent=cross(o.normal,o.tangent)*v.tangent.w;o.uv=v.uv;o.frame=frame;return o; }
