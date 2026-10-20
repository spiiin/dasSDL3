options gen2
module animation_data shared public
// Preserved glTF channels and hierarchy; evaluated on CPU, deformation on GPU.
require forge_support public
require strings
require daslib/json_boost
require daslib/defer
struct AnimMatrix {columns : float4[4]}
struct AnimNode {parent : int=-1;translation : float3;rotation : float4=float4(0,0,0,1);scale : float3=float3(1);use_matrix : bool;matrix : float4[4];weights : array<float>}
struct AnimChannel {node,path,interpolation,components : int;times,values : array<float>}
struct AnimClip {duration : float;channels : array<AnimChannel>}
struct AnimSkin {joints : array<int>;inverse_bind : array<AnimMatrix>}
struct MorphData {file : string;count,vertices : int}
struct AnimationData {nodes : array<AnimNode>;order : array<int>;clips : array<AnimClip>;skins : array<AnimSkin>;part_nodes,part_skins : array<int>;part_weights : array<string>;part_morphs : array<MorphData>}
struct AnimationPose {world : array<float4x4>;translation,scale : array<float3>;rotation : array<float4>;weights : array<array<float>>}
def read_animation(name : string) {
 let bytes <- load_file(asset("extended_{name}.animation.json")) |> sdl_try
 var error : string;var j=read_json(string(bytes),error)
 if(j==null){return err(SdlError(operation="Animation JSON",message=error),type<AnimationData>)}
 {defer(){unsafe{delete j}}
  var data <- from_JV(j,type<AnimationData>)
  if(length(data.nodes)==0 || length(data.order)!=length(data.nodes)){return err(SdlError(operation=name,message="Invalid animation hierarchy"),type<AnimationData>)}
  var seen : array<bool>;resize(seen,length(data.nodes))
  for(index in data.order){if(index<0 || index>=length(data.nodes) || seen[index]){return err(SdlError(operation=name,message="Invalid topological order"),type<AnimationData>)};let parent=data.nodes[index].parent;if(parent>=0 && (parent>=length(seen) || !seen[parent])){return err(SdlError(operation=name,message="Invalid parent order"),type<AnimationData>)};seen[index]=true}
  for(clip in data.clips){for(channel in clip.channels){
   if(channel.node<0 || channel.node>=length(data.nodes) || channel.components<=0 || length(channel.times)==0 || length(channel.values)!=length(channel.times)*channel.components*(channel.interpolation==2 ? 3 : 1)){return err(SdlError(operation=name,message="Invalid animation channel"),type<AnimationData>)}
   for(i in 1..length(channel.times)){if(channel.times[i]<channel.times[i-1]){return err(SdlError(operation=name,message="Unsorted keyframes"),type<AnimationData>)}}
  }}
  for(skin in data.skins){if(length(skin.joints)!=length(skin.inverse_bind) || length(skin.joints)>128){return err(SdlError(operation=name,message="Invalid skin size"),type<AnimationData>)};for(index in skin.joints){if(index<0 || index>=length(data.nodes)){return err(SdlError(operation=name,message="Invalid joint node"),type<AnimationData>)}}}
  return <- move_ok(data,type<SdlError>)
 }
}
def trs_matrix(t : float3;q : float4;s : float3) : float4x4 {
 let x=q.x;let y=q.y;let z=q.z;let w=q.w;var m : float4x4
 m[0]=float4((1.0-2.0*(y*y+z*z))*s.x,2.0*(x*y+z*w)*s.x,2.0*(x*z-y*w)*s.x,0.0)
 m[1]=float4(2.0*(x*y-z*w)*s.y,(1.0-2.0*(x*x+z*z))*s.y,2.0*(y*z+x*w)*s.y,0.0)
 m[2]=float4(2.0*(x*z+y*w)*s.z,2.0*(y*z-x*w)*s.z,(1.0-2.0*(x*x+y*y))*s.z,0.0);m[3]=float4(t,1.0);return m
}
def animation_slerp(a,b : float4;t : float) : float4 {
 var end=b;var cosine=dot(a,b);if(cosine<0.0){end=-b;cosine=-cosine}
 if(cosine>0.9995){return normalize(a*(1.0-t)+end*t)}
 let angle=acos(clamp(cosine,-1.0,1.0));return (a*sin((1.0-t)*angle)+end*sin(t*angle))/sin(angle)
}
def key_interval(times : array<float>;time : float) : int {
 var lo=0;var hi=length(times)-1
 while(lo+1<hi){let mid=(lo+hi)/2;if(times[mid]<=time){lo=mid}else{hi=mid}};return lo
}
def channel_component(channel : AnimChannel;key,component : int;time,t : float) : float {
 let count=length(channel.times);let next=min(key+1,count-1);let n=channel.components
 if(channel.interpolation==2){let duration=channel.times[next]-channel.times[key];let a=channel.values[(key*3+1)*n+component];let b=channel.values[(next*3+1)*n+component];let out_tangent=channel.values[(key*3+2)*n+component]*duration;let in_tangent=channel.values[(next*3)*n+component]*duration
  return (2.0*t*t*t-3.0*t*t+1.0)*a+(t*t*t-2.0*t*t+t)*out_tangent+(-2.0*t*t*t+3.0*t*t)*b+(t*t*t-t*t)*in_tangent
 }
 let a=channel.values[key*n+component];let b=channel.values[next*n+component];return channel.interpolation==1 ? a : a*(1.0-t)+b*t
}
def evaluate_animation(data : AnimationData;var pose : AnimationPose;time : float;clip_index : int=0) {
 let n=length(data.nodes);resize(pose.world,n);resize(pose.translation,n);resize(pose.rotation,n);resize(pose.scale,n);resize(pose.weights,n)
 for(i in 0..n){pose.translation[i]=data.nodes[i].translation;pose.rotation[i]=data.nodes[i].rotation;pose.scale[i]=data.nodes[i].scale;pose.weights[i] <- clone(data.nodes[i].weights)}
 if(clip_index>=0 && clip_index<length(data.clips)){
  let clip & = unsafe(data.clips[clip_index]);let local=clip.duration>0.0 ? time%clip.duration : 0.0
  for(channel in clip.channels){let key=key_interval(channel.times,local);let next=min(key+1,length(channel.times)-1);let duration=channel.times[next]-channel.times[key];let t=duration>0.0 ? clamp((local-channel.times[key])/duration,0.0,1.0) : 0.0
   let node=channel.node
   if(channel.path==3){resize(pose.weights[node],channel.components);for(c in 0..channel.components){pose.weights[node][c]=channel_component(channel,key,c,local,t)}}
   else{
    var value : float4;for(c in 0..min(channel.components,4)){value[c]=channel_component(channel,key,c,local,t)}
    if(channel.path==0){pose.translation[node]=value.xyz}
    elif(channel.path==2){pose.scale[node]=value.xyz}
    elif(channel.interpolation==0){let a=float4(channel.values[key*4],channel.values[key*4+1],channel.values[key*4+2],channel.values[key*4+3]);let b=float4(channel.values[next*4],channel.values[next*4+1],channel.values[next*4+2],channel.values[next*4+3]);pose.rotation[node]=animation_slerp(a,b,t)}
    else{pose.rotation[node]=normalize(value)}
   }
  }
 }
 for(i in data.order){var local=trs_matrix(pose.translation[i],pose.rotation[i],pose.scale[i]);if(data.nodes[i].use_matrix){for(c in 0..4){local[c]=data.nodes[i].matrix[c]}};let parent=data.nodes[i].parent;pose.world[i]=parent>=0 ? pose.world[parent]*local : local}
}
def joint_matrix(data : AnimationData;pose : AnimationPose;skin,index : int) : float4x4 {
 var inverse_bind : float4x4;for(c in 0..4){inverse_bind[c]=data.skins[skin].inverse_bind[index].columns[c]};return pose.world[data.skins[skin].joints[index]]*inverse_bind
}
