import Foundation

/// A repeating timer that fires the hydration reminder. `reset()` restarts the
/// countdown from full length, used by both "Reset Timer" and after a manual trigger.
final class HydrationTimer {
    private var timer: Timer?
    private let interval: TimeInterval
    private let onFire: () -> Void

    init(interval: TimeInterval, onFire: @escaping () -> Void) {
        self.interval = interval
        self.onFire = onFire
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.onFire()
        }
    }

    func reset() {
        start()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
