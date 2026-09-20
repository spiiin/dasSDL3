RWStructuredBuffer<uint> output_data : register(u0, space1);
cbuffer Params : register(b0, space2) { uint4 values; };
[numthreads(4,1,1)]
void main(uint3 id : SV_DispatchThreadID) { output_data[id.x] = values.x + 3 * id.x; }
