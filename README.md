# HydrationPet

A tiny macOS menu-bar utility: a transparent, click-through desktop pet that
sits on your desktop and plays a "walk in and drink water" animation on a
timer, reminding you to hydrate.

Built as a native Swift Package Manager executable using AppKit (no
SwiftUI/storyboard needed) — no Xcode project file required, though you can
still open and run it from Xcode.

## Project structure

```
.
├── Package.swift
├── Scripts/
│   └── make_app_bundle.sh        # optional: packages a double-clickable .app
└── Sources/HydrationPet/
    ├── main.swift                 # entry point, sets accessory activation policy
    ├── AppDelegate.swift          # wires window + timer + status bar together
    ├── AppConfig.swift            # tunables: timer interval, window size/level
    ├── PetState.swift             # idle / drinking state enum
    ├── PetWindow.swift            # NSWindow subclass that never takes focus
    ├── PetWindowController.swift  # transparent click-through window + state machine
    ├── GIFAnimator.swift          # manual GIF decoder/player (ImageIO-based)
    ├── HydrationTimer.swift       # repeating reminder timer
    ├── StatusBarController.swift  # NSStatusItem menu (the only UI)
    └── Resources/Assets/          # <-- put your idle.gif and drink.gif here
```

## 1. Place your assets

Drop your two transparent GIFs into:

```
Sources/HydrationPet/Resources/Assets/idle.gif
Sources/HydrationPet/Resources/Assets/drink.gif
```

- `idle.gif` — character sitting/idling; loops forever.
- `drink.gif` — character walking into frame and drinking; plays once, then
  the app automatically switches back to `idle.gif`.

Both must have real alpha transparency (not a matte background color) — the
window itself has no background, so whatever isn't transparent in the GIF is
what you'll see floating on the desktop.

`Package.swift` already declares this folder as a resource:

```swift
resources: [
    .copy("Resources/Assets")
]
```

so any file you place there is copied into the app's resource bundle on
every build, and loaded at runtime via `Bundle.module` in `GIFAnimator.swift`.

## 2. Build & run

Requires Xcode (or at least the Xcode Command Line Tools) with Swift 5.9+ on
macOS 12+.

```bash
swift run
```

This compiles and launches the app directly from the terminal. You won't see
it in the Dock or Cmd-Tab switcher — `main.swift` calls
`NSApp.setActivationPolicy(.accessory)`, so the only sign it's running is the
droplet icon in your menu bar (top-right).

To stop it while running from the terminal, use the menu bar's **Quit
Hydration Pet**, or Ctrl-C in the terminal.

### Opening in Xcode instead

Xcode can open `Package.swift` directly:

```bash
open Package.swift
```

Then pick the `HydrationPet` scheme and Run (⌘R).

### Packaging as a real .app (optional)

For a normal double-clickable app you can add to Login Items:

```bash
chmod +x Scripts/make_app_bundle.sh   # already executable in this repo
./Scripts/make_app_bundle.sh
```

This produces `HydrationPet.app` in the project root — drag it to
`/Applications`.

## 3. How each requirement is implemented

**Perfect transparency** (`PetWindowController.configureWindow`):
```swift
window.isOpaque = false
window.backgroundColor = .clear
window.hasShadow = false
window.styleMask = [.borderless]   // no title bar, no frame
```

**Click-through** (same method):
```swift
window.ignoresMouseEvents = true
```
Since the only interaction surface is the menu bar item, the entire window
(not just its transparent pixels) passes every click straight through to
whatever is behind it — no custom hit-testing needed.

**Always on top / desktop-anchored toggle** (`AppConfig.swift` +
`PetWindowController.setAlwaysOnTop`):
```swift
enum PetWindowLevel {
    // just above the desktop wallpaper/icons, behind normal app windows
    static let desktop = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    // floats above every other app window
    static let alwaysOnTop = NSWindow.Level.floating
}
```
Default is `.desktop`. Toggling **Always on Top** in the menu switches
`window.level` between the two at runtime.

**Animation state machine** (`PetWindowController` + `GIFAnimator`):
- `startIdle()` loads `idle.gif` and plays it looping.
- `triggerDrinkAnimation()` loads `drink.gif`, plays it once, and — via a
  completion closure fired after the final frame — calls `startIdle()`
  again automatically.
- `GIFAnimator` decodes every frame of the GIF up front with `ImageIO`
  (`CGImageSourceCreateImageAtIndex` + per-frame `kCGImagePropertyGIFDictionary`
  delay times) and drives an `NSImageView` frame-by-frame with a `Timer`,
  which is what makes the one-shot "play then callback" behavior possible
  (plain `NSImageView.animates` GIF playback has no completion callback).

**Hydration timer** (`HydrationTimer.swift` + `AppConfig.hydrationInterval`):
Currently set to `10` seconds for easy testing. Change to `3600` for the
real 60-minute cadence:
```swift
static let hydrationInterval: TimeInterval = 3600
```

**Menu bar controls** (`StatusBarController.swift`):
- **Trigger Drink Now** — plays the drink animation immediately and resets
  the timer (for testing).
- **Reset Timer** — restarts the countdown without triggering the animation.
- **Always on Top** — checkbox toggling the window level (see above).
- **Quit Hydration Pet** — `NSApp.terminate(nil)`.

## 4. Tuning

All the knobs live in `AppConfig.swift`:

```swift
static let hydrationInterval: TimeInterval = 10   // seconds between reminders
static let windowSize = CGSize(width: 220, height: 220)
static let screenMargin: CGFloat = 24             // distance from screen edge
```

The pet is positioned in `PetWindowController.positionWindow()`, anchored to
the bottom-right of the main screen's visible area — edit that method if you
want a different corner or a fixed custom position.

## 5. Testing checklist

- [ ] Launch with `swift run` — droplet icon appears in the menu bar, no
      Dock icon, no visible window frame.
- [ ] Character appears bottom-right, idling on loop.
- [ ] Click desktop icons / other app windows underneath the pet — clicks
      pass straight through.
- [ ] Wait ~10s (default test interval) — pet plays the drink animation once,
      then returns to idle automatically.
- [ ] Menu → **Trigger Drink Now** — plays immediately regardless of timer
      state.
- [ ] Menu → **Reset Timer** — countdown restarts without playing anything.
- [ ] Menu → **Always on Top** — toggle on, bring another app window to
      front; pet stays above it. Toggle off; pet drops behind other app
      windows again (still above the wallpaper).
- [ ] Menu → **Quit Hydration Pet** — app exits cleanly.
