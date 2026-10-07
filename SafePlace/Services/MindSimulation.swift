import Foundation
import SwiftUI

/// Force-directed layout simulation that keeps the graph gently alive.
/// Runs in a fixed "world" space (0...worldSize) so pan/zoom live in the view.
final class MindSimulation {

    struct Body {
        var id: String
        var position: CGPoint
        var velocity: CGVector
        var pinned: Bool
    }

    static let worldSize: CGFloat = 800

    private(set) var bodies: [Body] = []
    private var edges: [MindEdge]
    private let worldCenter: CGPoint

    // Tuning
    private let repulsion: CGFloat = 5_600
    private let attraction: CGFloat = 0.05
    private let centering: CGFloat = 0.02
    private let damping: CGFloat = 0.86
    private let collisionDistance: CGFloat = 52
    private let maxSpeed: CGFloat = 18

    init(nodes: [MindNode], edges: [MindEdge]) {
        self.edges = edges
        self.worldCenter = CGPoint(x: Self.worldSize / 2, y: Self.worldSize / 2)

        let count = max(nodes.count, 1)
        bodies = nodes.enumerated().map { index, node in
            // Start in a soft spiral so the graph unfolds organically.
            let t = Double(index) / Double(count)
            let angle = t * .pi * (3 + sqrt(5))
            let radius = 0.32 * Self.worldSize * sqrt(t)
            let position = CGPoint(
                x: worldCenter.x + cos(angle) * radius,
                y: worldCenter.y + sin(angle) * radius
            )
            return Body(id: node.id, position: position, velocity: .zero, pinned: false)
        }
    }

    /// Runs `iterations` physics steps. `energy` (0...~1.8) scales motion.
    func step(iterations: Int, energy: CGFloat) {
        let count = bodies.count
        guard count > 0 else { return }
        let e = max(energy, 0.05)
        let index = Dictionary(uniqueKeysWithValues: bodies.enumerated().map { ($1.id, $0) })

        for _ in 0..<iterations {
            var forces = [CGVector](repeating: .zero, count: count)

            // Repulsion between every pair.
            for i in 0..<count {
                for j in (i + 1)..<count {
                    let dx = bodies[i].position.x - bodies[j].position.x
                    let dy = bodies[i].position.y - bodies[j].position.y
                    let distanceSq = max(dx * dx + dy * dy, 1)
                    let distance = sqrt(distanceSq)
                    var force = min(repulsion / distanceSq * e, 60)
                    // Extra push so nodes never pile on top of each other.
                    if distance < collisionDistance {
                        force += (collisionDistance - distance) * 0.6
                    }
                    let fx = dx / distance * force
                    let fy = dy / distance * force
                    forces[i].dx += fx
                    forces[i].dy += fy
                    forces[j].dx -= fx
                    forces[j].dy -= fy
                }
            }

            // Attraction along edges.
            for edge in edges {
                guard let a = index[edge.from], let b = index[edge.to] else { continue }
                let dx = bodies[b].position.x - bodies[a].position.x
                let dy = bodies[b].position.y - bodies[a].position.y
                let distance = max(sqrt(dx * dx + dy * dy), 1)
                let force = attraction * distance * edge.weight * e
                let fx = dx / distance * force
                let fy = dy / distance * force
                forces[a].dx += fx
                forces[a].dy += fy
                forces[b].dx -= fx
                forces[b].dy -= fy
            }

            // Gentle pull toward the middle so the graph stays framed.
            for i in 0..<count {
                forces[i].dx += (worldCenter.x - bodies[i].position.x) * centering
                forces[i].dy += (worldCenter.y - bodies[i].position.y) * centering
            }

            // Integrate + damp.
            for i in 0..<count where !bodies[i].pinned {
                bodies[i].velocity.dx = (bodies[i].velocity.dx + forces[i].dx) * damping
                bodies[i].velocity.dy = (bodies[i].velocity.dy + forces[i].dy) * damping

                // Cap speed so the graph never explodes.
                let speed = hypot(bodies[i].velocity.dx, bodies[i].velocity.dy)
                if speed > maxSpeed {
                    bodies[i].velocity.dx *= maxSpeed / speed
                    bodies[i].velocity.dy *= maxSpeed / speed
                }

                bodies[i].position.x += bodies[i].velocity.dx
                bodies[i].position.y += bodies[i].velocity.dy

                // Soft boundary — keep every node inside the world.
                let margin: CGFloat = 24
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
        if bodies[i].pinned {
            bodies[i].velocity = .zero
        }
    }

    /// Swap in new edges without resetting node positions (e.g. sensitivity change).
    func update(edges newEdges: [MindEdge]) {
        edges = newEdges
    }
}