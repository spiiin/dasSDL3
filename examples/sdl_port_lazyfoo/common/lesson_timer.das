options gen2
module lesson_timer shared public
struct LessonTimer { started, paused : bool; start, held : uint64 }
def public timer_start(var timer : LessonTimer; now : uint64) {timer=LessonTimer(started=true,start=now)}
def public timer_ticks(timer : LessonTimer; now : uint64) : uint64 {return !timer.started ? 0ul : (timer.paused ? timer.held : now-timer.start)}
def public timer_pause(var timer : LessonTimer; now : uint64) {if(timer.started && !timer.paused){timer.held=now-timer.start;timer.paused=true}}
def public timer_resume(var timer : LessonTimer; now : uint64) {if(timer.started && timer.paused){timer.start=now-timer.held;timer.paused=false}}
