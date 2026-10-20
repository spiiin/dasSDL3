options gen2
module raw_bytes shared public
require math public
require daslib/math_bits
def packed_floats(values : array<float>) {var bytes : array<uint8>;for(value in values){let bits=uint(float_bits_to_int(value));for(i in 0u..4u){push(bytes,uint8(bits>>(i*8u)))}};return <- bytes}
def packed_uints(values : array<uint>) {var bytes : array<uint8>;for(value in values){for(i in 0u..4u){push(bytes,uint8(value>>(i*8u)))}};return <- bytes}
def read_float(bytes : array<uint8>;index : int) : float {let bits=uint(bytes[index])|(uint(bytes[index+1])<<8)|(uint(bytes[index+2])<<16)|(uint(bytes[index+3])<<24);return int_bits_to_float(int(bits))}
