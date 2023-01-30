//
//  BoundingBox.swift
//  FaceID
//
//  Created by Phoom Punpeng on 18/1/23.
//

import Foundation
import AppKit

class BoundingBox: NSView {
    var color: NSColor = .red
    var boxRect: CGRect = CGRect()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func draw(_ rect: CGRect) {
        let frame = self.frame
        let newRect = CGRect(x: boxRect.minX * frame.width, y: boxRect.minY * frame.height, width: boxRect.width * frame.width, height: boxRect.height * frame.height)
        let context = NSGraphicsContext.current!.cgContext
        self.color.setStroke()
        context.setLineWidth(5.0)
        context.addRect(newRect)
        context.strokePath()
    }
}
