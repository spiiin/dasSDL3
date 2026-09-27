#pragma once
#include "daScript/daScript.h"
#include "imgui.h"

// Pinned dasImgui exports these functions but omits their AOT declarations.
// Declarations only: implementations remain in the unmodified upstream library.
namespace das {
void DisableIniPersistence();
ImU32 GetActiveID();
bool InputTextBasic(uint8_t *, int, const char *, ImGuiInputTextFlags_);
bool InputTextWithHintBasic(uint8_t *, int, const char *, const char *, ImGuiInputTextFlags_);
bool InputTextMultilineBasic(uint8_t *, int, const char *, const ImVec2 &, ImGuiInputTextFlags_);
bool InputTextCb(uint8_t *, int, const char *, ImGuiInputTextFlags_, Lambda, Context *, LineInfoArg *);
void PlotLinesCb(const char *, int, int, const char *, float, float, ImVec2, Lambda, Context *, LineInfoArg *);
void PlotHistogramCb(const char *, int, int, const char *, float, float, ImVec2, Lambda, Context *, LineInfoArg *);
}
