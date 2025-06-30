//
//  CorePatchApp.swift
//  CorePatch
//
//  Created by Francis John on 6/25/25.
//

import SwiftUI
import SwiftData

@main
struct CorePatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserCoreWound.self, CorePatchEntry.self])
    }
}
