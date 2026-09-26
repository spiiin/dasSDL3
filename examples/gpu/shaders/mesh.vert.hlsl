// Port of bgfx 04-mesh; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause, ../LICENSE-bgfx.txt. Normals are signed float3, not packed UNORM.
cbuffer Scene : register(b0,space1) { float4 frame; }; // time, aspect, near, far
struct Input { float3 position:TEXCOORD0; float3 normal:TEXCOORD1; };
struct Output { float4 position:SV_Position; float3 pos:TEXCOORD0; float3 view:TEXCOORD1; float3 normal:TEXCOORD2; float4 color:COLOR0; nointerpolation float time:TEXCOORD3; };
float3 rotate(float3 p) { float s=sin(frame.x*0.37),c=cos(frame.x*0.37);return float3(c*p.x-s*p.z,p.y,s*p.x+c*p.z); }
Output main(Input v) {
 float sx=sin(v.position.x*32+frame.x*4)*0.5+0.5,cy=cos(v.position.y*32+frame.x*4)*0.5+0.5;
 float3 displacement=float3(sx,cy,sx*cy);
 float3 p=rotate(v.position+v.normal*displacement*0.06)+float3(0,-1,2.5);
 float f=1.73205080757,q=frame.w/(frame.w-frame.z);
 Output o;o.position=float4(p.x*f/frame.y,p.y*f,p.z*q-frame.z*q,p.z);
 o.pos=o.position.xyz;o.view=p;o.normal=rotate(v.normal);
 float brightness=length(displacement)*0.4+0.6;o.color=float4(brightness.xxx,1);o.time=frame.x;return o;
}
