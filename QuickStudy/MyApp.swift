//
//  MyApp.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/17/26.
//

import SwiftUI

@main
struct MyApp: App {
    init() {
        #if DEBUG
        FreshInstallReset.performIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
