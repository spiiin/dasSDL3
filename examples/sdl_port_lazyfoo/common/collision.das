options gen2
module collision shared public
require ./dot_motion.das public
def public overlaps(a,b : SDL_FRect) : bool {
    return a.x < b.x+b.w && a.x+a.w > b.x && a.y < b.y+b.h && a.y+a.h > b.y
}
def public move_colliding(var dot : Dot; wall : SDL_FRect; dt : float) {
    let old=dot.position
    dot.position.x=clamp(old.x+dot.velocity.x*dt,0.0,608.0)
    if(overlaps(SDL_FRect(x=dot.position.x,y=dot.position.y,w=32.0,h=32.0),wall)){dot.position.x=old.x}
    dot.position.y=clamp(old.y+dot.velocity.y*dt,0.0,448.0)
    if(overlaps(SDL_FRect(x=dot.position.x,y=dot.position.y,w=32.0,h=32.0),wall)){dot.position.y=old.y}
}
