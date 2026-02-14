//
//  LuxShotApp.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import SwiftUI

@main
struct LuxShotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
