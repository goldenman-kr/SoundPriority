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
    static let deviceDisplayNames = "audioPriority.deviceDisplayNames"
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

    /// User-defined priority order (device UIDs). First = highest priority. Persisted so reconnects keep position.
    var priorityOrder: [String] {
        didSet { savePriorityAndNames() }
    }

    /// Last-known display name per UID (for showing disconnected devices in UI).
    var lastSeenDeviceNames: [String: String] {
        didSet { savePriorityAndNames() }
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
        self.priorityOrder = UserDefaults.standard.array(forKey: StorageKey.priorityOrder) as? [String] ?? []
        self.lastSeenDeviceNames = UserDefaults.standard.dictionary(forKey: StorageKey.deviceDisplayNames) as? [String: String] ?? [:]
        self.autoSwitchEnabled = UserDefaults.standard.object(forKey: StorageKey.autoSwitchEnabled) as? Bool ?? true
        launchAtLoginManager.refreshStatus()
    }

    private func savePriorityAndNames() {
        UserDefaults.standard.set(priorityOrder, forKey: StorageKey.priorityOrder)
        UserDefaults.standard.set(lastSeenDeviceNames, forKey: StorageKey.deviceDisplayNames)
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

    /// Single poll: refresh device list and default ID; merge by UID so reconnects keep position; auto-switch if enabled.
    private func tick() {
        outputDevices = audioManager.getOutputDevices()
        defaultOutputDeviceID = audioManager.getDefaultOutputDeviceID()
        ensurePriorityContains(devices: outputDevices)

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

    /// Manually route output to a specific device and turn auto-switch off.
    /// This does not change the saved priority order.
    func manuallySelectOutputDevice(_ device: AudioDevice) {
        autoSwitchEnabled = false
        _ = audioManager.setDefaultOutputDevice(device.id)
        defaultOutputDeviceID = audioManager.getDefaultOutputDeviceID()
    }

    /// Set priority order to a new UID list (e.g. after drag reorder in UI). Persists.
    func setPriorityOrder(_ uids: [String]) {
        priorityOrder = uids
    }

    /// Add devices to the priority list by UID; only append truly new UIDs. Update last-seen names.
    func ensurePriorityContains(devices: [AudioDevice]) {
        var names = lastSeenDeviceNames
        var order = priorityOrder
        var changed = false
        for device in devices {
            names[device.uid] = device.name
            if !order.contains(device.uid) {
                order.append(device.uid)
                changed = true
            }
        }
        if changed { priorityOrder = order }
        lastSeenDeviceNames = names
    }

    /// Remove a UID from the priority list.
    func removeFromPriority(uid: String) {
        priorityOrder.removeAll { $0 == uid }
    }
}
