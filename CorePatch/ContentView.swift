//
//  ContentView.swift
//  CorePatch
//
//  Created by Francis John on 6/25/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showCoreWoundSheet = false
    @State private var showingSettings = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            NavigationStack {
                TabView {
                    HomeView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }

                    HistoryView()
                        .tabItem {
                            Image(systemName: "calendar")
                            Text("Progress")
                        }

                    ChatView()
                        .tabItem {
                            Image(systemName: "message")
                            Text("Chat")
                        }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCoreWoundSheet) {
                CoreWoundSelectionView()
            }
            .sheet(isPresented: $showingSettings) {
                AppSettingsView()
            }
            .onAppear { updateSheetState() }
            .onChange(of: activeWounds) { _, _ in updateSheetState() }
        }
    }

    private func updateSheetState() {
        showCoreWoundSheet = activeWounds.isEmpty
    }
}
