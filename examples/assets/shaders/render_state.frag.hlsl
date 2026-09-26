// Original dasSDL3 test/example shader. Uniform layout: one float4 (16 bytes).
cbuffer Parameters : register(b0, space3) { float4 tint; };
float4 main() : SV_Target0 { return tint; }
