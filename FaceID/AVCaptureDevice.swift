//
//  AVCaptureDevice.swift
//  FaceID
//
//  Created by Phoom Punpeng on 28/3/23.
//

import Foundation
import Vision
import AVKit


extension AVCaptureDevice {
    func set(frameRate: Double) {
        guard let range = activeFormat.videoSupportedFrameRateRanges.first,
            range.minFrameRate...range.maxFrameRate ~= frameRate
            else {
                print("Requested FPS is not supported by the device's activeFormat !")
                return
        }

        do { try lockForConfiguration()
            activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            unlockForConfiguration()
        } catch {
            print("LockForConfiguration failed with error: \(error.localizedDescription)")
        }
    }
}
