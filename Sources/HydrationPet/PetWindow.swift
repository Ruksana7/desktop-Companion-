import Cocoa

/// A borderless window that never takes keyboard focus, so it can never
/// accidentally steal focus from whatever app the user is working in.
final class PetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
