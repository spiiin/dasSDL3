#pragma once
#include <SDL3/SDL.h>
#include <SDL3/SDL_opengl.h>
// Only GL rendering/reading is native. SDL calls under test remain in the script.
inline bool SDLTestGLPixel(void * clear_color,void * clear,void * read_pixels) {
    if(!clear_color || !clear || !read_pixels) return false;
    auto color=reinterpret_cast<void(APIENTRY *)(GLfloat,GLfloat,GLfloat,GLfloat)>(clear_color);
    auto fill=reinterpret_cast<void(APIENTRY *)(GLbitfield)>(clear);
    auto read=reinterpret_cast<void(APIENTRY *)(GLint,GLint,GLsizei,GLsizei,GLenum,GLenum,void *)>(read_pixels);
    color(0.25f,0.5f,0.75f,1.f);fill(GL_COLOR_BUFFER_BIT);
    unsigned char rgba[4]={};read(0,0,1,1,GL_RGBA,GL_UNSIGNED_BYTE,rgba);
    return rgba[0]>=62 && rgba[0]<=65 && rgba[1]>=126 && rgba[1]<=129 && rgba[2]>=189 && rgba[2]<=193;
}
