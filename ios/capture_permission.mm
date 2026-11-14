#include "capture_permission.h"
#import <AVFoundation/AVFoundation.h>

namespace dassdl3_ios {
CameraPermission cameraPermission() {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
    case AVAuthorizationStatusNotDetermined: return CameraPermission::Pending;
    case AVAuthorizationStatusAuthorized: return CameraPermission::Approved;
    default: return CameraPermission::Denied;
    }
}

void requestCameraPermission() {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL) {}];
}
}
