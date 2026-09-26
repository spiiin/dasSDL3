// Port of bgfx 04-mesh; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause, ../LICENSE-bgfx.txt.
struct Input { float4 position:SV_Position; float3 pos:TEXCOORD0; float3 view:TEXCOORD1; float3 normal:TEXCOORD2; float4 color:COLOR0; nointerpolation float time:TEXCOORD3; };
float4 main(Input v):SV_Target0 {
 float3 light=float3(0,0,-1),normal=normalize(v.normal),view=normalize(v.view);
 float ndotl=dot(normal,light),rdotv=dot(light-2*ndotl*normal,view);
 float diff=max(0,ndotl),spec=step(0,ndotl)*max(0,rdotv);
 float fres=max(0.2+0.8*pow(1-ndotl,5),0);
 float index=((sin(v.pos.x*3+v.time)*0.3+0.7)+(cos(v.pos.y*3+v.time)*0.4+0.6)+(cos(v.pos.z*3+v.time)*0.2+0.8))*3.14159265359;
 float3 color=(sin(index*float3(8,4,2))*0.4+0.6)*v.color.xyz;
 return float4(pow(float3(0.07,0.06,0.08)+color*diff+fres*pow(spec,128),1.0/2.2),1);
}
