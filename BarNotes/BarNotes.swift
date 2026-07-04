//
//  TopNotesApp.swift
//  TopNotes
//
//  Created by Tanish Mittal on 26/03/25.
//

import SwiftUI
import MenuBarExtraAccess


@main
struct BarNotes: App {
    @AppStorage("menubarIcon") private var menubarIcon: MenuBarIcon = .pencil

    /// Single shared AppState instance, passed to both ContentView and the
    /// Settings panel so they stay in sync (e.g. toggling "Launch at login"
    /// in Settings should reflect immediately in the main note view).
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("BarNotes", systemImage: menubarIcon.icon) {
            ContentView()
                .environment(appState)
                .environment(TipsStore())
                .frame(width: 400, height: 350)
                .introspectMenuBarExtraWindow { window in
                    SettingsPanelController.shared.attach(to: window)
                    SettingsPanelController.shared.appState = appState
                }
        }
        .menuBarExtraStyle(.window)
    }
}
