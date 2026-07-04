//
//  ContentView.swift
//  TopNotes
//
//  Created by Tanish Mittal on 26/03/25.
//

import KeychainAccess
import OSLog
import ServiceManagement
import SwiftUI


struct ContentView: View {
    @Environment(AppState.self) var appState
    @Environment(\.appearsActive) var appearsActive
    
    @AppStorage("fontSize") var fontSize = 13.0
    @AppStorage("fontDesign") var fontDesign: FontDesign = .system
    @AppStorage("bgColor") var theme: ThemeColors = .blue
    
    @State private var notes = ""
    @State private var savingTask: Task<Void, any Error>? = nil
    @State private var showTipJar = false
    
    let keychain = Keychain(service: "com.dextercode.BarNotes")
    
    var body: some View {
        VStack {
            TextEditor(text: $notes)
                .animatableFontSize(size: fontSize)
                .foregroundStyle(theme.fontColor)
                .fontDesign(fontDesign.design)
                .lineSpacing(5)
            
            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(notes, forType: .string)
                    Logger.dataOperations.info("Text copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.accessoryBar)
                .accessibilityLabel("Copy note")
                .help("Copy")

                Spacer()
                
                Button {
                    showTipJar.toggle()
                } label: {
                    Image(systemName: "heart.fill")
                }
                .buttonStyle(.accessoryBar)
                .accessibilityLabel("Tip Jar")
                .help("Tip Jar")
                
                Spacer()
                
                Button {
                    if SettingsPanelController.shared.isVisible {
                        SettingsPanelController.shared.close()
                    } else {
                        SettingsPanelController.shared.show(
                            fontSize: $fontSize,
                            theme: $theme,
                            fontDesign: $fontDesign
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(.accessoryBar)
                .accessibilityLabel("Settings")
                .help("Settings")
            }
            .popover(isPresented: $showTipJar,
                     attachmentAnchor: .point(.top),
                     arrowEdge: .bottom) {
                TipJarView()
            }
        }
        .padding()
        .tint(theme.fontColor)
        .background(theme.bgColor)
        .onChange(of: notes) { _, newValue in
            saveNotes(newValue: newValue)
        }
        .onChange(of: appState.launchAtLogin) { _, state in
            launchAtLoginByToggle(state)
        }
        .onChange(of: appearsActive) { _, state in
            launchAtLoginFromSettings(state)
        }
        .onAppear(perform: checkLaunchAtLoginStatus)
        .onAppear(perform: loadNotes)
    }
    
    
    private func launchAtLoginByToggle(_ state: Bool) {
        if state == true {
            try? SMAppService.mainApp.register()
            Logger.dataOperations.info("Launch at login in set to true")
        } else {
            try? SMAppService.mainApp.unregister()
            Logger.dataOperations.info("Launch at login in set to false")
        }
    }
    
    /// If user remove the app from Login Items in Settings directly,
    /// and the app window is also opened, which is not possible in this app
    /// but just to be safe and ensure reliability,
    /// the `onChanged` method updates the UI state
    /// when the app window regains focus by using the `appearsActive` environment value.
    private func launchAtLoginFromSettings(_ state: Bool) {
        guard state else { return }
        if SMAppService.mainApp.status == .enabled {
            appState.launchAtLogin = true
            Logger.dataOperations.info("Launch at login in set to true from the settings")
        } else {
            appState.launchAtLogin = false
            Logger.dataOperations.info("Launch at login in set to false from the settings")
        }
    }
    
    /// Checking the current login status at launch
    private func checkLaunchAtLoginStatus() {
        if SMAppService.mainApp.status == .enabled {
            appState.launchAtLogin = true
            Logger.dataOperations.info("Launch at login appears to be true")
        } else {
            appState.launchAtLogin = false
            Logger.dataOperations.info("Launch at login appears to be false")
        }
    }
    
    /// Load notes from the user's keychain at launch.
    private func loadNotes() {
        notes = keychain["notes"] ?? ""
        Logger.dataOperations.info("Notes loaded from the keychain")
    }
    
    /// Saves the user's latest note using a sleeping task to avoid writing to keychain on every keypress.
    /// Delay saving by 1 second for efficiency.
    /// If there is currently a sleeping save task active, cancel it now to avoid multiple writes to the keychain.
    private func saveNotes(newValue: String) {
        savingTask?.cancel()
        
        savingTask = Task {
            try await Task.sleep(for: .seconds(1))
            keychain["notes"] = newValue
            Logger.dataOperations.info("Notes are saved into the keychain")
        }
    }
}
