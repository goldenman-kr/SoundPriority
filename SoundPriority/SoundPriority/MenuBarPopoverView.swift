//
//  MenuBarPopoverView.swift
//  SoundPriority
//
//  Custom dark, rounded panel-style menu bar popover content.
//

import SwiftUI

struct MenuBarPopoverView: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 18, x: 0, y: 10)

            VStack(spacing: 0) {
                MenuHeaderSection(appState: appState)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                Divider()
                    .overlay(Color.white.opacity(0.12))
                    .padding(.horizontal, 8)

                MenuSectionView {
                    ActionsSection(appState: appState)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .padding(8)
        .frame(width: 280)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header / Status

struct MenuHeaderSection: View {
    @Bindable var appState: AppState

    private var currentOutputName: String {
        if let device = appState.outputDevices.first(where: { $0.id == appState.defaultOutputDeviceID }) {
            return device.name
        } else {
            return "Unknown output"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("AudioPriority")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Circle()
                    .fill(appState.autoSwitchEnabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Current output")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(currentOutputName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text(appState.autoSwitchEnabled
                     ? "Auto switching is enabled"
                     : "Auto switching is disabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundColor(.white.opacity(0.95))
    }
}

// MARK: - Section Container

struct MenuSectionView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
        }
        .foregroundColor(.white.opacity(0.95))
    }
}

// MARK: - Actions Section

struct ActionsSection: View {
    @Bindable var appState: AppState

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.launchAtLoginManager.isEnabled },
            set: { enabled in
                if enabled {
                    appState.launchAtLoginManager.enable()
                } else {
                    appState.launchAtLoginManager.disable()
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MenuActionRow(
                iconName: "gearshape",
                title: "Open Settings",
                subtitle: "Configure device priority",
                isDestructive: false
            ) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows.first { $0.identifier?.rawValue.contains("settings") == true }?
                    .makeKeyAndOrderFront(nil)
            }

            LaunchAtLoginRow(isOn: launchAtLoginBinding)

            MenuActionRow(
                iconName: "xmark.circle",
                title: "Quit AudioPriority",
                subtitle: nil,
                isDestructive: true
            ) {
                appState.stopPolling()
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Generic Action Row

struct MenuActionRow: View {
    let iconName: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isDestructive ? Color.red : Color.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isDestructive ? Color.red : Color.white.opacity(0.95))

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }

    private var rowBackground: some View {
        let baseOpacity: Double = isPressed ? 0.30 : (isHovering ? 0.20 : 0.08)
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.white.opacity(baseOpacity))
    }
}

// MARK: - Launch at Login Row

struct LaunchAtLoginRow: View {
    @Binding var isOn: Bool
    @State private var isHovering = false

    init(isOn: Binding<Bool>) {
        _isOn = isOn
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 2) {
                Text("Launch at login")
                    .font(.system(size: 13, weight: .medium))
                Text("Start automatically at login")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(isHovering ? 0.20 : 0.08))
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onHover { isHovering = $0 }
    }
}

// MARK: - Press Events Helper

private struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

