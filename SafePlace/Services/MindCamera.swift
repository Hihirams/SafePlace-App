import SwiftUI
import UIKit

/// Per-frame animation state. Kept as a reference type so the TimelineView can
/// advance it every frame without triggering SwiftUI state churn.
final class MindCamera {
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
    var targetZoom: CGFloat = 1
    var targetPan: CGSize = .zero

    var contagion: Double = 0        // 0...1 wave ramp
    var waveMix: CGFloat = 1        // 0 = category, 1 = wave
    var waveTarget: CGFloat = 1
    var focusProgress: CGFloat = 0  // 0 = hubs only, 1 = members shown
    var focusTarget: CGFloat = 0
    var pulse: CGFloat = 0          // pop on the focused hub

    private var zoomVel: CGFloat = 0
    private var panVel: CGSize = .zero
    private var lastDate: Date?

    func setDirect(zoom: CGFloat, pan: CGSize) {
        self.zoom = zoom
        self.pan = pan
        self.targetZoom = zoom
        self.targetPan = pan
        self.zoomVel = 0
        self.panVel = .zero
    }

    func setTarget(zoom: CGFloat, pan: CGSize) {
        self.targetZoom = zoom
        self.targetPan = pan
    }

    func advance(to date: Date) {
        let dt: CGFloat
        if let last = lastDate {
            dt = min(max(CGFloat(date.timeIntervalSince(last)), 0), 0.05)
        } else {
            dt = 0
        }
        lastDate = date
        guard dt > 0 else { return }

        // Slightly underdamped spring → smooth with a gentle settle.
        spring(&zoom, &zoomVel, targetZoom, dt)
        var px = pan.width, py = pan.height
        var vx = panVel.width, vy = panVel.height
        spring(&px, &vx, targetPan.width, dt)
        spring(&py, &vy, targetPan.height, dt)
        pan = CGSize(width: px, height: py)
        panVel = CGSize(width: vx, height: vy)

        contagion = min(contagion + Double(dt) / 4.0, 1)
        waveMix += (waveTarget - waveMix) * min(1, dt * 6)
        focusProgress += (focusTarget - focusProgress) * min(1, dt * 8)
        pulse = max(pulse - dt * 3, 0)
    }

    /// Reduce Motion: jump straight to the resting values.
    func snap() {
        zoom = targetZoom
        pan = targetPan
        zoomVel = 0
        panVel = .zero
        contagion = 1
        waveMix = waveTarget
        focusProgress = focusTarget
        pulse = 0
    }

    func reset() {
        zoom = 1; pan = .zero
        targetZoom = 1; targetPan = .zero
        zoomVel = 0; panVel = .zero
        contagion = 0
        waveMix = 1; waveTarget = 1
        focusProgress = 0; focusTarget = 0
        pulse = 0
        lastDate = nil
    }

    private func spring(_ value: inout CGFloat, _ velocity: inout CGFloat, _ target: CGFloat, _ dt: CGFloat) {
        let stiffness: CGFloat = 130
        let damping: CGFloat = 20
        let force = (target - value) * stiffness - velocity * damping
        velocity += force * dt
        value += velocity * dt
    }
}
