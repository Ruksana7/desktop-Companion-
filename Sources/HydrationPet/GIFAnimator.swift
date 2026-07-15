import Cocoa
import ImageIO

/// Decodes an animated GIF frame-by-frame and drives an NSImageView manually.
///
/// This is used instead of NSImageView's built-in `animates` GIF support because
/// the drinking clip needs to play exactly once and report back when it's done,
/// so the pet can return to idle.
final class GIFAnimator {

    private struct Frame {
        let image: NSImage
        let duration: TimeInterval
    }

    private var frames: [Frame] = []
    private weak var imageView: NSImageView?
    private var timer: Timer?
    private var currentFrameIndex = 0
    private var loops = true
    private var completion: (() -> Void)?

    /// The GIF's native pixel size, taken from its first frame. Used to size
    /// the window to the clip's real aspect ratio instead of stretching it
    /// into a fixed box.
    var nativeSize: CGSize? {
        frames.first?.image.size
    }

    init(imageView: NSImageView) {
        self.imageView = imageView
    }

    /// Loads `<name>.gif` from the app bundle's Resources/Assets folder.
    /// Returns false (and logs a warning) if the file isn't found or isn't a valid GIF.
    @discardableResult
    func load(gifNamed name: String) -> Bool {
        guard let url = Self.resourceURL(forGIFNamed: name) else {
            print("⚠️ GIFAnimator: could not find \(name).gif — place it in Sources/HydrationPet/Resources/Assets/")
            return false
        }
        return load(url: url)
    }

    @discardableResult
    func load(url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return false }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return false }

        var loadedFrames: [Frame] = []
        loadedFrames.reserveCapacity(count)

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let normalized = Self.normalizedAlphaImage(from: cgImage)
            let duration = Self.frameDuration(source: source, index: i)
            let size = NSSize(width: normalized.width, height: normalized.height)
            loadedFrames.append(Frame(image: NSImage(cgImage: normalized, size: size), duration: duration))
        }

        guard !loadedFrames.isEmpty else { return false }
        frames = loadedFrames
        return true
    }

    /// Starts playback of the currently loaded GIF.
    /// - Parameters:
    ///   - loop: pass `true` for idle (loops forever), `false` for a one-shot clip.
    ///   - completion: called once, after the final frame of a non-looping clip.
    func play(loop: Bool, completion: (() -> Void)? = nil) {
        stop()
        guard !frames.isEmpty else { return }
        self.loops = loop
        self.completion = completion
        currentFrameIndex = 0
        showCurrentFrame()
        scheduleNextFrame()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func showCurrentFrame() {
        imageView?.image = frames[currentFrameIndex].image
    }

    private func scheduleNextFrame() {
        let duration = frames[currentFrameIndex].duration
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.advanceFrame()
        }
    }

    private func advanceFrame() {
        let isLastFrame = currentFrameIndex == frames.count - 1

        if isLastFrame {
            if loops {
                currentFrameIndex = 0
                showCurrentFrame()
                scheduleNextFrame()
            } else {
                stop()
                completion?()
            }
        } else {
            currentFrameIndex += 1
            showCurrentFrame()
            scheduleNextFrame()
        }
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        let fallback = 0.1
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return fallback
        }

        let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gifProperties[kCGImagePropertyGIFDelayTime] as? Double
        let duration = unclamped ?? clamped ?? fallback

        // Guard against near-zero delays some GIF encoders emit.
        return duration < 0.02 ? fallback : duration
    }

    /// GIF frames decoded via ImageIO often come back with non-premultiplied
    /// alpha. Compositing that directly on a layer-backed view can corrupt
    /// transparent regions (rendering as a checkerboard-like pattern instead
    /// of clean transparency) because Core Animation's fast path expects
    /// premultiplied alpha. Redrawing into a fresh premultiplied bitmap
    /// context normalizes every frame before it ever reaches the layer.
    private static func normalizedAlphaImage(from cgImage: CGImage) -> CGImage {
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return cgImage
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage() ?? cgImage
    }

    private static func resourceURL(forGIFNamed name: String) -> URL? {
        // SwiftPM's directory .copy() resource keeps only the last path
        // component ("Assets"), not the full "Resources/Assets" source path.
        Bundle.module.url(forResource: name, withExtension: "gif", subdirectory: "Assets")
            ?? Bundle.module.url(forResource: name, withExtension: "gif", subdirectory: "Resources/Assets")
            ?? Bundle.module.url(forResource: name, withExtension: "gif")
    }
}
