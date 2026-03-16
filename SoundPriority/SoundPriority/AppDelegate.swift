//
//  AppDelegate.swift
//  SoundPriority
//
//  Starts the 1s polling when the app finishes launching.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppState.shared.launchAtLoginManager.refreshStatus()
        AppState.shared.startPolling()
    }
}
