//
//  AppState.swift
//  SoundPriority
//
//  Central state: devices, priority order, auto-switch toggle; persistence and 1s polling.
//

import Foundation
import SwiftUI
import AudioToolbox

/// Keys for UserDefaults persistence.
private enum StorageKey {
    static let priorityOrder = "audioPriority.devicePriorityOrder"
    static let autoSwitchEnabled = "audioPriority.autoSwitchEnabled"
}

/// App-wide state and business logic for AudioPriority: devices, priority list, auto-switch, polling.
@Observable
final class AppState {

    /// Shared instance so AppDelegate can start polling at launch (no window required).
    static let shared = AppState()

    // MARK: - Published state

    /// All current output devices (refreshed every poll).
    var outputDevices: [AudioDevice] = []

    /// Current system default output device ID.
    var defaultOutputDeviceID: AudioDeviceID = kAudioDeviceUnknown

    /// User-defined priority order (device IDs). First = highest priority.
    var priorityOrder: [UInt32] {
        didSet { savePriorityOrder() }
    }

    /// When true, we automatically set default output to the highest-priority available device every poll.
    var autoSwitchEnabled: Bool {
        didSet { UserDefaults.standard.set(autoSwitchEnabled, forKey: StorageKey.autoSwitchEnabled) }
    }

    // MARK: - Dependencies

    private let audioManager = AudioDeviceManager()
    private var pollTimer: Timer?

    /// Launch-at-login state; refresh on startup so UI shows actual status.
    let launchAtLoginManager = LaunchAtLoginManager()

    // MARK: - Init & persistence

    init() {
        let stored = UserDefaults.standard.array(forKey: StorageKey.priorityOrder) as? [Int]
        self.priorityOrder = stored?.map { UInt32(truncatingIfNeeded: $0) } ?? []
        self.autoSwitchEnabled = UserDefaults.standard.object(forKey: StorageKey.autoSwitchEnabled) as? Bool ?? true
        // Reflect actual launch-at-login status from the system (e.g. after user changed it in System Settings).
        launchAtLoginManager.refreshStatus()
    }

    private func savePriorityOrder() {
        let intList = priorityOrder.map { Int(truncatingIfNeeded: $0) }
        UserDefaults.standard.set(intList, forKey: StorageKey.priorityOrder)
    }

    // MARK: - Polling

    /// Start polling every 1 second: refresh devices and optionally apply priority-based default.
    func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        pollTimer?.tolerance = 0.2
        RunLoop.main.add(pollTimer!, forMode: .common)
        tick()
    }

    /// Stop the 1s timer.
    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// Single poll: refresh device list and default ID; if auto-switch is on, set default to best device.
    private func tick() {
        outputDevices = audioManager.getOutputDevices()
        defaultOutputDeviceID = audioManager.getDefaultOutputDeviceID()
        ensurePriorityContains(deviceIDs: outputDevices.map(\.id))

        guard autoSwitchEnabled else { return }

        if let best = PriorityResolver.resolve(availableDevices: outputDevices, priorityOrder: priorityOrder) {
            if best.id != defaultOutputDeviceID {
                _ = audioManager.setDefaultOutputDevice(best.id)
                defaultOutputDeviceID = best.id
            }
        }
    }

    // MARK: - User actions

    /// Set the system default output device to the given ID (e.g. from settings).
    func setDefaultOutputDevice(_ deviceID: AudioDeviceID) {
        _ = audioManager.setDefaultOutputDevice(deviceID)
        defaultOutputDeviceID = audioManager.getDefaultOutputDeviceID()
    }

    /// Move a device ID to a new index in the priority order (for reordering in UI).
    func movePriority(from source: IndexSet, to destination: Int) {
        var order = priorityOrder
        order.move(fromOffsets: source, toOffset: destination)
        priorityOrder = order
    }

    /// Add device IDs to the priority list if not already present (e.g. when new devices appear).
    /// New devices are appended at the end.
    func ensurePriorityContains(deviceIDs: [UInt32]) {
        var order = priorityOrder
        var changed = false
        for id in deviceIDs {
            if !order.contains(id) {
                order.append(id)
                changed = true
            }
        }
        if changed { priorityOrder = order }
    }

    /// Remove a device ID from the priority list.
    func removeFromPriority(_ deviceID: UInt32) {
        priorityOrder.removeAll { $0 == deviceID }
    }
}
