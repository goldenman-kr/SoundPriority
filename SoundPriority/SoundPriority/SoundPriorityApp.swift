//
//  SoundPriorityApp.swift
//  SoundPriority
//
//  AudioPriority: menu bar app that switches system output to the highest-priority available device.
//

import SwiftUI

@main
struct SoundPriorityApp: App {
    private var appState: AppState { AppState.shared }
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar item: show "AudioPriority" and open settings from menu
        MenuBarExtra("AudioPriority", systemImage: "speaker.wave.2.fill") {
            MenuBarMenuContent(appState: appState)
        }
        .menuBarExtraStyle(.window)

        // Settings window (opened from menu via openWindow(id:))
        Window("AudioPriority Settings", id: "settings") {
            SettingsView(appState: appState)
                .onAppear {
                    appState.ensurePriorityContains(deviceIDs: appState.outputDevices.map(\.id))
                    appState.launchAtLoginManager.refreshStatus()
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 380)
        .commandsRemoved()
    }
}

// Menu content view so we can use @Environment(\.openWindow) to open Settings.
private struct MenuBarMenuContent: View {
    let appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Settings…") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }
        // Launch at login: SMAppService.mainApp.register() / unregister()
        Button(action: toggleLaunchAtLogin) {
            if appState.launchAtLoginManager.isEnabled {
                Label("Launch at login", systemImage: "checkmark")
            } else {
                Text("Launch at login")
            }
        }
        Button("Quit") {
            appState.stopPolling()
            NSApplication.shared.terminate(nil)
        }
    }

    private func toggleLaunchAtLogin() {
        if appState.launchAtLoginManager.isEnabled {
            appState.launchAtLoginManager.disable()
        } else {
            appState.launchAtLoginManager.enable()
        }
    }
}
