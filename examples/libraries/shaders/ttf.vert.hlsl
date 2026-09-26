cbuffer View : register(b0, space1) { float4 view; }; // width, height, origin x/y
struct Input { float2 xy : TEXCOORD0; float2 uv : TEXCOORD1; };
struct Output { float2 uv : TEXCOORD0; float4 position : SV_Position; };
Output main(Input input) {
    Output output;
    // SDL_ttf GPU xy already has negative-down Y. Convert top-left pixels to NDC.
    output.position = float4(2.0*(input.xy.x+view.z)/view.x-1.0,
                            1.0+2.0*(input.xy.y-view.w)/view.y,0.0,1.0);
    output.uv = input.uv;
    return output;
}
