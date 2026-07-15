import Cocoa
import CoreGraphics

enum AppConfig {
    /// How often the hydration reminder fires.
    /// Set to 3600 (60 minutes) for real use. Left at 10s for easy testing.
    static let hydrationInterval: TimeInterval = 5

    /// Initial window size, used only before the drink GIF has loaded once.
    static let windowSize = CGSize(width: 220, height: 220)

    /// The window is resized to the drink GIF's real aspect ratio, capped so
    /// its longer side never exceeds this many points.
    static let maxPetDimension: CGFloat = 420

    /// Margin from the bottom-right corner of the visible screen area.
    static let screenMargin: CGFloat = 24
}

/// Window levels used for the "always on top" toggle.
enum PetWindowLevel {
    /// Sits just above the desktop wallpaper/icons, but behind normal app windows.
    static let desktop = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) + 1)

    /// Floats above all other application windows.
    static let alwaysOnTop = NSWindow.Level.floating
}
