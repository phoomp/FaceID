//
//  PointSet.swift
//  FaceID
//
//  Created by Phoom Punpeng on 27/3/23.
//

import Foundation

class PointSet {
    var facePoints: [CGPoint]
    
    init(facePoints: [CGPoint]) {
        self.facePoints = facePoints
    }
    
    private func pointDistance(p1x: Double, p1y: Double, p2x: Double, p2y: Double) -> Double {
        return sqrt(pow(p1x - p2x, 2) + pow(p1y - p2y, 2))
    }
    
    public func calculateDistances() -> [Double] {
        var pointX: [Double] = []
        var pointY: [Double] = []
        
        var dists: [Double] = []
        
        for point in self.facePoints {
            pointX.append(point.x)
            pointY.append(point.y)
        }
        
        for i in 0...self.facePoints.count - 2 {
            for j in i+1...self.facePoints.count - 1 {
                let p1 = self.facePoints[i]
                let p2 = self.facePoints[j]
                dists.append(self.pointDistance(p1x: p1.x, p1y: p1.y, p2x: p2.x, p2y: p2.y))
            }
        }
        
        return dists
    }
}
