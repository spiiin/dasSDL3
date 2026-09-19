cbuffer Transform : register(b0, space1) {
    float4 column0, column1, column2, column3;
};
struct Input { float4 position : TEXCOORD0; float4 normal : TEXCOORD1; float2 uv : TEXCOORD2;
    float4 model0 : TEXCOORD3; float4 model1 : TEXCOORD4; float4 model2 : TEXCOORD5; float4 model3 : TEXCOORD6;
    float4 normal0 : TEXCOORD7; float4 normal1 : TEXCOORD8; float4 normal2 : TEXCOORD9; float4 color : TEXCOORD10; };
struct Output { float4 position : SV_Position; float3 normal : TEXCOORD0; float2 uv : TEXCOORD1; nointerpolation float4 color : TEXCOORD2; };
Output main(Input input) {
    Output output;
    float4 world = input.model0*input.position.x + input.model1*input.position.y + input.model2*input.position.z + input.model3*input.position.w;
    output.position = column0*world.x + column1*world.y + column2*world.z + column3*world.w;
    output.normal = input.normal0.xyz*input.normal.x + input.normal1.xyz*input.normal.y + input.normal2.xyz*input.normal.z;
    output.color = input.color;
    output.uv = input.uv;
    return output;
}
