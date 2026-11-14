#include "capture_permission.h"
#import <AVFoundation/AVFoundation.h>

namespace dassdl3_ios {
static AVMediaType mediaType(CaptureDevice device) {
    return device == CaptureDevice::Camera ? AVMediaTypeVideo : AVMediaTypeAudio;
}

CapturePermission capturePermission(CaptureDevice device) {
    switch ([AVCaptureDevice authorizationStatusForMediaType:mediaType(device)]) {
    case AVAuthorizationStatusNotDetermined: return CapturePermission::Pending;
    case AVAuthorizationStatusAuthorized: return CapturePermission::Approved;
    default: return CapturePermission::Denied;
    }
}

void requestCapturePermission(CaptureDevice device) {
    [AVCaptureDevice requestAccessForMediaType:mediaType(device) completionHandler:^(BOOL) {}];
}
}
