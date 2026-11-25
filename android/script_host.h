#pragma once
#include "../mobile/bundle_scripts.h"

namespace android_host {
struct Script {
    std::string source;
    das::TextWriter log;
    das::ModuleGroup modules;
    das::ProgramPtr program;
    std::unique_ptr<das::Context> context;

    bool load(const char *path, bool aot, bool expectMissingAot = false, bool fromSource = false);
};

int runMode(const char *mode);
bool runLive(bool test);
bool runKeyboard(bool widgets);
bool runMultitouch(bool keyboardOnly);
bool showVulkanTriangle();
bool runCapture(bool camera, bool denied);
bool runSensors();
}
