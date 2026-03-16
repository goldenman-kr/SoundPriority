//
//  PriorityResolver.swift
//  SoundPriority
//
//  Chooses the best output device from current devices using the user's priority order.
//

import Foundation

/// Resolves the highest-priority currently available output device from a priority list.
enum PriorityResolver {

    /// Given the list of currently available devices and the user's ordered priority (device IDs, first = highest),
    /// returns the first device in the priority list that is present in availableDevices, or nil if none match.
    /// - Parameters:
    ///   - availableDevices: Current output devices from AudioDeviceManager.
    ///   - priorityOrder: User's preferred device IDs in order (first = highest priority).
    /// - Returns: The AudioDevice to use, or nil if no prioritized device is available.
    static func resolve(
        availableDevices: [AudioDevice],
        priorityOrder: [UInt32]
    ) -> AudioDevice? {
        let availableIDs = Set(availableDevices.map(\.id))
        for deviceID in priorityOrder {
            if availableIDs.contains(deviceID),
               let device = availableDevices.first(where: { $0.id == deviceID }) {
                return device
            }
        }
        return nil
    }
}
