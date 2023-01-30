//
//  ContentView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 12/1/23.
//

import SwiftUI


struct ContentView: View {
    @State var framesBetweenUpdates: Double = 10
    @State var framesBeforeLock: Double = 300
    @State var userPassword: String
    @State var training: Bool = false
    
    var cameraView: CameraView
    
    init() {
        self.cameraView = CameraView()
        self.cameraView.vc.saveAllFrames = false
        
        // Retrieve password if it exists
        self.userPassword = UserDefaults.standard.string(forKey: "userPassword") ?? ""
        if self.userPassword != "" {
            print("Recovered password: \(self.userPassword)")
        }
    }
    
    var body: some View {
        VStack {
            self.cameraView
                .onChange(of: framesBetweenUpdates) { newValue in
                    self.cameraView.vc.set(framesBetweenUpdates: Int(newValue))
                }
                .onChange(of: training, perform: { newValue in
                    self.cameraView.vc.saveThisFace = newValue
                })
                .onChange(of: framesBeforeLock, perform: { newValue in
                    self.cameraView.vc.framesBeforeLock = Int(newValue)
                })
                .frame(width: 1000, height: 600)
            
            HStack {
                Spacer()
                VStack {
                    SliderView(framesBetweenUpdates: $framesBetweenUpdates, framesBeforeLock: $framesBeforeLock)
                        .frame(width: 400)
                    Toggle(isOn: $training) {
                        Text("Training Mode")
                    }
                }
                .padding()
                Spacer()
                VStack(alignment: .leading) {
                    ControlInterface(userPassword: $userPassword)
                        .frame(width: 400)
                }
                .padding()
                Spacer()
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
