//
//  AudioDeviceManager.swift
//  SoundPriority
//
//  Manages Core Audio: enumerates output devices, gets/sets default output device.
//

import Foundation
import AudioToolbox

/// Represents a single audio output device (transient id, stable uid, display name).
/// Use uid for persistence and matching across reconnects; use id for Core Audio API calls.
struct AudioDevice: Identifiable, Hashable, Codable {
    var id: UInt32
    /// Stable device identifier (e.g. Bluetooth address); persists across disconnect/reconnect.
    var uid: String
    var name: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool { lhs.id == rhs.id }
}

/// Wraps Core Audio HAL to list output devices and get/set the system default output device.
final class AudioDeviceManager {

    // MARK: - Public API

    /// Returns all currently available output devices (id, stable uid, name).
    func getOutputDevices() -> [AudioDevice] {
        let ids = getAllDeviceIDs()
        var result: [AudioDevice] = []
        for deviceID in ids {
            guard isOutputDevice(deviceID: deviceID) else { continue }
            let uid = getDeviceUID(deviceID: deviceID)
            let name = getDeviceName(deviceID: deviceID)
            result.append(AudioDevice(id: deviceID, uid: uid, name: name))
        }
        return result
    }

    /// Returns the current system default output device ID.
    func getDefaultOutputDeviceID() -> AudioDeviceID {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var deviceID: AudioDeviceID = kAudioDeviceUnknown

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        )

        let err = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        if err != noErr {
            return kAudioDeviceUnknown
        }
        return deviceID
    }

    /// Sets the system default output device to the given device ID.
    /// - Returns: true if the change was applied successfully.
    @discardableResult
    func setDefaultOutputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        )
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var id = deviceID
        let err = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            size,
            &id
        )
        return err == noErr
    }

    // MARK: - Private Helpers

    private func getAllDeviceIDs() -> [AudioDeviceID] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        )
        var size: UInt32 = 0
        let err = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &size
        )
        if err != noErr || size == 0 {
            return []
        }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: count)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &size,
            &devices
        )
        return devices
    }

    private func isOutputDevice(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyStreams),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        )
        var size: UInt32 = 0
        AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &size)
        return size > 0
    }

    private func getDeviceName(deviceID: AudioDeviceID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        )
        var size = UInt32(MemoryLayout<CFString>.size)
        var name: CFString = "" as CFString
        let err = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &name)
        if err != noErr {
            return "Device \(deviceID)"
        }
        return name as String
    }

    /// Stable device UID (persists across disconnects; use for priority list).
    private func getDeviceUID(deviceID: AudioDeviceID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceUID),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        )
        var size = UInt32(MemoryLayout<CFString>.size)
        var uid: CFString = "" as CFString
        let err = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &uid)
        if err != noErr {
            return "device-\(deviceID)"
        }
        return uid as String
    }
}
