#pragma once

#include "daScript/daScript.h"
#include "daScript/simulate/fs_file_info.h"
#include <SDL3/SDL.h>
#include <filesystem>
#include <limits>
#include <memory>
#include <utility>

namespace dassdl3_ios {
class BundleAccess final : public das::FsFileAccess {
public:
    das::ModuleInfo getModuleInfo(const das::string &request, const das::string &from) const override {
        // The SDK's no-file-I/O build omits source-relative import resolution.
        const std::filesystem::path path(request.c_str());
        if (request.compare(0, 2, "./") == 0 && path.extension() == ".das") {
            const auto file = (std::filesystem::path(from.c_str()).parent_path() / path).lexically_normal();
            das::ModuleInfo info;
            info.fileName = file.generic_string().c_str();
            info.moduleName = info.importName = file.stem().generic_string().c_str();
            return info;
        }
        return FsFileAccess::getModuleInfo(request, from);
    }
};

class BundleScripts final : public das::AnyFileSystem {
public:
    explicit BundleScripts(das::string root) : root_(std::move(root)) {}
    das::FileInfo *tryOpenFile(const das::string &name) override {
        // Only packaged .das files, through the module resolver's absolute paths.
        if (name.compare(0, root_.size(), root_) != 0 || name.find("..") != das::string::npos ||
            name.size() < 4 || name.compare(name.size() - 4, 4, ".das") != 0) return nullptr;
        size_t length = 0;
        std::unique_ptr<void, decltype(&SDL_free)> bytes(SDL_LoadFile(name.c_str(), &length), SDL_free);
        if (!bytes || length > std::numeric_limits<uint32_t>::max()) return nullptr;
        auto *source = static_cast<char *>(das_aligned_alloc16(length + 1));
        if (!source) return nullptr;
        SDL_memcpy(source, bytes.get(), length + 1); // SDL_LoadFile appends NUL.
        return new das::TextFileInfo(source, static_cast<uint32_t>(length), true);
    }
private:
    das::string root_;
};
}
