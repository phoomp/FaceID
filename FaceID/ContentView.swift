//
//  ContentView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 12/1/23.
//

import SwiftUI


struct ContentView: View {
    @State var fps: Double
    @State var training: Bool = false
    
    var faceIDView: FaceIDView
    var minFPS: Double
    var maxFPS: Double
    
    init() {
        self.faceIDView = FaceIDView()
        self.minFPS = 0
        self.maxFPS = 0
        
        while self.minFPS == 0 && self.maxFPS == 0 {
            (self.minFPS, self.maxFPS) = self.faceIDView.vc.getMinMaxFPS()
        }
        
        self.fps = UserDefaults.standard.double(forKey: "fps")
        self.faceIDView.vc.fps = self.fps
    }
    
    var body: some View {
        VStack {
            self.faceIDView
                .onChange(of: fps) { newValue in
                    self.faceIDView.vc.fps = newValue
                    UserDefaults.standard.set(newValue, forKey: "fps")
                    print("FPS changed to \(newValue)")
                }
                .onChange(of: training, perform: { newValue in
                    self.faceIDView.vc.training = newValue
                })
                .frame(width: 1000, height: 600)
            
            HStack {
                Spacer()
                VStack {
                    SliderView(fps: $fps, minFPS: minFPS, maxFPS: maxFPS)
                        .frame(width: 800)
                    Toggle(isOn: $training) {
                        Text("Training Mode")
                    }
                    ControlInterface()
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
