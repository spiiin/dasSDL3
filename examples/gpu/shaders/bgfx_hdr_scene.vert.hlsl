// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
cbuffer Frame:register(b0,space1){float4 frame;float4 tone;float4 sampling;};
struct In{float3 pos:TEXCOORD0;float3 normal:TEXCOORD1;};
struct Out{float4 pos:SV_Position;float3 clip:TEXCOORD0;float3 view:TEXCOORD1;float3 normal:TEXCOORD2;nointerpolation float time:TEXCOORD3;};
float3 rotateY(float3 p,float t){float s=sin(t),c=cos(t);return float3(c*p.x-s*p.z,p.y,s*p.x+c*p.z);}
Out main(In v){Out o;float3 p=rotateY(v.pos-float3(0,1,0),-frame.x)+float3(0,0,2.5);o.pos=float4(p.x*1.7320508/frame.y,p.y*1.7320508,p.z*100/99.9-10/99.9,p.z);o.clip=o.pos.xyz;o.view=p;o.normal=rotateY(v.normal,-frame.x);o.time=frame.x;return o;}
