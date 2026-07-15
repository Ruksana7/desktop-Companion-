import Cocoa

/// Owns the transparent, click-through pet window and drives its animation state machine.
final class PetWindowController: NSWindowController {

    private let imageView = NSImageView()
    private let animator: GIFAnimator
    private(set) var state: PetState = .idle
    private var hasPositionedOnce = false

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
        goBlank()
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
        // Without this, Core Animation may assume the layer is fully opaque
        // and skip clearing its backing store between frames, which can show
        // up as a checkerboard/garbage pattern in transparent regions instead
        // of true transparency.
        imageView.layer?.isOpaque = false
        window.contentView = imageView
    }

    private func positionWindow() {
        resizeAndReposition(to: AppConfig.windowSize)
    }

    /// Resizes the window to `size`, keeping its bottom-right corner anchored
    /// in place so the pet doesn't visually jump when its aspect ratio changes
    /// between GIFs of different dimensions. On the very first call, anchors
    /// to the bottom-right of the screen (with margin) instead of the window's
    /// own prior frame, since it has none yet.
    private func resizeAndReposition(to size: CGSize) {
        guard let window = window, let screen = NSScreen.main else { return }

        let anchorMaxX: CGFloat
        let anchorMinY: CGFloat
        if hasPositionedOnce {
            anchorMaxX = window.frame.maxX
            anchorMinY = window.frame.minY
        } else {
            let screenFrame = screen.visibleFrame
            anchorMaxX = screenFrame.maxX - AppConfig.screenMargin
            anchorMinY = screenFrame.minY + AppConfig.screenMargin
            hasPositionedOnce = true
        }

        let newFrame = NSRect(
            x: anchorMaxX - size.width,
            y: anchorMinY,
            width: size.width,
            height: size.height
        )
        window.setFrame(newFrame, display: true)
        imageView.frame = NSRect(origin: .zero, size: size)
    }

    /// Scales `nativeSize` down so its longer side fits `AppConfig.maxPetDimension`,
    /// preserving the GIF's real aspect ratio.
    private func fittedSize(for nativeSize: CGSize) -> CGSize {
        guard nativeSize.width > 0, nativeSize.height > 0 else { return AppConfig.windowSize }
        let scale = AppConfig.maxPetDimension / max(nativeSize.width, nativeSize.height)
        return CGSize(width: nativeSize.width * scale, height: nativeSize.height * scale)
    }

    // MARK: - State machine

    /// Hides the pet entirely — there is no idle animation, only blank space
    /// between drink triggers.
    func goBlank() {
        state = .idle
        animator.stop()
        imageView.image = nil
    }

    func triggerDrinkAnimation() {
        guard state != .drinking else { return }
        guard animator.load(gifNamed: "drink") else { return }

        if let nativeSize = animator.nativeSize {
            resizeAndReposition(to: fittedSize(for: nativeSize))
        }

        state = .drinking
        animator.play(loop: false) { [weak self] in
            self?.goBlank()
        }
    }

    // MARK: - Menu bar actions

    func setAlwaysOnTop(_ isOn: Bool) {
        window?.level = isOn ? PetWindowLevel.alwaysOnTop : PetWindowLevel.desktop
    }
}
