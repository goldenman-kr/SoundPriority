//
//  StatusBarController.swift
//  SoundPriority
//
//  Owns the NSStatusItem and presents an NSPopover with custom SwiftUI content.
//

import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(popover: NSPopover) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = popover

        super.init()

        if let button = statusItem.button {
            // Use custom template asset for the menu bar icon so it adapts to light/dark mode.
            if let image = NSImage(named: NSImage.Name("SoundPriority_bar")) {
                image.isTemplate = true
                button.image = image
            }
            // Ensure the status item treats the image as a template-only glyph.
            button.imagePosition = .imageOnly
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.becomeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}

