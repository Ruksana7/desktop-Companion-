import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// .accessory hides the Dock icon and app switcher entry — the app is only
// reachable through its menu bar item, matching the "no window UI" design.
app.setActivationPolicy(.accessory)
app.run()
