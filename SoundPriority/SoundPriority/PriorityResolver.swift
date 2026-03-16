//
//  PriorityResolver.swift
//  SoundPriority
//
//  Chooses the best output device from current devices using the user's priority order (by UID).
//

import Foundation

/// Resolves the highest-priority currently available output device from a priority list (by stable UID).
enum PriorityResolver {

    /// Returns the first device in priorityOrder (UIDs) that is present in availableDevices. Reconnects match by UID.
    static func resolve(
        availableDevices: [AudioDevice],
        priorityOrder: [String]
    ) -> AudioDevice? {
        let byUID = Dictionary(uniqueKeysWithValues: availableDevices.map { ($0.uid, $0) })
        for uid in priorityOrder {
            if let device = byUID[uid] { return device }
        }
        return nil
    }
}
