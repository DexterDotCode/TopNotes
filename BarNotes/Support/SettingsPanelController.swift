//
//  SettingsPanelController.swift
//  BarNotes
//
//  Manages the Settings window as a real AppKit NSPanel, attached as a child
//  window of the MenuBarExtra panel. This fixes bugs caused by using a
//  SwiftUI `.popover` inside a `MenuBarExtra(.window)`:
//
//  1. The Settings popover could render behind other apps' windows, because
//     a `.popover` doesn't inherit the MenuBarExtra panel's window level.
//     Fixed by giving Settings its own `.floating` window level.
//
//  2. Opening Settings, or clicking anywhere within it, caused the main note
//     view to close. BarNotes runs as an accessory app (no Dock icon), and
//     the note's own dismissal logic treats any loss of app focus as a
//     reason to close. Making Settings a `.nonactivatingPanel` prevents
//     ordinary clicks on it from stealing key window status outright, but
//     that alone wasn't sufficient - adding Settings as a child window of
//     the note's window (`addChildWindow`) is what actually keeps AppKit
//     from treating interaction with Settings as "BarNotes lost focus."
//
//  3. Closing Settings (via its own close button) also closed the note, for
//     the same underlying reason: with Settings gone, there was briefly no
//     BarNotes window left to hold focus. Fixed by explicitly re-focusing
//     the note's window at the moment Settings closes, via a window delegate
//     hooked into `windowWillClose`, so there's no focus gap - this covers
//     both our own `close()` calls and the user clicking Settings' own
//     close button directly.
//

import SwiftUI
import AppKit

@MainActor
final class SettingsPanelController: NSObject, NSWindowDelegate {

    /// Shared singleton, since there's only ever one Settings panel for the app.
    static let shared = SettingsPanelController()

    private var panel: NSPanel?

    /// The MenuBarExtra's real NSWindow, captured via `.introspectMenuBarExtraWindow`.
    /// Kept so we can hand focus back to it when Settings closes.
    private weak var parentWindow: NSWindow?

    /// The shared AppState instance, set once from BarNotes.swift. Injected into
    /// the Settings view's environment so `@Environment(AppState.self)` resolves,
    /// and so changes (e.g. "Launch at login") stay in sync with the main note view.
    var appState: AppState?

    private override init() {
        super.init()
    }

    /// Called once, when the MenuBarExtra window becomes available.
    /// Safe to call multiple times; only stores the reference.
    func attach(to window: NSWindow) {
        parentWindow = window
    }

    /// Shows the Settings panel, centered on screen, with the supplied
    /// bindings passed through to the existing `Settings` view.
    func show(
        fontSize: Binding<Double>,
        theme: Binding<ThemeColors>,
        fontDesign: Binding<FontDesign>
    ) {
        guard let parentWindow, let appState else { return }

        // If already visible, just bring it to front rather than recreating it.
        if let panel, panel.isVisible {
            panel.orderFront(nil)
            return
        }

        let settingsView = Settings(fontSize: fontSize, theme: theme, fontDesign: fontDesign)
            .environment(appState)
        let hostingController = NSHostingController(rootView: settingsView)

        let newPanel = NSPanel(contentViewController: hostingController)
        newPanel.styleMask = [.nonactivatingPanel, .closable, .utilityWindow, .borderless]
        newPanel.isFloatingPanel = true
        newPanel.level = .floating
        newPanel.hidesOnDeactivate = false
        newPanel.isMovableByWindowBackground = true
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.delegate = self

        newPanel.center()

        // Settings is added as a child window of the note's window: this keeps
        // ordinary clicks on Settings from being treated as "BarNotes lost focus"
        // by the note's own dismissal logic. The separate windowWillClose(_:)
        // delegate method below handles re-focusing the note specifically at the
        // moment Settings closes, since closing a child window doesn't happen
        // to trigger that focus hand-off on its own.
        parentWindow.addChildWindow(newPanel, ordered: .above)
        newPanel.orderFront(nil)

        panel = newPanel
    }

    /// Closes the Settings panel, if open.
    func close() {
        panel?.close()
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    // MARK: - NSWindowDelegate

    /// Called both when we call `panel.close()` ourselves, and when the user
    /// clicks the panel's own close button directly - covering both paths
    /// that need the note to regain focus.
    func windowWillClose(_ notification: Notification) {
        guard let closingPanel = panel else { return }
        parentWindow?.removeChildWindow(closingPanel)
        panel = nil
        // Hand focus back to the note's window so BarNotes never has a moment
        // with zero focused windows, which is what was triggering the note's
        // own dismissal logic.
        parentWindow?.makeKeyAndOrderFront(nil)
    }
}
