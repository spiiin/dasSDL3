#pragma once

namespace dassdl3_ios {
enum class CaptureDevice { Camera, Microphone };
enum class CapturePermission { Pending, Approved, Denied };
CapturePermission capturePermission(CaptureDevice device);
void requestCapturePermission(CaptureDevice device);
}
