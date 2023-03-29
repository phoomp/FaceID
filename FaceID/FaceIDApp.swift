//
//  FaceIDApp.swift
//  FaceID
//
//  Created by Phoom Punpeng on 12/1/23.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
//        FirebaseApp.configure()
    }
}

@main
struct FaceIDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State var disabled: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .opacity(disabled ? 0 : 1)
                .onAppear {
                    setupApp()
                }
//            LockScreenView()
        }
    }
    
    private func setupApp() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        
        let db = Firestore.firestore()
        db.settings = settings
        
        var appID: String? = UserDefaults.standard.string(forKey: "appID")
        if appID == nil {
            print("appID not found: creating a new one and saving...")
            appID = UUID().uuidString
            UserDefaults.standard.set(appID, forKey: "appID")
        }
        
        guard let appID = appID else { return }
        
        print("appID: \(appID)")
        
        db.collection("instances").document(appID).addSnapshotListener { documentSnapshot, error in
            guard let snapshot = documentSnapshot else {
                print("Error fetching document: \(error)")
                fatalError("This app, in its beta testing stage, requires an active internet connection at all time.")
            }
            
            guard let d = snapshot.data() else {
                print("Document data was empty! Creating a new record for appID \(appID)")
                let instance = Instance(hostName: "phoom", userName: "phoom", disabled: 0)
                do {
                    try db.collection("instances").document(appID).setData(from: instance)
                } catch let error {
                    print("Error writing city to Firestore: \(error)")
                }
                return
            }
            
            do {
                let data = try snapshot.data(as: Instance.self)
                
                if data.disabled > 0 {
                    self.disabled = true
                    if data.disabled == 1 {
                        let alert = NSAlert()
                        alert.messageText = "This copy of FaceID has been invalidated. Thank you for testing it!"
                        alert.informativeText = "Either an update is available, or this software has been disabled for your device."
                        alert.alertStyle = NSAlert.Style.warning
                        alert.addButton(withTitle: "Ok")
                        alert.runModal()
                    }
                    
                    exit(0)
                }
            } catch let error {
                print("Unable to decode data: \(error)")
            }
        }
    }
}
