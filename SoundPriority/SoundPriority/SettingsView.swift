//
//  SettingsView.swift
//  SoundPriority
//
//  Settings window: list of devices, priority order, auto-switch toggle.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Auto-switch toggle
            Toggle("Auto-switch to highest priority device", isOn: $appState.autoSwitchEnabled)
                .toggleStyle(.switch)

            // Launch at login (ServiceManagement SMAppService.mainApp)
            Toggle("Launch at login", isOn: launchAtLoginBinding)
                .toggleStyle(.switch)
            if let error = appState.launchAtLoginManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            // Current default
            if let defaultDevice = appState.outputDevices.first(where: { $0.id == appState.defaultOutputDeviceID }) {
                HStack {
                    Text("Current output:")
                    Text(defaultDevice.name)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
            }

            Divider()

            // Priority order section
            Text("Priority order (top = highest)")
                .font(.headline)
            Text("Drag to reorder. First available device becomes the default when auto-switch is on.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // List of devices in priority order (with option to remove from list)
            List {
                ForEach(priorityOrderedDevices) { device in
                    HStack {
                        Text(device.name)
                        Spacer()
                        if device.id == appState.defaultOutputDeviceID {
                            Text("Default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove(perform: movePriority)
            }
            .listStyle(.inset)
        }
        .padding()
        .frame(minWidth: 360, minHeight: 320)
    }

    /// Binding for "Launch at login" that calls enable/disable and keeps UI in sync with actual status.
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

    /// Devices ordered by user priority; devices not in priority list appear at the end.
    private var priorityOrderedDevices: [AudioDevice] {
        let ordered = appState.priorityOrder.compactMap { id in
            appState.outputDevices.first { $0.id == id }
        }
        let remaining = appState.outputDevices.filter { d in !appState.priorityOrder.contains(d.id) }
        return ordered + remaining
    }

    private func movePriority(from source: IndexSet, to destination: Int) {
        var ids = priorityOrderedDevices.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        appState.priorityOrder = ids
    }
}

#Preview {
    let state = AppState()
    return SettingsView(appState: state)
        .frame(width: 400, height: 400)
}
