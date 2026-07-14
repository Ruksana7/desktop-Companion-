import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var petWindowController: PetWindowController!
    private var hydrationTimer: HydrationTimer!
    private var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        petWindowController = PetWindowController()
        petWindowController.showWindow(nil)

        hydrationTimer = HydrationTimer(interval: AppConfig.hydrationInterval) { [weak self] in
            self?.petWindowController.triggerDrinkAnimation()
        }
        hydrationTimer.start()

        statusBarController = StatusBarController(
            onTriggerNow: { [weak self] in
                self?.petWindowController.triggerDrinkAnimation()
                self?.hydrationTimer.reset()
            },
            onResetTimer: { [weak self] in
                self?.hydrationTimer.reset()
            },
            onToggleAlwaysOnTop: { [weak self] isOn in
                self?.petWindowController.setAlwaysOnTop(isOn)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
