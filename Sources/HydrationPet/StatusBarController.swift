import Cocoa

/// The menu bar (status item) UI — the only way the user interacts with the app.
final class StatusBarController {

    private let statusItem: NSStatusItem
    private var alwaysOnTop = false

    private let onTriggerNow: () -> Void
    private let onResetTimer: () -> Void
    private let onToggleAlwaysOnTop: (Bool) -> Void
    private let onQuit: () -> Void

    init(
        onTriggerNow: @escaping () -> Void,
        onResetTimer: @escaping () -> Void,
        onToggleAlwaysOnTop: @escaping (Bool) -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onTriggerNow = onTriggerNow
        self.onResetTimer = onResetTimer
        self.onToggleAlwaysOnTop = onToggleAlwaysOnTop
        self.onQuit = onQuit

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Hydration Pet")
        }

        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let triggerItem = NSMenuItem(title: "Trigger Drink Now", action: #selector(handleTriggerNow), keyEquivalent: "")
        triggerItem.target = self
        menu.addItem(triggerItem)

        let resetItem = NSMenuItem(title: "Reset Timer", action: #selector(handleResetTimer), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())

        let alwaysOnTopItem = NSMenuItem(title: "Always on Top", action: #selector(handleToggleAlwaysOnTop), keyEquivalent: "")
        alwaysOnTopItem.target = self
        alwaysOnTopItem.state = alwaysOnTop ? .on : .off
        menu.addItem(alwaysOnTopItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Hydration Pet", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func handleTriggerNow() {
        onTriggerNow()
    }

    @objc private func handleResetTimer() {
        onResetTimer()
    }

    @objc private func handleToggleAlwaysOnTop(_ sender: NSMenuItem) {
        alwaysOnTop.toggle()
        sender.state = alwaysOnTop ? .on : .off
        onToggleAlwaysOnTop(alwaysOnTop)
    }

    @objc private func handleQuit() {
        onQuit()
    }
}
