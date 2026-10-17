import SwiftUI
import Observation

struct PointOfInterest: Identifiable, Hashable {
    enum Kind: Hashable { case chapter(UUID), library, pond, campfire }
    var id: String
    var kind: Kind
    var position: CGPoint      // normalized 0...1
    var title: String
    var subtitle: String
    var symbol: String
    var color: Color
    var number: Int? = nil
}

@Observable
final class WorldModel {
    var position = CGPoint(x: 0.36, y: 0.86)
    var target: CGPoint?
    var joystick: CGVector = .zero
    var keys: Set<String> = []
    var facingLeft = false
    var isMoving = false
    var size: CGSize = .init(width: 1000, height: 700)
    private var last = Date()

    /// Speed in points per second, so motion feels the same on every iPad size.
    let speed: CGFloat = 260

    func tick() {
        let now = Date()
        let dt = min(0.05, now.timeIntervalSince(last))
        last = now
        var v = CGVector.zero
        if keys.contains("up") { v.dy -= 1 }
        if keys.contains("down") { v.dy += 1 }
        if keys.contains("left") { v.dx -= 1 }
        if keys.contains("right") { v.dx += 1 }
        if v == .zero { v = joystick }
        var px = CGPoint(x: position.x * size.width, y: position.y * size.height)

        if v != .zero {
            target = nil
            let len = max(1, sqrt(v.dx * v.dx + v.dy * v.dy))
            px.x += v.dx / len * speed * dt * min(1, sqrt(v.dx * v.dx + v.dy * v.dy))
            px.y += v.dy / len * speed * dt * min(1, sqrt(v.dx * v.dx + v.dy * v.dy))
            if abs(v.dx) > 0.1 { facingLeft = v.dx < 0 }
            isMoving = true
        } else if let t = target {
            let tp = CGPoint(x: t.x * size.width, y: t.y * size.height)
            let dx = tp.x - px.x, dy = tp.y - px.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < 4 { target = nil; isMoving = false }
            else {
                let step = min(dist, speed * dt)
                px.x += dx / dist * step; px.y += dy / dist * step
                if abs(dx) > 1 { facingLeft = dx < 0 }
                isMoving = true
            }
        } else {
            isMoving = false
        }
        let nx = min(0.97, max(0.03, px.x / max(1, size.width)))
        let ny = min(0.95, max(0.08, px.y / max(1, size.height)))
        if abs(nx - position.x) > 0.00001 || abs(ny - position.y) > 0.00001 { position = CGPoint(x: nx, y: ny) }
    }

    func distance(to p: CGPoint) -> CGFloat {
        let dx = (p.x - position.x) * size.width, dy = (p.y - position.y) * size.height
        return sqrt(dx * dx + dy * dy)
    }
}
