// Adapted from bgfx examples 05/06/09. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
TextureCube<float4> environment:register(t0,space2);SamplerState envSampler:register(s0,space2);
struct In{float4 pos:SV_Position;float3 clip:TEXCOORD0;float3 view:TEXCOORD1;float3 normal:TEXCOORD2;nointerpolation float time:TEXCOORD3;};
float4 main(In v):SV_Target0{float3 n=normalize(v.normal),view=normalize(v.view),light=float3(0,0,-1);float ndotl=dot(n,light);float spec=step(0,ndotl)*max(0,dot(light-2*ndotl*n,view));float fres=max(.2+.8*pow(max(0,1-ndotl),5),0);
 float index=((sin(v.clip.x*3+v.time)*.3+.7)+(cos(v.clip.y*3+v.time)*.4+.6)+(cos(v.clip.z*3+v.time)*.2+.8))*3.14159265;
 float3 color=(sin(index*float3(8,4,2))*.4+.6)*max(0,environment.SampleLevel(envSampler,reflect(view,-n),0).rgb);
 return float4(color*max(0,ndotl)+fres*pow(spec,128),1);}
