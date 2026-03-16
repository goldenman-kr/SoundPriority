//
//  SettingsView.swift
//  SoundPriority
//
//  Settings window: list of devices (including disconnected) by priority, auto-switch and launch-at-login toggles.
//

import SwiftUI

/// One row in the priority list: either a connected device or a remembered (disconnected) device.
struct PriorityRowItem: Identifiable {
    let uid: String
    var displayName: String
    var isConnected: Bool
    var device: AudioDevice?
    var id: String { uid }
}

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Auto-switch to highest priority device", isOn: $appState.autoSwitchEnabled)
                .toggleStyle(.switch)

            Toggle("Launch at login", isOn: launchAtLoginBinding)
                .toggleStyle(.switch)
            if let error = appState.launchAtLoginManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            if let defaultDevice = appState.outputDevices.first(where: { $0.id == appState.defaultOutputDeviceID }) {
                HStack {
                    Text("Current output:")
                    Text(defaultDevice.name)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
            }

            Divider()

            Text("Priority order (top = highest)")
                .font(.headline)
            Text("Drag to reorder. Known devices keep their position when disconnected.")
                .font(.caption)
                .foregroundStyle(.secondary)

            List {
                ForEach(priorityOrderedRows) { row in
                    HStack {
                        Text(row.displayName)
                            .fontWeight(row.device?.id == appState.defaultOutputDeviceID ? .semibold : .regular)

                        if !row.isConnected {
                            Text("(Not Connected)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if row.device?.id == appState.defaultOutputDeviceID {
                            Text("Current")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Manual "Play on this device" button.
                        if let device = row.device {
                            Button {
                                appState.manuallySelectOutputDevice(device)
                            } label: {
                                Image(systemName: "play.fill")
                            }
                            .buttonStyle(.borderless)
                            .help("Play on this device")
                            .disabled(!row.isConnected)
                            .opacity(row.isConnected ? 1.0 : 0.3)
                        } else {
                            Image(systemName: "play.fill")
                                .foregroundStyle(.secondary)
                                .opacity(0.2)
                        }
                    }
                }
                .onMove(perform: movePriority)
            }
            .listStyle(.inset)
            
            Spacer(minLength: 8)
            
            // App version at the bottom of the settings window.
            Text(versionString)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 360, minHeight: 320)
    }

    /// Version string from Info.plist, e.g. "Version 1.0 (Build 3)".
    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(version) (Build \(build))"
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.launchAtLoginManager.isEnabled },
            set: { newValue in
                if newValue {
                    appState.launchAtLoginManager.enable()
                } else {
                    appState.launchAtLoginManager.disable()
                }
            }
        )
    }

    /// Rows in priority order: connected devices show live name; disconnected show last-seen name + "(Not Connected)".
    private var priorityOrderedRows: [PriorityRowItem] {
        appState.priorityOrder.map { uid in
            if let device = appState.outputDevices.first(where: { $0.uid == uid }) {
                return PriorityRowItem(uid: uid, displayName: device.name, isConnected: true, device: device)
            } else {
                let name = appState.lastSeenDeviceNames[uid] ?? uid
                return PriorityRowItem(uid: uid, displayName: name, isConnected: false, device: nil)
            }
        }
    }

    private func movePriority(from source: IndexSet, to destination: Int) {
        var uids = priorityOrderedRows.map(\.uid)
        uids.move(fromOffsets: source, toOffset: destination)
        appState.setPriorityOrder(uids)
    }
}

#Preview {
    let state = AppState()
    return SettingsView(appState: state)
        .frame(width: 400, height: 400)
}
