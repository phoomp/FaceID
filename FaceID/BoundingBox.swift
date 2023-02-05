//
//  BoundingBox.swift
//  FaceID
//
//  Created by Phoom Punpeng on 18/1/23.
//

import Foundation
import AppKit
import Vision

class BoundingBox: NSView {
    var colors: [NSColor] = []
    var boxRects: [CGRect] = []
    var landmarks: [VNFaceLandmarks2D] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func draw(_ rect: CGRect) {
        let frame = self.frame
        let context = NSGraphicsContext.current!.cgContext
        
        for (boxRect, (landmark, color)) in zip(boxRects, zip(landmarks, colors)) {
            let newRect = CGRect(x: boxRect.minX * frame.width, y: boxRect.minY * frame.height, width: boxRect.width * frame.width, height: boxRect.height * frame.height)
            color.setStroke()
            context.setLineWidth(5.0)
            context.setLineDash(phase: 0, lengths: [])
            context.addRect(newRect)
            context.strokePath()
            
            let subLandmarks: [VNFaceLandmarkRegion2D] = [
                landmark.faceContour!,
                landmark.leftEye!,
                landmark.rightEye!,
                landmark.leftEyebrow!,
                landmark.rightEyebrow!,
                landmark.nose!,
                landmark.noseCrest!,
                landmark.medianLine!,
                landmark.outerLips!,
                landmark.innerLips!,
                landmark.leftPupil!,
                landmark.rightPupil!
            ]
            
//            print("Precision Estimates: \(landmark.allPoints?.precisionEstimatesPerPoint)")
//            print("Confidence: \(landmark.confidence)")
                        
            context.setLineWidth(2.0)
            context.setLineDash(phase: 10, lengths: [2])
            
            for (i, subLandmark) in subLandmarks.enumerated() {
//                print(subLandmark.normalizedPoints.count)
                let precisions = subLandmark.precisionEstimatesPerPoint!

//              Averaged Precision
                var sum: Float = 0
                for precision in precisions {
                    sum += precision
                }
                let avgPrecision = sum / Float(precisions.count)
//                print("\(i) Average Precision: \(avgPrecision)")
                let points = subLandmark.pointsInImage(imageSize: frame.size)
                context.addLines(between: points)
                avgPrecision < 0.0135 ? NSColor.green.setStroke() : NSColor.red.setStroke()
                
                
                // Point-by-Point Precision
//                var sum: Float = 0
//                let points = subLandmark.pointsInImage(imageSize: frame.size)
//                context.addLines(between: <#T##[CGPoint]#>)
                
                context.strokePath()
            }
        }
    }
}
