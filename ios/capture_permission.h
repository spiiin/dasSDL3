#pragma once

namespace dassdl3_ios {
enum class CameraPermission { Pending, Approved, Denied };
CameraPermission cameraPermission();
void requestCameraPermission();
}
