//
//  AppDelegate.swift
//  SoundPriority
//
//  Sets up the status bar item + popover and starts audio polling.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppState.shared.launchAtLoginManager.refreshStatus()
        AppState.shared.startPolling()

        // Create the SwiftUI popover content and attach it to an NSPopover.
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 280, height: 220)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(appState: AppState.shared)
        )

        // Status bar controller owns the NSStatusItem and toggles the popover.
        statusBarController = StatusBarController(popover: popover)
    }
}

