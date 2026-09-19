cbuffer Transform : register(b0, space1) { float4 rowX; float4 rowY; };
struct Input { float2 position : TEXCOORD0; float2 uv : TEXCOORD1; };
struct Output { float4 position : SV_Position; float2 uv : TEXCOORD0; };
Output main(Input input) {
    Output output;
    float4 p = float4(input.position, 0.0, 1.0);
    output.position = float4(dot(rowX, p), dot(rowY, p), 0.0, 1.0);
    output.uv = input.uv;
    return output;
}
