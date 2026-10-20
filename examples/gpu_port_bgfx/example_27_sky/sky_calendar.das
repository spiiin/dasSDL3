options gen2
module sky_calendar shared public
require math public
def sun_luminance(hour : float) : float3 {
    let keys=fixed_array(float4(0.000000,0.000000,0.000000,5.0),float4(12.703322,12.989393,9.100411,7.0),float4(13.202644,13.597814,11.524929,8.0),float4(13.192974,13.597458,12.264488,9.0),float4(13.132943,13.535914,12.560032,10.0),float4(13.088722,13.489535,12.692996,11.0),float4(13.067827,13.467483,12.745179,12.0),float4(13.069653,13.469413,12.740822,13.0),float4(13.094319,13.495428,12.678066,14.0),float4(13.142133,13.545483,12.526785,15.0),float4(13.201734,13.606017,12.188001,16.0),float4(13.182774,13.572725,11.311157,17.0),float4(12.448635,12.672520,8.267771,18.0),float4(0.000000,0.000000,0.000000,20.0))
    if(hour<=keys[0].w){return keys[0].xyz}
    for(i in 1..length(keys)){if(hour<keys[i].w){let t=(hour-keys[i-1].w)/(keys[i].w-keys[i-1].w);return keys[i-1].xyz*(1.0-t)+keys[i].xyz*t}}
    return keys[length(keys)-1].xyz
}
def sky_luminance(hour : float) : float3 {
    let keys=fixed_array(float4(0.308,0.308,0.411,0.0),float4(0.308,0.308,0.410,1.0),float4(0.301,0.301,0.402,2.0),float4(0.287,0.287,0.382,3.0),float4(0.258,0.258,0.344,4.0),float4(0.258,0.258,0.344,5.0),float4(0.962851,1.000000,1.747835,7.0),float4(0.967787,1.000000,1.776762,8.0),float4(0.970173,1.000000,1.788413,9.0),float4(0.971431,1.000000,1.794102,10.0),float4(0.972099,1.000000,1.797096,11.0),float4(0.972385,1.000000,1.798389,12.0),float4(0.972361,1.000000,1.798278,13.0),float4(0.972020,1.000000,1.796740,14.0),float4(0.971275,1.000000,1.793407,15.0),float4(0.969885,1.000000,1.787078,16.0),float4(0.967216,1.000000,1.773758,17.0),float4(0.961668,1.000000,1.739891,18.0),float4(0.264,0.264,0.352,20.0),float4(0.264,0.264,0.352,21.0),float4(0.290,0.290,0.386,22.0),float4(0.303,0.303,0.404,23.0))
    if(hour<=keys[0].w){return keys[0].xyz}
    for(i in 1..length(keys)){if(hour<keys[i].w){let t=(hour-keys[i-1].w)/(keys[i].w-keys[i-1].w);return keys[i-1].xyz*(1.0-t)+keys[i].xyz*t}}
    return keys[length(keys)-1].xyz
}
def sun_direction(hour,latitude : float; month : int) : float3 {
    let rad=0.01745329252
    let longitude=(280.46+0.9856474*(30.0*float(month)+15.0))*rad
    let delta=asin(sin(23.4*rad)*sin(longitude));let lat=latitude*rad;let h=(hour-12.0)*3.14159265/12.0
    let az=atan2(sin(h),cos(h)*sin(lat)-tan(delta)*cos(lat))
    let alt=asin(sin(lat)*sin(delta)+cos(lat)*cos(delta)*cos(h))
    return float3(cos(alt)*cos(az),-sin(alt),cos(alt)*sin(az))
}
