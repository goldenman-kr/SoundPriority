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
        // Settings window (opened from the custom status bar popover).
        Window("SoundPriority Settings", id: "settings") {
            SettingsView(appState: appState)
                .onAppear {
                    appState.ensurePriorityContains(devices: appState.outputDevices)
                    appState.launchAtLoginManager.refreshStatus()
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 380)
        .commandsRemoved()
    }
}
