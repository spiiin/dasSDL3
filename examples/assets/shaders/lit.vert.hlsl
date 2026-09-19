cbuffer Transform : register(b0, space1) {
    float4 column0, column1, column2, column3;
    float4 normal0, normal1, normal2;
};
struct Input { float4 position : TEXCOORD0; float4 normal : TEXCOORD1; float2 uv : TEXCOORD2; };
struct Output { float4 position : SV_Position; float3 normal : TEXCOORD0; float2 uv : TEXCOORD1; };
Output main(Input input) {
    Output output;
    output.position = column0*input.position.x + column1*input.position.y + column2*input.position.z + column3*input.position.w;
    output.normal = normal0.xyz*input.normal.x + normal1.xyz*input.normal.y + normal2.xyz*input.normal.z;
    output.uv = input.uv;
    return output;
}
