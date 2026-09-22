#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline const char * process_child_path() {return DASSDL3_PROCESS_CHILD;}
inline const char * process_library_path() {return DASSDL3_PROCESS_LIBRARY;}
inline int process_library_call(void * function) {return reinterpret_cast<int (*)()>(function)();}
}
