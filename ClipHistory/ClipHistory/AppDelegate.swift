import AppKit
import SwiftUI
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let persistence = PersistenceController.shared
    private let monitor = ClipboardMonitor.shared
    private let retention = RetentionManager.shared
    private var previousApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = persistence.viewContext
        retention.start()
        setupMenuBarItem()
        monitor.start()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePasteRequest),
            name: .clipHistoryRequestPaste,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipHistory")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 380, height: 520)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(rootView: PopoverRootView())
        popover = pop
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }

        if popover?.isShown == true {
            popover?.performClose(sender)
        } else {
            previousApp = NSWorkspace.shared.frontmostApplication
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func handlePasteRequest() {
        popover?.performClose(nil)
        previousApp?.activate(options: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.performPaste()
        }
    }

    private func performPaste() {
        guard AXIsProcessTrusted() else {
            let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 9
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
