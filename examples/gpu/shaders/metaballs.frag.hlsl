// Adapted from bgfx 02-metaballs; BSD-2-Clause, ../LICENSE-bgfx.txt.
struct Input { float4 position:SV_Position; float3 normal:TEXCOORD0; float3 color:TEXCOORD1; };
float4 main(Input v):SV_Target0 {
    float ndotl=saturate(dot(normalize(v.normal),float3(0,0,-1)));
    float spec=pow(ndotl,30.0);
    return float4(pow(pow(saturate(v.color),2.2)*ndotl+spec,1.0/2.2),1);
}
