cbuffer Params : register(b0, space1) { float4 values; };
struct Input { float2 position : TEXCOORD0; float4 color : TEXCOORD1; };
struct Vary { float4 position : SV_Position; float4 color : TEXCOORD0; };
Vary main(Input input) {
    Vary v; v.position=float4(input.position,values.x,1); v.color=input.color; return v;
}
