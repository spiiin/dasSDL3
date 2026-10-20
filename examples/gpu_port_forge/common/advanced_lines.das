options gen2
module advanced_lines shared public
// Immediate debug geometry from Forge 19; application-local, fixed capacity.
require math public
require daslib/math_bits
struct DebugLineVertex { position : float3; color : float4 }
def line(var dst : array<DebugLineVertex>; a,b : float3; color : float4) {
    push(dst,DebugLineVertex(position=a,color=color));push(dst,DebugLineVertex(position=b,color=color))
}
def axes(var dst : array<DebugLineVertex>; origin : float3; size : float) {
    line(dst,origin,origin+float3(size,0,0),float4(1,0,0,1))
    line(dst,origin,origin+float3(0,size,0),float4(0,1,0,1))
    line(dst,origin,origin+float3(0,0,size),float4(0,0,1,1))
}
def box_lines(var dst : array<DebugLineVertex>; lo,hi : float3; color : float4) {
    for(i in 0..8){for(axis in 0..3){if((i&(1<<axis))==0){
        let j=i|(1<<axis)
        let a=float3((i&1)!=0 ? hi.x : lo.x,(i&2)!=0 ? hi.y : lo.y,(i&4)!=0 ? hi.z : lo.z)
        let b=float3((j&1)!=0 ? hi.x : lo.x,(j&2)!=0 ? hi.y : lo.y,(j&4)!=0 ? hi.z : lo.z)
        line(dst,a,b,color)
    }}}
}
def circle_lines(var dst : array<DebugLineVertex>; center : float3; radius : float; normal : float3; color : float4) {
    let n=normalize(normal);let ref_=abs(n.y)>0.9 ? float3(1,0,0) : float3(0,1,0)
    let t=normalize(cross(n,ref_));let b=cross(n,t)
    for(i in 0..32){
        let a0=float(i)*6.283185307/32.0;let a1=float((i+1)%32)*6.283185307/32.0
        line(dst,center+(t*cos(a0)+b*sin(a0))*radius,center+(t*cos(a1)+b*sin(a1))*radius,color)
    }
}
def make_debug_lines(var world,overlay : array<DebugLineVertex>; time : float) {
    for(i in -20..21){
        line(world,float3(float(i),0,-20),float3(float(i),0,20),float4(0.3,0.3,0.3,1))
        line(world,float3(-20,0,float(i)),float3(20,0,float(i)),float4(0.3,0.3,0.3,1))
    }
    axes(overlay,float3(0),2.0)
    box_lines(world,float3(-6,0,-3),float3(-4,2,-1),float4(1,0.6,0,1))
    box_lines(world,float3(4,0,-4),float3(7,3,-1),float4(0.2,0.8,1,1))
    box_lines(world,float3(-2,0,-8),float3(2,4,-5),float4(1,0.3,0.5,1))
    box_lines(overlay,float3(-0.5,0,-0.5),float3(0.5,1,0.5),float4(1,1,0,1))
    circle_lines(world,float3(6,0.5,4),1.5,float3(0,1,0),float4(0,1,0.5,1))
    circle_lines(world,float3(-6,2,4),1.5,float3(0,0,1),float4(0.8,0.2,1,1))
    circle_lines(world,float3(0,3,-3),2.0,float3(sin(time),0.5,cos(time)),float4(1,0.8,0.2,1))
    axes(world,float3(-5,1,-2),1.0);axes(world,float3(5.5,1.5,-2.5),1.0)
}
def line_bytes(world,overlay : array<DebugLineVertex>) {
    var bytes : array<uint8>
    for(v in world){
        for(value in fixed_array(v.position.x,v.position.y,v.position.z,v.color.x,v.color.y,v.color.z,v.color.w)){
            let bits=uint(float_bits_to_int(value));for(i in 0..4){push(bytes,uint8(bits>>uint(i*8)))}
        }
    }
    for(v in overlay){
        for(value in fixed_array(v.position.x,v.position.y,v.position.z,v.color.x,v.color.y,v.color.z,v.color.w)){
            let bits=uint(float_bits_to_int(value));for(i in 0..4){push(bytes,uint8(bits>>uint(i*8)))}
        }
    }
    return <- bytes
}
