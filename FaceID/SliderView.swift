//
//  SliderView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 18/1/23.
//

import SwiftUI

struct SliderView: View {
    @Binding var framesBetweenUpdates: Double
    @Binding var framesBeforeLock: Double
    @State var isEditing: Bool = false
    
    var minimumValue: Int = 0
    var maximumValue: Int = 80
    
    var minimumLockValue: Int = 20 // 5 seconds
    var maxmimumLockValue: Int = 300 // About 1 min
    
    var body: some View {
        VStack {
            Slider(value: $framesBetweenUpdates, in: Double(minimumValue)...Double(maximumValue), step: 5) {
                Text("Frames Between Updates")
            } minimumValueLabel: {
                Text("\(minimumValue)")
            } maximumValueLabel: {
                Text("\(maximumValue)")
            } onEditingChanged: { editing in
                isEditing = editing
            }
            Spacer()
            Slider(value: $framesBeforeLock, in: Double(minimumLockValue)...Double(maxmimumLockValue), step: 20) {
                Text("Negative Frames Before Lock")
            } minimumValueLabel: {
                Text("\(minimumLockValue)")
            } maximumValueLabel: {
                Text("\(maxmimumLockValue)")
            } onEditingChanged: { editing in
                isEditing = editing
            }
        }
    }
}
