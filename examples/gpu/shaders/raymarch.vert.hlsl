// Port of bgfx 03-raymarch; BSD-2-Clause, ../LICENSE-bgfx.txt.
cbuffer Scene : register(b0, space1) { float4 frame; }; // time, aspect, near, far
struct Output { float4 position:SV_Position; float3 eye:TEXCOORD0; float3 at:TEXCOORD1; float3 light:TEXCOORD2; float4 color:COLOR0; };
// Inverse of bx::mtxRotateXY(time, time*0.37), applied to a column vector.
float3 inverseRotation(float3 p) {
    float sx=sin(frame.x), cx=cos(frame.x), sy=sin(frame.x*0.37), cy=cos(frame.x*0.37);
    return float3(cy*p.x+sy*p.z, sx*sy*p.x+cx*p.y-sx*cy*p.z, -cx*sy*p.x+sx*p.y+cx*cy*p.z);
}
Output main(uint id:SV_VertexID) {
    const float2 corners[6]={float2(-1,-1),float2(1,1),float2(1,-1),float2(-1,-1),float2(-1,1),float2(1,1)};
    const float4 colors[6]={float4(1,0,0,1),float4(0,0,1,1),float4(0,1,0,1),float4(1,0,0,1),float4(1,1,1,1),float4(0,0,1,1)};
    float2 uv=corners[id]; Output o;
    o.position=float4(uv.x,-uv.y,0,1); // screen-space quad, bgfx top-left is red
    float2 slope=float2(uv.x*frame.y,-uv.y)*0.57735026919;
    o.eye=inverseRotation(float3(slope*frame.z,-15+frame.z));
    o.at=inverseRotation(float3(slope*frame.w,-15+frame.w));
    o.light=inverseRotation(normalize(float3(-0.4,-0.5,-1)));
    o.color=colors[id]; return o;
}
