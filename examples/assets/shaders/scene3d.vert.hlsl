cbuffer Camera : register(b0, space1) { float4 column0; float4 column1; float4 column2; float4 column3; };
struct Input { float4 position : TEXCOORD0; float4 color : TEXCOORD1; };
struct Output { float4 position : SV_Position; float4 color : TEXCOORD0; };
Output main(Input input) {
    Output output;
    output.position = column0 * input.position.x + column1 * input.position.y
        + column2 * input.position.z + column3 * input.position.w;
    output.color = input.color;
    return output;
}
