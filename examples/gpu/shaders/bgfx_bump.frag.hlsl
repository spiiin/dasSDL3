// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
Texture2D<float4> colorTex:register(t0,space2);SamplerState colorSampler:register(s0,space2);
Texture2D<float4> normalTex:register(t1,space2);SamplerState normalSampler:register(s1,space2);
struct In { float4 pos:SV_Position;float3 world:TEXCOORD0;float3 normal:TEXCOORD1;float3 tangent:TEXCOORD2;float3 bitangent:TEXCOORD3;float2 uv:TEXCOORD4;nointerpolation float4 frame:TEXCOORD5; };
float4 main(In v):SV_Target0 {
 float2 xy=(normalTex.Sample(normalSampler,v.uv).xy*2-1)*v.frame.w;
 float3 normal=float3(xy,sqrt(saturate(1-dot(xy,xy))));float3 lighting=0;
 const float3 colors[4]={float3(1,.7,.2),float3(.7,.2,1),float3(.2,1,.7),float3(1,.4,.2)};
 for(int i=0;i<4;i++) {float3 lp=float3(sin(v.frame.x*(.1+i*.17)+i*1.5707963*1.37)*3,cos(v.frame.x*(.2+i*.29)+i*1.5707963*1.49)*3,-2.5)-v.world;
 float attenuation=1-smoothstep(.8,1,length(lp)/3);float3 l=normalize(lp);
 float3 local=float3(dot(l,v.tangent),dot(l,v.bitangent),dot(l,v.normal));lighting+=colors[i]*saturate(dot(local,normal))*attenuation;}
 float3 albedo=pow(colorTex.Sample(colorSampler,v.uv).rgb,2.2);
 return float4(pow(max(.05,lighting)*albedo,1/2.2),1); }
