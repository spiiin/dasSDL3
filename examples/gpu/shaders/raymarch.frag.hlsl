// Port of bgfx fs_raymarching.sc; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause, ../LICENSE-bgfx.txt. SDF formulas from the upstream iq_sdf.sh.
struct Input { float4 position:SV_Position; float3 eye:TEXCOORD0; float3 at:TEXCOORD1; float3 light:TEXCOORD2; float4 color:COLOR0; };
float sceneDist(float3 p) {
    float d=length(max(abs(p)-2.5,0))-0.5;
    d=min(d,length(p+float3(4,0,0))-1); d=min(d,length(p-float3(4,0,0))-1);
    d=min(d,length(p+float3(0,4,0))-1); d=min(d,length(p-float3(0,4,0))-1);
    d=min(d,length(p+float3(0,0,4))-1); return min(d,length(p-float3(0,0,4))-1);
}
float3 normalAt(float3 p) {
    float2 e=float2(0.002,0);
    return normalize(float3(sceneDist(p+e.xyy)-sceneDist(p-e.xyy),sceneDist(p+e.yxy)-sceneDist(p-e.yxy),sceneDist(p+e.yyx)-sceneDist(p-e.yyx)));
}
float occlusion(float3 p,float3 n) {
    float occ=0;
    for(int i=1;i<4;i++) { float s=float(i)*0.2; occ+=(s-sceneDist(p+n*s))/exp2(float(i)); }
    return 1-occ;
}
struct Output { float4 color:SV_Target0; float depth:SV_Depth; };
Output main(Input v) {
    float maxd=length(v.at-v.eye); float3 dir=normalize(v.at-v.eye); float t=0;
    // Same 64 sphere-tracing steps and epsilon as upstream; early out on miss
    // avoids exponentially growing distances without changing visible hits.
    for(int i=0;i<64;i++) { float d=sceneDist(v.eye+dir*t); if(d>0.001) t+=d; if(t>=maxd) break; }
    Output o; o.color=v.color; o.depth=1;
    if(t>0.5 && t<maxd) {
        float3 p=v.eye+dir*t, n=normalAt(p); float ndotl=dot(n,v.light);
        float rdotv=dot(v.light-2*ndotl*n,dir);
        float diff=max(0,ndotl), spec=step(0,ndotl)*max(0,rdotv);
        float fres=max(0.2+0.8*pow(1-ndotl,5),0);
        float value=(0.9*diff+pow(spec,128)*fres)*occlusion(p,n);
        value=pow(max(value,0),1.0/2.2); o.color=float4(value,value,value,1); o.depth=t/maxd;
    }
    return o;
}
