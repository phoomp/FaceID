//
//  FaceRecognition.swift
//  FaceID
//
//  Created by Phoom Punpeng on 28/3/23.
//

import Foundation
import AVKit
import AppKit
import Vision
import CoreML


extension FaceIDViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func performFaceLocalization(on pixelBuffer: CVPixelBuffer) -> [(CGRect, VNFaceLandmarks2D)] {
        let imageSequenceHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        var allResults: [(CGRect, VNFaceLandmarks2D)] = []

        let faceLandmarkRequest = VNDetectFaceLandmarksRequest { request, error in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            for result in results {
                allResults.append((result.boundingBox, result.landmarks!))
            }
        }

        do {
            try imageSequenceHandler.perform([faceLandmarkRequest])
        } catch {
            print("Vision request error")
            print(error.localizedDescription)
        }

        return allResults
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // immediately get and store the fps
        let instantFPS = self.fps
        let instantTime = CMTimeMake(value: 1, timescale: Int32(instantFPS))
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let results = self.performFaceLocalization(on: pixelBuffer)
        let valid = evaluateResults(results: results, training: self.training)
        let time = CMTimeGetSeconds(self.validTime)
        
        if valid {
            if time > 0 {
                self.validTime = CMTimeAdd(self.validTime, instantTime)
            } else {
                self.validTime = CMTimeAdd(CMTimeMake(value: 0, timescale: 1), instantTime)
            }
        } else {
            if time < 0 {
                self.validTime = CMTimeSubtract(self.validTime, instantTime)
            } else {
                self.validTime = CMTimeSubtract(CMTimeMake(value: 0, timescale: 1), instantTime)
            }
        }
        
        if time > self.secsBeforeUnlock {
            self.validTime = CMTimeMake(value: 0, timescale: 1)
            print("Unlock")
            if self.state.active {
                DispatchQueue.main.async {
                    self.state.active = false
                    
                }
            }
        } else if time < -self.secsBeforeLock {
            self.validTime = CMTimeMake(value: 0, timescale: 1)
            DispatchQueue.main.async {
                if self.state.active == false {
                    performLockScreenSequence(state: self.state)
                }
                print("Locking screen!")
            }
        }
        
        print(time)
    }
    
    func evaluateResults(results: [(CGRect, VNFaceLandmarks2D)], training: Bool) -> Bool {
//        print("Training: \(training)")
//        print("Valid faces len: \(self.validFaces.count)")
        for (box, landmarks) in results {
            for face in self.validFaces {
                let pointSet = PointSet(facePoints: landmarks.allPoints!.normalizedPoints)
                let dists = pointSet.calculateDistances()
                
                if training {
//                    print("training is true")
                    self.validFaces.append(dists)
                    while self.validFaces.count > 100 {
                        self.validFaces.remove(at: 0)
                    }
                    return true
                }
                
                let diff = self.euclideanNorm(arr1: dists, arr2: face)
                if diff < self.threshold {
                    return true
                }
            }
        }
        return false
    }

    func createCGImage(from pixelBuffer: CVPixelBuffer) -> String {
        let ciContext = CIContext()
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let filename = "/Users/phoom/Documents/FaceID/imgs/\(UUID()).png"
        
        do {
            try ciContext.writePNGRepresentation(of: ciImage, to: URL(filePath: filename), format: .BGRA8, colorSpace: ciImage.colorSpace!)
        } catch {
            print("Error: \(error)")
        }
        
        return filename
    }
    
    func euclideanNorm(arr1: [Double], arr2: [Double]) -> Double {
        var sumBeforeRoot: Double = 0
        for (m1, m2) in zip(arr1, arr2) {
            sumBeforeRoot += pow((m2 - m1), 2)
        }

        return sumBeforeRoot.squareRoot()
    }
}
