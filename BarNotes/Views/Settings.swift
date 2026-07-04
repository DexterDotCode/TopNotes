//
//  PopoverView.swift
//  TopNotes
//
//  Created by Tanish Mittal on 03/04/25.
//

import SwiftUI
import StoreKit

struct Settings: View {
    @Environment(AppState.self) var appState
    @Environment(\.openURL) private var openURL
    
    @Binding var fontSize: Double
    @Binding var theme: ThemeColors
    @Binding var fontDesign: FontDesign
    @AppStorage("menubarIcon") private var menubarIcon: MenuBarIcon = .pencil
    
    var body: some View {
        @Bindable var appState = appState
        
        VStack(spacing: 0) {
            // Custom title strip standing in for the native title bar: shows
            // the app name, hosts the traffic-light buttons, and (via
            // DragHandle below) lets the user drag the window by this area -
            // all things a borderless NSPanel doesn't get for free.
            ZStack {
                HStack(spacing: 0) {
                    // Custom traffic-light buttons. Only the red one is
                    // functional (closes Settings); yellow and green are
                    // purely decorative, matching the standard macOS window
                    // chrome pattern where minimize/full-screen wouldn't be
                    // meaningful for a small utility panel like this.
                    HStack(spacing: 8) {
                        CloseButton {
                            SettingsPanelController.shared.close()
                        }
                        
                        DecorativeTrafficLight()
                        DecorativeTrafficLight()
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                }
                
                Text("BarNotes Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 28)
            .background(DragHandle())
            
            List {
                VStack(alignment: .leading, spacing: 25) {
                    HStack {
                        Text("Font Size")

                        Spacer()
                        
                        ControlGroup {
                            Button("Decrease font size", systemImage: "minus") {
                                withAnimation(.spring) { fontSize -= 1 }
                            }
                            
                            Button("Increase font size", systemImage: "plus") {
                                withAnimation(.spring) { fontSize += 1 }
                            }
                        }
                    }
                    
                    Picker("Note Font", selection: $fontDesign) {
                        ForEach(FontDesign.allCases) { font in
                            Text(font.description)
                        }
                    }
                    
                    Picker("Background Color", selection: $theme) {
                        ForEach(ThemeColors.allCases) { bgColor in
                            Text(bgColor.bgColorLabel)
                        }
                        
                    }
                    
                    Picker("Menu Bar Icon", selection: $menubarIcon) {
                        ForEach(MenuBarIcon.allCases) { menubarIcon in
                            Image(systemName: menubarIcon.icon)
                                .tint(.primary)
                        }
                     }
                    
                    Toggle("Launch at login", isOn: $appState.launchAtLogin)
                        .toggleStyle(.switch)
                    
                    Spacer()
                    
                    HStack {
                        Link(destination: URL(string: "https://github.com/dexterdotcode/barnotes")!) {
                            Text("Github")
                        }
                        .tint(.blue)
                        .buttonStyle(.accessoryBar)
                        
                        Spacer()
                        
                        Button("Leave a Review") {
                            let url = URL(string: "https://apps.apple.com/app/id6744329261?action=write-review")!
                            openURL(url)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Quit") {
                            NSApp.terminate(nil)
                        }
                        .tint(.red)
                        .buttonStyle(.accessoryBar)
                    }
                }
                .fontWeight(.medium)
            }
            .scrollDisabled(true)
        }
        .frame(width: 370, height: 330 + 28, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// A close button styled to resemble the native macOS traffic-light close
/// button (red circle, darker "×" glyph that appears on hover), used here
/// since the Settings panel has no native title bar to provide one.
private struct CloseButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.37, blue: 0.34))
                    .frame(width: 13, height: 13)

                if isHovering {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(Color(red: 0.4, green: 0.05, blue: 0.02))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close Settings")
        .help("Close")
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// A purely decorative gray circle, standing in for the native macOS
/// minimize/full-screen traffic-light buttons. Grayed out (rather than
/// yellow/green) to visually signal "present but disabled," matching the
/// convention used by other macOS utility panels where those actions
/// wouldn't be meaningful.
private struct DecorativeTrafficLight: View {
    var body: some View {
        Circle()
            .fill(Color(nsColor: .quaternaryLabelColor))
            .frame(width: 13, height: 13)
    }
}

/// An invisible view that lets the user drag the Settings panel by clicking
/// and dragging within the title strip, standing in for the native title
/// bar's drag behavior. Uses `NSWindow.performDrag(with:)`, the standard
/// AppKit mechanism for implementing custom draggable regions.
private struct DragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragHandleView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private class DragHandleView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
