//
//  FaceIDApp.swift
//  FaceID
//
//  Created by Phoom Punpeng on 12/1/23.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
    }
}

@main
struct FaceIDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//            LockScreenView()
        }
    }
}
