// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
struct In {float4 pos:SV_Position;float2 uv:TEXCOORD0;nointerpolation float4 frame:TEXCOORD1;nointerpolation float4 tone:TEXCOORD2;nointerpolation float4 sampling:TEXCOORD3;};
float3 rotateY(float3 p,float t){float s=sin(t),c=cos(t);return float3(c*p.x-s*p.z,p.y,s*p.x+c*p.z);}
float3 reinhard2(float3 x,float whiteSqr){return x*(1+x/whiteSqr)/(1+x);}
float3 rgb2xyz(float3 c){return float3(dot(c,float3(.4124,.3576,.1805)),dot(c,float3(.2126,.7152,.0722)),dot(c,float3(.0193,.1192,.9505)));}
float3 xyz2rgb(float3 c){return float3(dot(c,float3(3.2406,-1.5372,-.4986)),dot(c,float3(-.9689,1.8758,.0415)),dot(c,float3(.0557,-.204,1.057)));}
