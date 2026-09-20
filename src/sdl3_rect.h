#pragma once
#include "sdl3_pixels.h"
inline bool SDL_HasRectIntersectionRefs(const SDL_Rect & a,const SDL_Rect & b) {return SDL_HasRectIntersection(&a,&b);}
inline bool SDL_RectsEqualRefs(const SDL_Rect & a,const SDL_Rect & b) {return SDL_RectsEqual(&a,&b);}
inline bool SDL_RectEmptyRef(const SDL_Rect & a) {return SDL_RectEmpty(&a);}
inline bool SDL_PointInRectRefs(const SDL_Point & p,const SDL_Rect & r) {return SDL_PointInRect(&p,&r);}
inline bool SDL_GetRectIntersectionRefs(const SDL_Rect & a,const SDL_Rect & b,SDL_Rect & out) {return SDL_GetRectIntersection(&a,&b,&out);}
inline bool SDL_GetRectUnionRefs(const SDL_Rect & a,const SDL_Rect & b,SDL_Rect & out) {return SDL_GetRectUnion(&a,&b,&out);}
inline bool SDL_GetRectAndLineIntersectionRefs(const SDL_Rect & rect,int & x1,int & y1,int & x2,int & y2) {return SDL_GetRectAndLineIntersection(&rect,&x1,&y1,&x2,&y2);}
inline bool SDL_GetRectEnclosingPointsArray(const das::TArray<SDL_Point> & points,const SDL_Rect & clip,SDL_Rect & out) {if(points.size>uint32_t(INT_MAX)/sizeof(SDL_Point))return SDL_SetError("Point array too large");return SDL_GetRectEnclosingPoints(reinterpret_cast<const SDL_Point *>(points.data),int(points.size),&clip,&out);}
inline bool SDL_GetRectEnclosingPointsAll(const das::TArray<SDL_Point> & points,SDL_Rect & out) {if(points.size>uint32_t(INT_MAX)/sizeof(SDL_Point))return SDL_SetError("Point array too large");return SDL_GetRectEnclosingPoints(reinterpret_cast<const SDL_Point *>(points.data),int(points.size),nullptr,&out);}
inline bool SDL_HasRectIntersectionFloatRefs(const SDL_FRect & a,const SDL_FRect & b) {return SDL_HasRectIntersectionFloat(&a,&b);}
inline bool SDL_RectsEqualFloatRefs(const SDL_FRect & a,const SDL_FRect & b) {return SDL_RectsEqualFloat(&a,&b);}
inline bool SDL_RectEmptyFloatRef(const SDL_FRect & a) {return SDL_RectEmptyFloat(&a);}
inline bool SDL_PointInRectFloatRefs(const SDL_FPoint & p,const SDL_FRect & r) {return SDL_PointInRectFloat(&p,&r);}
inline bool SDL_GetRectIntersectionFloatRefs(const SDL_FRect & a,const SDL_FRect & b,SDL_FRect & out) {return SDL_GetRectIntersectionFloat(&a,&b,&out);}
inline bool SDL_GetRectUnionFloatRefs(const SDL_FRect & a,const SDL_FRect & b,SDL_FRect & out) {return SDL_GetRectUnionFloat(&a,&b,&out);}
inline bool SDL_GetRectAndLineIntersectionFloatRefs(const SDL_FRect & rect,float & x1,float & y1,float & x2,float & y2) {return SDL_GetRectAndLineIntersectionFloat(&rect,&x1,&y1,&x2,&y2);}
inline bool SDL_GetRectEnclosingPointsFloatArray(const das::TArray<SDL_FPoint> & points,const SDL_FRect & clip,SDL_FRect & out) {if(points.size>uint32_t(INT_MAX)/sizeof(SDL_FPoint))return SDL_SetError("Point array too large");return SDL_GetRectEnclosingPointsFloat(reinterpret_cast<const SDL_FPoint *>(points.data),int(points.size),&clip,&out);}
inline bool SDL_GetRectEnclosingPointsFloatAll(const das::TArray<SDL_FPoint> & points,SDL_FRect & out) {if(points.size>uint32_t(INT_MAX)/sizeof(SDL_FPoint))return SDL_SetError("Point array too large");return SDL_GetRectEnclosingPointsFloat(reinterpret_cast<const SDL_FPoint *>(points.data),int(points.size),nullptr,&out);}
inline void SDL_RectToFRectRef(const SDL_Rect & src,SDL_FRect & dst) {SDL_RectToFRect(&src,&dst);}
inline bool SDL_RectsEqualEpsilonRefs(const SDL_FRect & a,const SDL_FRect & b,float epsilon) {return SDL_RectsEqualEpsilon(&a,&b,epsilon);}
