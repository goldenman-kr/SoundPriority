//
//  LaunchAtLoginManager.swift
//  SoundPriority
//
//  Manages "Launch at login" using ServiceManagement (SMAppService.mainApp).
//  Use this to register/unregister the app as a login item and to read current status.
//

import Foundation
import ServiceManagement
import SwiftUI

/// Manages launch-at-login state via SMAppService.mainApp.
/// Exposes isEnabled, enable(), disable(), and refreshStatus() for the UI and app state.
@Observable
final class LaunchAtLoginManager {

    /// True when the app is registered as a login item (launches at user login).
    private(set) var isEnabled: Bool = false

    /// Non-nil when the last enable/disable operation failed; cleared on next success or refreshStatus().
    private(set) var lastError: String?

    // MARK: - Public API

    /// Registers the app as a login item. Call from main thread.
    /// Updates isEnabled and lastError when done.
    func enable() {
        lastError = nil
        do {
            try SMAppService.mainApp.register()
            refreshStatus()
        } catch {
            lastError = error.localizedDescription
            refreshStatus()
        }
    }

    /// Unregisters the app from login items. Call from main thread.
    /// Updates isEnabled and lastError when done.
    func disable() {
        lastError = nil
        do {
            try SMAppService.mainApp.unregister()
            refreshStatus()
        } catch {
            lastError = error.localizedDescription
            refreshStatus()
        }
    }

    /// Refreshes isEnabled from the system (SMAppService.mainApp.status).
    /// Call on app startup and when the settings window appears so the toggle reflects reality.
    func refreshStatus() {
        let status = SMAppService.mainApp.status
        isEnabled = (status == .enabled)
    }
}
