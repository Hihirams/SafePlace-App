import Foundation
import SwiftUI

/// Cluster layout: one hub per category with its notes orbiting around it.
/// Runs in a fixed "world" space so pan/zoom live in the view.
final class MindSimulation {

    struct Body {
        var id: String
        var position: CGPoint
        var velocity: CGVector
        var pinned: Bool
        var hubID: String?      // members: their category
        var isHub: Bool
        var radius: CGFloat
    }

    static let worldSize: CGFloat = 800

    private(set) var bodies: [Body] = []
    private let worldCenter = CGPoint(x: worldSize / 2, y: worldSize / 2)

    init(hubs: [MindHub], nodes: [MindNode]) {
        let hubCount = max(hubs.count, 1)
        let ringRadius: CGFloat = hubs.count <= 1 ? 0 : 0.26 * Self.worldSize

        var hubPositions: [String: CGPoint] = [:]
        for (index, hub) in hubs.enumerated() {
            let angle = CGFloat(index) / CGFloat(hubCount) * 2 * .pi
            let position = CGPoint(
                x: worldCenter.x + cos(angle) * ringRadius,
                y: worldCenter.y + sin(angle) * ringRadius
            )
            hubPositions[hub.id] = position
            bodies.append(Body(id: hub.id, position: position, velocity: .zero, pinned: false, hubID: nil, isHub: true, radius: hub.radius))
        }

        var counts: [String: Int] = [:]
        for node in nodes {
            let hubPosition = hubPositions[node.category] ?? worldCenter
            let index = counts[node.category, default: 0]
            counts[node.category] = index + 1
            let angle = CGFloat(index) * 2.399963  // golden angle for even spread
            let radius = 42 + CGFloat(index % 5) * 15
            let position = CGPoint(
                x: hubPosition.x + cos(angle) * radius,
                y: hubPosition.y + sin(angle) * radius
            )
            bodies.append(Body(id: node.id, position: position, velocity: .zero, pinned: false, hubID: node.category, isHub: false, radius: node.radius))
        }
    }

    /// Runs `iterations` physics steps. `energy` (0...~1.8) scales motion.
    func step(iterations: Int, energy: CGFloat) {
        let count = bodies.count
        guard count > 0 else { return }
        let e = max(energy, 0.15)
        let index = Dictionary(bodies.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })

        for _ in 0..<iterations {
            var forces = [CGVector](repeating: .zero, count: count)

            // Repulsion (hubs repel hard; hubs push members; members nudge each other).
            for i in 0..<count {
                for j in (i + 1)..<count {
                    let dx = bodies[i].position.x - bodies[j].position.x
                    let dy = bodies[i].position.y - bodies[j].position.y
                    let distanceSq = max(dx * dx + dy * dy, 1)
                    let distance = sqrt(distanceSq)
                    let strength: CGFloat
                    if bodies[i].isHub && bodies[j].isHub { strength = 9_000 }
                    else if bodies[i].isHub || bodies[j].isHub { strength = 1_200 }
                    else { strength = 320 }
                    var force = min(strength / distanceSq, 45) * e
                    if distance < 40 { force += (40 - distance) * 0.25 }
                    let fx = dx / distance * force
                    let fy = dy / distance * force
                    forces[i].dx += fx; forces[i].dy += fy
                    forces[j].dx -= fx; forces[j].dy -= fy
                }
            }

            // Member -> hub attraction (keeps clusters together).
            for i in 0..<count where !bodies[i].isHub {
                guard let hubID = bodies[i].hubID, let h = index[hubID] else { continue }
                let dx = bodies[h].position.x - bodies[i].position.x
                let dy = bodies[h].position.y - bodies[i].position.y
                let distance = max(sqrt(dx * dx + dy * dy), 1)
                let rest = bodies[h].radius + 30
                let force = (distance - rest) * 0.02 * e
                forces[i].dx += dx / distance * force
                forces[i].dy += dy / distance * force
            }

            // Gentle pull to center.
            for i in 0..<count {
                forces[i].dx += (worldCenter.x - bodies[i].position.x) * 0.004
                forces[i].dy += (worldCenter.y - bodies[i].position.y) * 0.004
            }

            // Integrate + damp.
            for i in 0..<count where !bodies[i].pinned {
                bodies[i].velocity.dx = (bodies[i].velocity.dx + forces[i].dx) * 0.85
                bodies[i].velocity.dy = (bodies[i].velocity.dy + forces[i].dy) * 0.85
                let speed = hypot(bodies[i].velocity.dx, bodies[i].velocity.dy)
                let maxSpeed: CGFloat = bodies[i].isHub ? 4 : 11
                if speed > maxSpeed {
                    bodies[i].velocity.dx *= maxSpeed / speed
                    bodies[i].velocity.dy *= maxSpeed / speed
                }
                bodies[i].position.x += bodies[i].velocity.dx
                bodies[i].position.y += bodies[i].velocity.dy
                let margin: CGFloat = 40
                bodies[i].position.x = min(max(bodies[i].position.x, margin), Self.worldSize - margin)
                bodies[i].position.y = min(max(bodies[i].position.y, margin), Self.worldSize - margin)
            }
        }
    }

    func position(for id: String) -> CGPoint? {
        bodies.first { $0.id == id }?.position
    }

    func isPinned(_ id: String) -> Bool {
        bodies.first { $0.id == id }?.pinned ?? false
    }

    func togglePin(_ id: String) {
        guard let i = bodies.firstIndex(where: { $0.id == id }) else { return }
        bodies[i].pinned.toggle()
        if bodies[i].pinned { bodies[i].velocity = .zero }
    }
}
