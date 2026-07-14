import Cocoa

/// Owns the transparent, click-through pet window and drives its animation state machine.
final class PetWindowController: NSWindowController {

    private let imageView = NSImageView()
    private let animator: GIFAnimator
    private(set) var state: PetState = .idle

    init() {
        let window = PetWindow(
            contentRect: NSRect(origin: .zero, size: AppConfig.windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        animator = GIFAnimator(imageView: imageView)
        super.init(window: window)

        configureWindow()
        configureImageView()
        positionWindow()
        startIdle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureWindow() {
        guard let window = window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = PetWindowLevel.desktop
        // The only interaction surface is the menu bar item, so make every
        // pixel of the window click-through — no per-pixel hit testing needed.
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false
    }

    private func configureImageView() {
        guard let window = window else { return }
        imageView.frame = NSRect(origin: .zero, size: AppConfig.windowSize)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = imageView
    }

    private func positionWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let origin = NSPoint(
            x: screenFrame.maxX - AppConfig.windowSize.width - AppConfig.screenMargin,
            y: screenFrame.minY + AppConfig.screenMargin
        )
        window.setFrameOrigin(origin)
    }

    // MARK: - State machine

    func startIdle() {
        state = .idle
        guard animator.load(gifNamed: "idle") else { return }
        animator.play(loop: true)
    }

    func triggerDrinkAnimation() {
        guard state != .drinking else { return }
        guard animator.load(gifNamed: "drink") else { return }

        state = .drinking
        animator.play(loop: false) { [weak self] in
            self?.startIdle()
        }
    }

    // MARK: - Menu bar actions

    func setAlwaysOnTop(_ isOn: Bool) {
        window?.level = isOn ? PetWindowLevel.alwaysOnTop : PetWindowLevel.desktop
    }
}
