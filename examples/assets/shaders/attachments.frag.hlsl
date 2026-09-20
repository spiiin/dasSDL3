struct Vary { float4 position : SV_Position; float4 color : TEXCOORD0; };
struct Targets { float4 first : SV_Target0; float4 second : SV_Target1; };
Targets main(Vary input) {
    Targets o; o.first=input.color; o.second=float4(1-input.color.rgb,1); return o;
}
